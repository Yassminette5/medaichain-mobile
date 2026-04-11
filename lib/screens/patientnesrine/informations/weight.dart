import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/user_info_view_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/weight_dial_painter.dart';

/// ----------------------
/// Weight Screen (Step 4 of 5)
/// ----------------------
class WeightStepScreen extends StatefulWidget {
  final VoidCallback onNext;

  const WeightStepScreen({super.key, required this.onNext});

  @override
  State<WeightStepScreen> createState() => _WeightStepScreenState();
}

class _WeightStepScreenState extends State<WeightStepScreen> {
  final int _minWeight = 40;
  final int _maxWeight = 200;
  final Color _brandColor = AppColors.primary;
  final Color _accentColor = AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserInfoViewModel>(context);
    int currentWeight = viewModel.currentWeight;

    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Title
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            children: [
              const TextSpan(text: "Your "),
              TextSpan(
                text: "current weight",
                style: TextStyle(color: _accentColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "We will use this data to give you a better diet type for you.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),

        const SizedBox(height: 30),

        // Weight Value Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          decoration: BoxDecoration(
            color: _brandColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$currentWeight ",
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: "kg",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Circular Dial
        Container(
          width: 240,
          height: 240,
          child: CustomPaint(
            painter: WeightDialPainter(
              currentWeight: currentWeight,
              minWeight: _minWeight,
              maxWeight: _maxWeight,
              tealColor: _brandColor,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Linear Slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _brandColor,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: Colors.white,
              overlayColor: _brandColor.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: currentWeight.toDouble(),
              min: _minWeight.toDouble(),
              max: _maxWeight.toDouble(),
              onChanged: (val) {
                viewModel.setCurrentWeight(val.toInt());
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Next Button (Standardized with Gender Screen)
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4), 
                  blurRadius: 20, 
                  spreadRadius: 5
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.onNext,
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
