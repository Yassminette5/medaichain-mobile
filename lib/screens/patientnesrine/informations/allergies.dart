import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/user_info_view_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../patientnesrine/main_screen.dart';

/// ----------------------
/// Allergies Screen (Step 5 of 5)
/// ----------------------
class AllergiesScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AllergiesScreen({super.key, required this.onNext, required this.onBack});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final List<String> commonAllergies = [
    "Arachides",
    "Produits laitiers",
    "Fruits de mer",
    "Oeufs",
    "Gluten",
    "Soja",
    "Pollen",
    "Pénicilline"
  ];
  final TextEditingController customController = TextEditingController();

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
              TextSpan(text: "Avez-vous des\n"),
              TextSpan(
                text: "Allergies ?",
                style: TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        
        Text(
          "Sélectionnez celles qui s'appliquent ou ajoutez-en d'autres.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 30),

        // Common Allergies Chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: commonAllergies.map((allergy) {
            final selected = viewModel.allergies.contains(allergy);
            return GestureDetector(
              onTap: () {
                if (selected) {
                  viewModel.removeAllergy(allergy);
                } else {
                  viewModel.addAllergy(allergy);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
                  ),
                  boxShadow: selected ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 10)
                  ] : [],
                ),
                child: Text(
                  allergy,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 30),

        // Custom Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: customController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Autre allergie...",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  final text = customController.text.trim();
                  if (text.isNotEmpty) {
                    viewModel.addAllergy(text);
                    customController.clear();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Selected Allergies Display (if any custom ones)
        if (viewModel.allergies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
               height: 40,
               child: ListView(
                 scrollDirection: Axis.horizontal,
                 children: viewModel.allergies.where((a) => !commonAllergies.contains(a)).map((allergy) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(allergy, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => viewModel.removeAllergy(allergy),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    );
                 }).toList(),
               ),
            ),
          ),

        const Spacer(),

        // Finish Button
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: ScaleTransition(
            scale: const AlwaysStoppedAnimation(1.0),
            child: Container(
              height: 70,
              width: 180, // Wider for "Terminer"
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF34D399)]),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4), 
                    blurRadius: 20, 
                    spreadRadius: 5
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                child: InkWell(
                  onTap: widget.onNext,
                  borderRadius: BorderRadius.circular(35),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Terminer",
                        style: GoogleFonts.poppins(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                    ],
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
