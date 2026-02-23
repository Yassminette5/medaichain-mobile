import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/user_info_view_model.dart';
import '../../../../core/theme/app_colors.dart';

/// ----------------------
/// Weight Screen (Step 4 of 5)
/// ----------------------
class WeightStepScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WeightStepScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserInfoViewModel>(context);
    int currentWeight = viewModel.currentWeight;

    final int minWeight = 40;
    final int maxWeight = 150;

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
            children: const [
              TextSpan(text: "Quel est votre\n"),
              TextSpan(
                text: "Poids ?",
                style: TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 50),

        // Main Display
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.2), 
                  width: 2
                ),
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  "$currentWeight",
                  style: GoogleFonts.poppins(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                Text(
                  "kg",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Slider Container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("$minWeight kg", style: const TextStyle(color: Colors.white54)),
                    Text("$maxWeight kg", style: const TextStyle(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.secondary,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: AppColors.secondary.withValues(alpha: 0.2),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  ),
                  child: Slider(
                    value: currentWeight.toDouble(),
                    min: minWeight.toDouble(),
                    max: maxWeight.toDouble(),
                    onChanged: (val) {
                      viewModel.setCurrentWeight(val.toInt());
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Next Button
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: ScaleTransition(
            scale: const AlwaysStoppedAnimation(1.0),
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
                  onTap: onNext,
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
        ),
      ],
    );
  }
}
