import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../screens/patientnesrine/doctors_list_screen.dart';

// ─── Design tokens ───────────────────────────────────────────────
const _kPink   = Color(0xFFEC4899);
const _kPurple = Color(0xFFA855F7);
const _kViolet = Color(0xFF7C3AED);
const _kBg     = Color(0xFFF9F5FF);
const _kSurface = Color(0xFFFFFFFF);
const _kBubble  = 22.0;
const _kUserGrad = LinearGradient(
  colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);
const _kAiGrad = LinearGradient(
  colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);

// ─── Main widget ─────────────────────────────────────────────────
class AiAssistantChat extends StatefulWidget {
  final String? userId;
  const AiAssistantChat({super.key, this.userId});

  @override
  State<AiAssistantChat> createState() => _AiAssistantChatState();
}

class _AiAssistantChatState extends State<AiAssistantChat>
    with SingleTickerProviderStateMixin {

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  String _currentMode = 'symptoms';
  bool _isLoading = false;
  String? _currentConversationId;
  XFile? _imageFile;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();


  // Voice
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  double _speechLevel = 0.0;
  bool _speechEnabled = false;

  // ONE shared animation controller for all subtle animations
  // (mic pulse + typing dots). Avatar/empty state use CSS-style
  // low-frequency animations via TweenAnimationBuilder.
  late AnimationController _loopCtrl;
  late Animation<double> _loopAnim;

  @override
  void initState() {
    super.initState();
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loopAnim = CurvedAnimation(parent: _loopCtrl, curve: Curves.easeInOut);
    _initVoice();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // If no conversationId is set, check if we have an active one or just start fresh
    if (_currentConversationId != null) {
      setState(() => _isLoading = true);
      try {
        final messages = await ApiService.getAiConversationMessages(_currentConversationId!);
        setState(() {
          _messages.clear();
          for (var m in messages) {
            final role = m['role'];
            final content = m['content'];
            final isUser = (role == 'user');
            
            if (!isUser) {
              try {
                // Try parsing JSON response types
                final clean = content.trim().startsWith('```')
                    ? content.trim().split('\n').sublist(1, content.trim().split('\n').length - 1).join('\n').trim()
                    : content.trim();
                _messages.add({'data': jsonDecode(clean), 'isUser': false});
              } catch (_) {
                _messages.add({'text': content, 'isUser': false});
              }
            } else {
              _messages.add({'text': content, 'isUser': true});
            }
          }
        });
      } catch (e) {
        debugPrint('History load error: $e');
      } finally {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _initVoice() async {
    if (!mounted) return;
    try {
      // Initialize STT only if not already initialized
      if (!_speech.isAvailable) {
        _speechEnabled = await _speech.initialize(
          onStatus: (_) {},
          onError: (e) => debugPrint('STT err: $e'),
        );
      }
      

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Voice Init Error: $e');
    }
  }



  void _listen() async {
    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;
      if (_speechEnabled) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (r) => setState(() => _controller.text = r.recognizedWords),
          localeId: 'fr-FR',
          onSoundLevelChange: (l) => setState(() => _speechLevel = l),
        );
      }
    } else {
      setState(() { _isListening = false; _speechLevel = 0.0; });
      await _speech.stop();
    }
  }

  @override
  void dispose() {
    _loopCtrl.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _speech.cancel();

    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource src) async {
    try {
      final f = await _picker.pickImage(source: src, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
      if (f != null) {
        final b = await f.readAsBytes();
        setState(() { _imageFile = f; _imageBase64 = base64Encode(b); });
      }
    } catch (e) { debugPrint('Pick image error: $e'); }
  }

  void _removeImage() => setState(() { _imageFile = null; _imageBase64 = null; });

  void _sendMessage(String text) async {

    final effectiveText = text.trim().isEmpty && _imageBase64 != null
        ? 'Analyse cette image médicale'
        : text.trim();
    if (effectiveText.isEmpty && _imageBase64 == null) return;

    final b64 = _imageBase64;
    final imgPath = _imageFile?.path;

    setState(() {
      _messages.add({'text': effectiveText, 'isUser': true, 'imagePath': imgPath});
      _isLoading = true;
      _imageFile = null;
      _imageBase64 = null;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      if (_currentConversationId == null) {
        final conv = await ApiService.createAiConversation(effectiveText);
        _currentConversationId = conv['_id'];
      } else {
        await ApiService.addAiMessage(
          conversationId: _currentConversationId!,
          role: 'user', content: effectiveText, type: 'text',
        );
      }

      // CALL NGROK for generation
      final reply = (text.trim().isEmpty && imgPath != null)
          ? await ApiService.analyzeImage(filePath: imgPath)
          : await ApiService.chatWithAI(
              message: effectiveText,
            );

      if (mounted) {
        setState(() {
          try {
            final clean = reply.trim().startsWith('```')
                ? reply.trim().split('\n').sublist(1, reply.trim().split('\n').length - 1).join('\n').trim()
                : reply.trim();
            _messages.add({'data': jsonDecode(clean), 'isUser': false});
          } catch (_) {
            _messages.add({'text': reply, 'isUser': false});
          }
          _isLoading = false;
        });
        _scrollToBottom();

        // SAVE RESPONSE TO NESTJS
        if (_currentConversationId != null) {
          String type = 'sentence';
          try {
            if (reply.trim().startsWith('{')) {
              type = (jsonDecode(reply.trim()) as Map)['type'] ?? 'sentence';
            }
          } catch (_) {}
          await ApiService.addAiMessage(
            conversationId: _currentConversationId!,
            role: 'assistant', content: reply, type: type,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'text': 'Oups 😣 Un souci est survenu, réessaie dans un moment !', 'isUser': false});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  // ════════════════════════════════════════════ BUILD ══════════════
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          if (_isLoading) RepaintBoundary(child: _buildTypingIndicator()),
          _buildImagePreview(),
          _buildInputBar(),
          _buildDisclaimer(),
        ],
      ),
    );
  }

  // ─── Handle ──────────────────────────────────────────────────────
  Widget _buildHandle() => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 36, height: 4,
      decoration: BoxDecoration(
        color: _kPurple.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  // ─── Header ──────────────────────────────────────────────────────
  // Static layout – no AnimatedBuilder here to avoid full-header rebuilds
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
      child: Row(
        children: [
          // Avatar: isolated repaint boundary + loop animation via AnimatedBuilder
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _loopCtrl,
              builder: (_, child) {
                final scale = 0.9 + (_loopCtrl.value * 0.2); // Maps 0..1 to 0.9..1.1
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x44EC4899), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: const Center(child: Text('✨', style: TextStyle(fontSize: 22))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Média ✦',
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: _kViolet)),
                Row(children: [
                  Container(width: 7, height: 7,
                      decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('En ligne · là pour toi 💜',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ]),
              ],
            ),
          ),
          _iconBtn(Icons.history_rounded, _showHistory, _kViolet.withOpacity(0.08), _kViolet),
          const SizedBox(width: 6),
          _iconBtn(Icons.add_rounded, () => setState(() {
            _messages.clear();
            _currentConversationId = null;
          }), const Color(0xFFE8FFF0), const Color(0xFF22C55E)),
          const SizedBox(width: 6),
          _iconBtn(Icons.close_rounded, () => Navigator.pop(context),
              Colors.grey.shade100, Colors.grey.shade500),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, Color bg, Color fg) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: fg),
        ),
      );

  // ─── Message list ────────────────────────────────────────────────
  Widget _buildMessageList() {
    if (_messages.isEmpty && !_isLoading) return _buildEmptyState();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildChatBubble(_messages[i]),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gentle float via isolated AnimatedBuilder
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _loopCtrl,
                builder: (_, child) {
                  final dy = _loopCtrl.value * -8.0; // Maps 0..1 to 0..-8
                  return Transform.translate(offset: Offset(0, dy), child: child);
                },
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Center(child: Text('🩺', style: TextStyle(fontSize: 44))),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Bonjour, je suis Média 👋',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _kViolet)),
            const SizedBox(height: 8),
            Text("Ton assistante santé bienveillante.\nPose-moi n'importe quelle question !",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.55)),
          ],
        ),
      ),
    );
  }

  // ─── Chat bubble ─────────────────────────────────────────────────
  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final bool isUser = msg['isUser'] ?? false;
    final String? text = msg['text'];
    final Map<String, dynamic>? rawData = msg['data'];
    final String? imagePath = msg['imagePath'];
    final Map<String, dynamic>? data = (rawData != null && rawData.containsKey('success') && rawData.containsKey('response'))
        ? rawData['response'] as Map<String, dynamic>?
        : rawData;

    if (!isUser && data != null) {
      final type = data['type']?.toString();
      final isExpanded = msg['isExpanded'] ?? false;
      final toggle = () => setState(() => msg['isExpanded'] = !isExpanded);

      if (type == 'paragraph' || type == 'sentence') return _buildParagraphBubble(data, isExpanded, toggle);
      if (type == 'steps')    return _buildStepsBubble(data);
      if (type == 'causes')   return _buildCausesBubble(data);
      if (type == 'warning')  return _buildWarningCard(data, isExpanded, toggle);
      if (type == 'medicine') return _buildMedicineCard(data);
      if (type == 'cards' || data.containsKey('causes')) return _buildAiResponseCards(data);
    }

    final displayText = text ?? (data != null ? (data['text'] ?? data['title'] ?? '...') : '...');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) _aiDot(),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isUser ? 16 : 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: isUser ? _kUserGrad : null,
                    color: isUser ? null : _kSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(_kBubble),
                      topRight: const Radius.circular(_kBubble),
                      bottomLeft: Radius.circular(isUser ? _kBubble : 6),
                      bottomRight: Radius.circular(isUser ? 6 : _kBubble),
                    ),
                    boxShadow: [BoxShadow(
                      color: isUser ? _kPink.withOpacity(0.18) : Colors.black.withOpacity(0.04),
                      blurRadius: 14, offset: const Offset(0, 4),
                    )],
                    border: isUser ? null : Border.all(color: _kPurple.withOpacity(0.07)),
                  ),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (imagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: kIsWeb 
                              ? Image.network(imagePath, width: 200, fit: BoxFit.cover)
                              : Image.file(File(imagePath), width: 200, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(displayText,
                        style: GoogleFonts.poppins(
                          color: isUser ? Colors.white : AppColors.textPrimary,
                          fontSize: 14, height: 1.45,
                          fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                        )),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(gradient: _kAiGrad, shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.person_rounded, color: Colors.white, size: 16)),
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isUser ? 0 : 42, right: isUser ? 38 : 0),
            child: Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(isUser ? 'Toi' : 'Média',
                    style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w600)),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiDot() => Container(
    width: 30, height: 30,
    margin: const EdgeInsets.only(right: 8, bottom: 2),
    decoration: const BoxDecoration(gradient: _kAiGrad, shape: BoxShape.circle),
    child: const Center(child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 12))),
  );

  // ─── Paragraph bubble ───────────────────────────────────────────
  Widget _buildParagraphBubble(Map<String, dynamic> data, bool isExpanded, VoidCallback onToggle) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _aiDot(),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(_kBubble), topRight: Radius.circular(_kBubble),
                    bottomLeft: Radius.circular(6), bottomRight: Radius.circular(_kBubble),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
                  border: Border.all(color: _kPurple.withOpacity(0.07)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['message'] ?? data['text'] ?? '',
                      style: GoogleFonts.poppins(fontSize: 14, height: 1.55, color: AppColors.textPrimary),
                      maxLines: isExpanded ? null : 4,
                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    if ((data['message']?.toString() ?? data['text']?.toString() ?? '').length > 150)
                      GestureDetector(
                        onTap: onToggle,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            isExpanded ? 'Voir moins' : 'Voir plus...',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: _kPurple),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (data['category'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 42),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(data['category'].toString().toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
            ),
          ),
      ],
    ),
  );

  // ─── Steps bubble ────────────────────────────────────────────────
  Widget _buildStepsBubble(Map<String, dynamic> data) {
    final steps = (data['steps'] as List?)?.cast<String>() ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kPurple.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(children: [
                const Text('📋', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(data['title'] ?? 'Instructions',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                if (data['medicine_name'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: Text(data['medicine_name'],
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 26, height: 26,
                      decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${e.key + 1}',
                          style: GoogleFonts.poppins(color: _kViolet, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.value,
                        style: GoogleFonts.poppins(fontSize: 13, height: 1.45, color: AppColors.textPrimary))),
                  ]),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Warning card ────────────────────────────────────────────────
  Widget _buildWarningCard(Map<String, dynamic> data, bool isExpanded, VoidCallback onToggle) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Color(0xFFFF5252), shape: BoxShape.circle),
              child: const Text('⚠️', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? 'Attention !',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFB71C1C))),
                Text('Consulte un médecin dès que possible',
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFE57373), fontWeight: FontWeight.w600)),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['message'] ?? data['text'] ?? '',
                style: GoogleFonts.poppins(fontSize: 13.5, height: 1.6, color: const Color(0xFF8B0000), fontWeight: FontWeight.w500),
                maxLines: isExpanded ? null : 4,
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if ((data['message']?.toString() ?? data['text']?.toString() ?? '').length > 130)
                GestureDetector(
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      isExpanded ? 'Voir moins' : 'Lire plus...',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFB71C1C)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsListScreen())),
              icon: const Icon(Icons.message_rounded, size: 17),
              label: Text('Contacter mon médecin', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ─── Causes bubble ───────────────────────────────────────────────
  Widget _buildCausesBubble(Map<String, dynamic> data) {
    final causes = (data['causes'] as List?)?.cast<String>() ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFD97706)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(children: [
                const Text('🔍', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(data['title'] ?? 'Causes possibles',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: causes.map((cause) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• ', style: TextStyle(fontSize: 18, color: Colors.amber, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(cause,
                        style: GoogleFonts.poppins(fontSize: 13, height: 1.45, color: AppColors.textPrimary))),
                  ]),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Medicine card ───────────────────────────────────────────────
  Widget _buildMedicineCard(Map<String, dynamic> data) {
    final brand = data['brand'] ?? data['name'] ?? 'Médicament';
    final generic = data['generic'] ?? 'N/A';
    final strength = data['strength'] ?? '';
    final usedFor = data['used_for'] ?? 'N/A';
    final howItWorks = data['how_it_works'] ?? 'N/A';
    final dosage = data['dosage'] ?? 'N/A';
    final drugClass = data['drug_class'] ?? 'N/A';
    final instructions = data['instructions'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kPurple.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: _kAiGrad,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(children: [
                const Text('💊', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drugClass != 'N/A' ? drugClass : 'Conseil Médical',
                        style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600)),
                    Text(brand,
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    if (strength.isNotEmpty)
                       Text(strength, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  ],
                )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (instructions != null) ...[
                    _medInfoRow(Icons.info_outline_rounded, 'Instructions', instructions),
                  ] else ...[
                    _medInfoRow(Icons.science_rounded, 'Générique', generic),
                    const Divider(height: 16),
                    _medInfoRow(Icons.health_and_safety_rounded, 'Utilisation', usedFor),
                    const Divider(height: 16),
                    _medInfoRow(Icons.auto_fix_high_rounded, 'Mécanisme', howItWorks),
                    const Divider(height: 16),
                    _medInfoRow(Icons.timer_rounded, 'Dosage', dosage),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medInfoRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: _kPurple),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: _kPurple)),
        ]),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
      ],
    );
  }

  // ─── AI response cards ───────────────────────────────────────────
  Widget _buildAiResponseCards(Map<String, dynamic> data) {
    final causes  = (data['causes']  as List?)?.cast<String>() ?? [];
    final actions = (data['actions'] as List?)?.cast<String>() ?? [];
    final warning = data['warning']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (causes.isNotEmpty) ...[
          _buildCardSection(emoji: '🔍', title: 'Causes possibles', subtitle: '${causes.length} pistes',
              items: causes, hdrColors: const [Color(0xFF34D399), Color(0xFF10B981)],
              chipBg: const Color(0xFFECFDF5), chipText: const Color(0xFF065F46)),
          const SizedBox(height: 12),
        ],
        if (actions.isNotEmpty) ...[
          _buildCardSection(emoji: '✅', title: 'À faire', subtitle: 'Actions simples',
              items: actions, hdrColors: const [Color(0xFF818CF8), Color(0xFF6366F1)],
              chipBg: const Color(0xFFEEF2FF), chipText: const Color(0xFF3730A3)),
          const SizedBox(height: 12),
        ],
        if (warning.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🚨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Consulte si…', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C))),
                const SizedBox(height: 4),
                Text(warning, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7F1D1D), height: 1.45)),
              ])),
            ]),
          ),
      ]),
    );
  }

  Widget _buildCardSection({
    required String emoji, required String title, required String subtitle,
    required List<String> items, required List<Color> hdrColors,
    required Color chipBg, required Color chipText,
  }) => Container(
    decoration: BoxDecoration(
      color: _kSurface, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kPurple.withOpacity(0.07)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: hdrColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.85))),
          ]),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(12)),
            child: Text(item, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: chipText)),
          )).toList(),
        ),
      ),
    ]),
  );

  // ─── Typing indicator ────────────────────────────────────────────
  // Uses a single AnimationController scoped inside a RepaintBoundary
  Widget _buildTypingIndicator() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      _aiDot(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_kBubble), topRight: Radius.circular(_kBubble),
            bottomLeft: Radius.circular(6), bottomRight: Radius.circular(_kBubble),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
          border: Border.all(color: _kPurple.withOpacity(0.07)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Dot(delay: 0.0, ctrl: _loopCtrl),
          const SizedBox(width: 5),
          _Dot(delay: 0.2, ctrl: _loopCtrl),
          const SizedBox(width: 5),
          _Dot(delay: 0.4, ctrl: _loopCtrl),
        ]),
      ),
      const SizedBox(width: 10),
      Text('Média réfléchit…',
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
    ]),
  );


  // ─── Image preview ───────────────────────────────────────────────
  Widget _buildImagePreview() {
    if (_imageFile == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 76, width: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kPink.withOpacity(0.35), width: 2),
            image: DecorationImage(image: FileImage(File(_imageFile!.path)), fit: BoxFit.cover),
            boxShadow: [BoxShadow(color: _kPink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
        ),
        Positioned(top: -6, right: -6,
          child: GestureDetector(
            onTap: _removeImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFFF5252)),
            ),
          )),
      ]),
    );
  }

  // ─── Input bar ───────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => Container(
              decoration: const BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.only(bottom: 18)),
                _imgTile(Icons.camera_alt_rounded, 'Prendre une photo 📷', ImageSource.camera),
                _imgTile(Icons.photo_library_rounded, 'Depuis la galerie 🖼️', ImageSource.gallery),
              ]),
            ),
          ),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: _kPurple.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.add_photo_alternate_rounded, color: _kViolet, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: _kSurface, borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _kPurple.withOpacity(0.14)),
              boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Dis-moi tout… 💬',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              // Mic – only the icon changes, no AnimatedBuilder needed
              GestureDetector(
                onTap: _listen,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: _isListening ? _kPink : AppColors.textLight, size: 20,
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _sendMessage(_controller.text),
          child: Container(
            width: 46, height: 46,
            decoration: const BoxDecoration(
              gradient: _kUserGrad, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x44EC4899), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _imgTile(IconData icon, String label, ImageSource src) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: _kPurple.withOpacity(0.08), shape: BoxShape.circle),
      child: Icon(icon, color: _kViolet, size: 22),
    ),
    title: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    onTap: () { Navigator.pop(context); _pickImage(src); },
  );

  // ─── Disclaimer ──────────────────────────────────────────────────
  Widget _buildDisclaimer() => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('💡', style: TextStyle(fontSize: 12)),
      const SizedBox(width: 6),
      Text("Je suis une IA — consulte toujours un médecin.",
          style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textLight, fontWeight: FontWeight.w500)),
    ]),
  );

  // ─── History sheet ───────────────────────────────────────────────
  void _showHistory() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await ApiService.getAiConversations();
      if (!mounted) return;
      setState(() => _isLoading = false);
      showModalBottomSheet(
        context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 6), width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(children: [
                const Text('📖', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text('Tes conversations',
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: _kViolet)),
              ]),
            ),
            Expanded(
              child: conversations.isEmpty
                  ? Center(child: Text("Aucune conversation pour l'instant 🌱",
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = conversations[i];
                        return ListTile(
                          leading: Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                            child: const Center(child: Text('💬', style: TextStyle(fontSize: 18))),
                          ),
                          title: Text(c['title'] ?? 'Sans titre',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(c['firstMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: () { Navigator.pop(context); _loadConversation(c['_id']); },
                        );
                      },
                    ),
            ),
          ]),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Load conversation ───────────────────────────────────────────
  void _loadConversation(String id) async {
    setState(() => _isLoading = true);
    try {
      final msgs = await ApiService.getAiConversationMessages(id);
      if (mounted) {
        setState(() {
          _currentConversationId = id;
          _messages.clear();
          for (final m in msgs) {
            final content = m['content'].toString();
            if (m['role'] == 'assistant') {
              try {
                if (content.trim().startsWith('{') || content.trim().startsWith('```')) {
                  final raw = content.trim().startsWith('```')
                      ? content.trim().split('\n').sublist(1, content.trim().split('\n').length - 1).join('\n').trim()
                      : content.trim();
                  _messages.add({'data': jsonDecode(raw), 'isUser': false});
                } else {
                  _messages.add({'text': content, 'isUser': false});
                }
              } catch (_) {
                _messages.add({'text': content, 'isUser': false});
              }
            } else {
              _messages.add({'text': content, 'isUser': true});
            }
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── Typing dot – isolated widget with its own repaint boundary ───
class _Dot extends StatelessWidget {
  final double delay;
  final AnimationController ctrl;
  const _Dot({required this.delay, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final t = ((ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final scale = 0.6 + 0.6 * (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withOpacity(0.3 + 0.7 * scale.clamp(0, 1)),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}
