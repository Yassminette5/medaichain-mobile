import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme/futuristic_theme.dart';

/// Animated Gradient Mesh Background
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    FuturisticColors.primaryDark,
                    FuturisticColors.secondaryDark,
                    Color(0xFF2D1B4E),
                    FuturisticColors.secondaryDark,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  transform: GradientRotation(_controller.value * 2 * math.pi),
                ),
              ),
            );
          },
        ),
        // Floating orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top: 100 + math.sin(_controller.value * 2 * math.pi) * 30,
                  right: -50 + math.cos(_controller.value * 2 * math.pi) * 20,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          FuturisticColors.neonCyan.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 150 + math.cos(_controller.value * 2 * math.pi) * 25,
                  left: -60 + math.sin(_controller.value * 2 * math.pi) * 15,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          FuturisticColors.neonPurple.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 300 + math.sin((_controller.value + 0.5) * 2 * math.pi) * 20,
                  right: 50 + math.cos((_controller.value + 0.5) * 2 * math.pi) * 25,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          FuturisticColors.neonPink.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Content
        widget.child,
      ],
    );
  }
}
