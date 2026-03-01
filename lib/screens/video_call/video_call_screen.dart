import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Écran d'appel vidéo médecin-patient (Agora).
/// [channelName] : nom du canal (ex: medaichain-{doctorId}-{patientId})
/// [remoteUserName] : nom de l'autre participant pour l'affichage
class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String remoteUserName;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    this.remoteUserName = 'Participant',
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _remoteUid;
  bool _isLoading = true;
  String? _error;
  bool _localVideoEnabled = true;
  bool _localAudioEnabled = true;

  @override
  void initState() {
    super.initState();
    _initAndJoin();
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  Future<void> _initAndJoin() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _requestPermissions();
      final data = await ApiService.getVideoCallToken(widget.channelName);
      final appId = data['appId'] as String? ?? '';
      final token = data['token'] as String? ?? '';
      final uid = (data['uid'] as num?)?.toInt() ?? 0;
      if (appId.isEmpty || token.isEmpty) {
        throw Exception('Token vidéo invalide');
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: appId));
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.startPreview();

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) return;
            setState(() { _isJoined = true; _isLoading = false; });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (!mounted) return;
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (!mounted) return;
            setState(() => _remoteUid = null);
          },
          onError: (ErrorCodeType err, String msg) {
            if (!mounted) return;
            setState(() { _error = msg; _isLoading = false; });
          },
        ),
      );

      await _engine!.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  void _toggleCamera() {
    _engine?.enableLocalVideo(_localVideoEnabled = !_localVideoEnabled);
    setState(() {});
  }

  void _toggleMute() {
    setState(() => _localAudioEnabled = !_localAudioEnabled);
    _engine?.muteLocalAudioStream(!_localAudioEnabled);
  }

  Future<void> _leaveCall() async {
    await _engine?.leaveChannel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Connexion à l\'appel...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Retour'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // Vidéo distante (plein écran)
                      if (_remoteUid != null)
                        Center(
                          child: AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: _engine!,
                              canvas: VideoCanvas(uid: _remoteUid),
                              connection: RtcConnection(channelId: widget.channelName),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person, size: 80, color: Colors.white54),
                              const SizedBox(height: 16),
                              Text(
                                'En attente de ${widget.remoteUserName}...',
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      // Vidéo locale (coin)
                      Positioned(
                        top: 16,
                        right: 16,
                        width: 120,
                        height: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _localVideoEnabled
                              ? AgoraVideoView(
                                  controller: VideoViewController(
                                    rtcEngine: _engine!,
                                    canvas: const VideoCanvas(uid: 0),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: Icon(Icons.videocam_off, color: Colors.white54),
                                  ),
                                ),
                        ),
                      ),
                      // Barre d'outils en bas
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCallButton(Icons.mic_off, _localAudioEnabled ? Colors.white : Colors.red, _toggleMute),
                            _buildCallButton(Icons.call_end, Colors.red, _leaveCall),
                            _buildCallButton(Icons.videocam_off, _localVideoEnabled ? Colors.white : Colors.red, _toggleCamera),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCallButton(IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: color.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}
