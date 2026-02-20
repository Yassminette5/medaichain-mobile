import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure google_fonts is added
import '../../../../models/user_info_view_model.dart';
import '../../../../core/theme/app_colors.dart';

/// ----------------------
/// Gender Screen (Step 1 of 5)
/// ----------------------
class GenderScreen extends StatelessWidget {
  final VoidCallback onNextClicked;

  const GenderScreen({super.key, required this.onNextClicked});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserInfoViewModel>(context);

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
                text: "Genre ?",
                style: TextStyle(color: AppColors.secondary), // Pink accent
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Ces informations nous aident à personnaliser votre expérience médicale.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 50),

        // Gender Selection
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GenderButton(
              selectedGender: viewModel.gender,
              genderType: "Male", // Value stored
              label: "Homme",     // Label shown
              icon: Icons.male_rounded,
              onGenderChanged: viewModel.setGender,
            ),
            const SizedBox(width: 24),
            GenderButton(
              selectedGender: viewModel.gender,
              genderType: "Female",
              label: "Femme",
              icon: Icons.female_rounded,
              onGenderChanged: viewModel.setGender,
            ),
          ],
        ),

        const Spacer(),

        // Next Button (Floating Action Style)
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: ScaleTransition(
            scale: const AlwaysStoppedAnimation(1.0), // Can animate
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                gradient: viewModel.gender.isNotEmpty 
                    ? AppColors.primaryGradient 
                    : LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade600]), // Disabled state
                shape: BoxShape.circle,
                boxShadow: viewModel.gender.isNotEmpty 
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4), 
                          blurRadius: 20, 
                          spreadRadius: 5
                        )
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: viewModel.gender.isNotEmpty ? onNextClicked : null,
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

class GenderButton extends StatelessWidget {
  final String selectedGender;
  final String genderType;
  final String label;
  final IconData icon;
  final Function(String) onGenderChanged;

  const GenderButton({
    super.key,
    required this.selectedGender,
    required this.genderType,
    required this.label,
    required this.icon,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedGender == genderType;

    return GestureDetector(
      onTap: () => onGenderChanged(genderType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        width: 140,
        height: 160,
        decoration: BoxDecoration(
          // Glass effect + Gradient if selected
          gradient: isSelected 
              ? AppColors.primaryGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary.withValues(alpha: 0.5) 
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
