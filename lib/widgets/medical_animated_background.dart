import 'dart:math';
import 'package:flutter/material.dart';

/// Premium animated medical background — cute floating health icons
/// with soft pastel bubbles and gentle breathing animations.
/// Clean and professional, no DNA helix or ECG lines.
class MedicalAnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool showIcons;
  final bool showParticles;
  final bool showWaves;
  final double iconOpacity;
  final double particleOpacity;

  const MedicalAnimatedBackground({
    super.key,
    required this.child,
    this.showIcons = true,
    this.showParticles = true,
    this.showWaves = true,
    this.iconOpacity = 0.07,
    this.particleOpacity = 0.06,
  });

  @override
  State<MedicalAnimatedBackground> createState() =>
      _MedicalAnimatedBackgroundState();
}

class _MedicalAnimatedBackgroundState extends State<MedicalAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _driftController;
  late AnimationController _pulseController;
  late List<_FloatingMedicalIcon> _icons;
  late List<_SoftBubble> _bubbles;
  final _rng = Random(42);

  // Cute medical icons — all health/clinic related
  static final _medicalItems = [
    _IconDef(Icons.favorite_rounded, Color(0xFFE91E63)),              // Heart
    _IconDef(Icons.local_hospital_rounded, Color(0xFF1E88E5)),        // Hospital +
    _IconDef(Icons.medical_services_rounded, Color(0xFF00ACC1)),      // Medical bag
    _IconDef(Icons.vaccines_rounded, Color(0xFF43A047)),              // Syringe
    _IconDef(Icons.healing_rounded, Color(0xFFFFA726)),               // Band-aid
    _IconDef(Icons.monitor_heart_rounded, Color(0xFFEC407A)),         // HeartBeat
    _IconDef(Icons.medication_rounded, Color(0xFF7E57C2)),            // Pill
    _IconDef(Icons.health_and_safety_rounded, Color(0xFF26A69A)),     // Shield
    _IconDef(Icons.bloodtype_rounded, Color(0xFFEF5350)),             // Blood
    _IconDef(Icons.spa_rounded, Color(0xFF66BB6A)),                   // Wellness
    _IconDef(Icons.psychology_rounded, Color(0xFF5C6BC0)),            // Brain
    _IconDef(Icons.child_care_rounded, Color(0xFFFFB74D)),            // Child
  ];

  @override
  void initState() {
    super.initState();

    // Slow smooth drift — very gentle floating
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();

    // Gentle breathing pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Generate 12 floating icons spread across the area
    _icons = List.generate(12, (i) {
      final item = _medicalItems[i % _medicalItems.length];
      return _FloatingMedicalIcon(
        icon: item.icon,
        color: item.color,
        x: 0.08 + _rng.nextDouble() * 0.84,
        y: 0.06 + _rng.nextDouble() * 0.88,
        size: 22 + _rng.nextDouble() * 12,
        floatRadius: 12 + _rng.nextDouble() * 18,
        speed: 0.12 + _rng.nextDouble() * 0.18,
        phase: _rng.nextDouble() * 2 * pi,
      );
    });

    // Generate 6 soft pastel bubbles
    _bubbles = List.generate(6, (i) {
      final colors = [
        const Color(0xFF1E88E5), // Blue
        const Color(0xFF00ACC1), // Cyan
        const Color(0xFFEC407A), // Pink
        const Color(0xFF43A047), // Green
        const Color(0xFF7E57C2), // Purple
        const Color(0xFF26A69A), // Teal
      ];
      return _SoftBubble(
        x: 0.1 + _rng.nextDouble() * 0.8,
        y: 0.1 + _rng.nextDouble() * 0.8,
        radius: 80 + _rng.nextDouble() * 140,
        color: colors[i % colors.length],
        phase: _rng.nextDouble() * 2 * pi,
        speed: 0.08 + _rng.nextDouble() * 0.12,
      );
    });
  }

  @override
  void dispose() {
    _driftController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ═══ 1. Soft Base Gradient ═══
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF0F7FF),
                  Color(0xFFF5F3FF),
                  Color(0xFFF0FDFA),
                  Color(0xFFF8FAFC),
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),
        ),

        // ═══ 2. Soft Gradient Bubbles (breathing) ═══
        if (widget.showParticles)
          AnimatedBuilder(
            animation: Listenable.merge([_driftController, _pulseController]),
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final t = _driftController.value;
                  final p = _pulseController.value;
                  return Stack(
                    children: _bubbles.map((b) {
                      final dx = sin(t * 2 * pi * b.speed + b.phase) * 30;
                      final dy = cos(t * 2 * pi * b.speed * 0.7 + b.phase) * 25;
                      final x = b.x * constraints.maxWidth + dx;
                      final y = b.y * constraints.maxHeight + dy;
                      final scale = 0.9 + p * 0.2;

                      return Positioned(
                        left: x - b.radius * scale / 2,
                        top: y - b.radius * scale / 2,
                        child: Container(
                          width: b.radius * scale,
                          height: b.radius * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                b.color.withOpacity(0.045 + p * 0.015),
                                b.color.withOpacity(0.01),
                                b.color.withOpacity(0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),

        // ═══ 3. Subtle Dot Grid ═══
        Positioned.fill(
          child: CustomPaint(painter: _DotGridPainter()),
        ),

        // ═══ 4. Floating Medical Icons ═══
        if (widget.showIcons)
          AnimatedBuilder(
            animation: Listenable.merge([_driftController, _pulseController]),
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final t = _driftController.value;
                  final p = _pulseController.value;

                  return Stack(
                    children: _icons.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ic = entry.value;

                      // Smooth lissajous drift
                      final dx = sin(t * 2 * pi * ic.speed + ic.phase) *
                          ic.floatRadius;
                      final dy = sin(t * 2 * pi * ic.speed * 1.4 +
                              ic.phase +
                              pi / 3) *
                          ic.floatRadius * 0.8;
                      final x = ic.x * constraints.maxWidth + dx;
                      final y = ic.y * constraints.maxHeight + dy;

                      // Very gentle rotation
                      final rotation =
                          sin(t * 2 * pi * 0.15 + ic.phase) * 0.12;

                      // Per-icon opacity breathing
                      final opPulse =
                          0.75 + sin(t * 2 * pi * 0.4 + i * 0.6) * 0.25;

                      final bgSize = ic.size + 16;

                      return Positioned(
                        left: x - bgSize / 2,
                        top: y - bgSize / 2,
                        child: Transform.rotate(
                          angle: rotation,
                          child: Container(
                            width: bgSize,
                            height: bgSize,
                            decoration: BoxDecoration(
                              color: ic.color.withOpacity(
                                  0.05 * opPulse * (0.8 + p * 0.4)),
                              borderRadius: BorderRadius.circular(bgSize * 0.3),
                              border: Border.all(
                                color: ic.color.withOpacity(
                                    0.06 * opPulse * (0.8 + p * 0.4)),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                ic.icon,
                                size: ic.size,
                                color: ic.color.withOpacity(
                                    widget.iconOpacity *
                                        opPulse *
                                        (0.8 + p * 0.4)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),

        // ═══ 5. Corner Glow Accents ═══
        // Top-right blue glow
        Positioned(
          top: -60,
          right: -60,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final p = _pulseController.value;
              return Container(
                width: 220 + p * 20,
                height: 220 + p * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1E88E5).withOpacity(0.05 + p * 0.015),
                      const Color(0xFF1E88E5).withOpacity(0.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom-left green glow
        Positioned(
          bottom: -50,
          left: -50,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final p = _pulseController.value;
              return Container(
                width: 180 + p * 15,
                height: 180 + p * 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF43A047).withOpacity(0.04 + p * 0.01),
                      const Color(0xFF43A047).withOpacity(0.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Center-left soft pink glow
        Positioned(
          top: 200,
          left: -30,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final p = _pulseController.value;
              return Container(
                width: 140 + p * 15,
                height: 140 + p * 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFEC407A).withOpacity(0.03 + p * 0.01),
                      const Color(0xFFEC407A).withOpacity(0.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ═══ Child Content ═══
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

// ── Data Models ──

class _IconDef {
  final IconData icon;
  final Color color;
  const _IconDef(this.icon, this.color);
}

class _FloatingMedicalIcon {
  final IconData icon;
  final Color color;
  final double x, y, size, floatRadius, speed, phase;

  _FloatingMedicalIcon({
    required this.icon,
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.floatRadius,
    required this.speed,
    required this.phase,
  });
}

class _SoftBubble {
  final double x, y, radius, phase, speed;
  final Color color;

  _SoftBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.phase,
    required this.speed,
  });
}

// ── Painters ──

/// Clean subtle dot grid (professional clinical feel)
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    const spacing = 36.0;
    const dotRadius = 0.6;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
