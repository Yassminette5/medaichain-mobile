import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import '../../core/theme/futuristic_theme.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

/// Patient Access Request Screen with Security Emphasis
class PatientAccessRequestScreen extends StatefulWidget {
  const PatientAccessRequestScreen({super.key});

  @override
  State<PatientAccessRequestScreen> createState() => _PatientAccessRequestScreenState();
}

class _PatientAccessRequestScreenState extends State<PatientAccessRequestScreen> {
  final List<Map<String, dynamic>> _requests = [
    {'name': 'Jean Dupont', 'reason': 'Consultation urgente', 'time': 15, 'urgent': true},
    {'name': 'Marie Lambert', 'reason': 'Suivi médical', 'time': 30, 'urgent': false},
    {'name': 'Pierre Moreau', 'reason': 'Résultats analyses', 'time': 45, 'urgent': false},
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSecurityBadge(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FuturisticColors.glassWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FuturisticColors.glassBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => FuturisticColors.cyberGradient.createShader(bounds),
              child: const Text(
                'Demandes d\'Accès',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        showGlow: true,
        glowColor: FuturisticColors.neonGreen,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: FuturisticColors.blockchainGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonGreen, intensity: 0.4),
              ),
              child: const Icon(Icons.verified_user, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => FuturisticColors.blockchainGradient.createShader(bounds),
                    child: const Text(
                      'Sécurité Blockchain',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tous les accès sont enregistrés',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.shield_outlined,
              color: FuturisticColors.neonGreen.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final isUrgent = request['urgent'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        showGlow: isUrgent,
        glowColor: isUrgent ? const Color(0xFFEF4444) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: isUrgent
                        ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)])
                        : FuturisticColors.cyberGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      (request['name'] as String).split(' ').map((n) => n[0]).take(2).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            request['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (isUrgent) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['reason'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CountdownTimer(minutes: request['time'] as int),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _handleReject(request['name'] as String),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Refuser',
                        style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: NeonButton(
                    text: 'Accepter',
                    icon: Icons.check_circle_outline,
                    height: 48,
                    onPressed: () => _handleAccept(request['name'] as String),
                    gradient: FuturisticColors.blockchainGradient,
                    glowColor: FuturisticColors.neonGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAccept(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accès accordé à $name'),
        backgroundColor: FuturisticColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleReject(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accès refusé à $name'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Countdown Timer Widget
class _CountdownTimer extends StatefulWidget {
  final int minutes;
  
  const _CountdownTimer({required this.minutes});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.minutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FuturisticColors.neonYellow.withValues(alpha: 0.2),
            FuturisticColors.neonYellow.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FuturisticColors.neonYellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            color: FuturisticColors.neonYellow,
            size: 18,
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [FuturisticColors.neonYellow, FuturisticColors.neonYellow.withValues(alpha: 0.7)],
            ).createShader(bounds),
            child: Text(
              'Expire dans ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
