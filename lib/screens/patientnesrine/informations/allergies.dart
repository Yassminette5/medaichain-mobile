import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/user_info_view_model.dart';
import '../../../../core/theme/app_colors.dart';

/// ----------------------
/// Allergies Screen (Step 5 of 6)
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
    "Peanuts",
    "Dairy",
    "Seafood",
    "Eggs",
    "Gluten",
    "Soy",
    "Pollen",
    "Penicillin"
  ];
  final TextEditingController customController = TextEditingController();
  final Color _brandColor = AppColors.primary;
  final Color _accentColor = AppColors.secondary;

  @override
  void dispose() {
    customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserInfoViewModel>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      children: [
                        const TextSpan(text: "Do you have "),
                        TextSpan(
                          text: "any allergies?",
                          style: TextStyle(color: _accentColor),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Select common allergies or add your own.",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Common Allergies Chips (Horizontal Scroll)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: commonAllergies.length,
                    itemBuilder: (context, index) {
                      final allergy = commonAllergies[index];
                      final selected = viewModel.allergies.contains(allergy);
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            if (selected) {
                              viewModel.removeAllergy(allergy);
                            } else {
                              viewModel.addAllergy(allergy);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? _brandColor : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              allergy,
                              style: GoogleFonts.poppins(
                                color: selected ? Colors.white : Colors.white70,
                                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            controller: customController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Add your allergy...",
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () {
                          final text = customController.text.trim();
                          if (text.isNotEmpty) {
                            viewModel.addAllergy(text);
                            customController.clear();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: _brandColor.withValues(alpha: 0.3), blurRadius: 10)
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Your Allergies List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Your Allergies:",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                viewModel.allergies.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "No allergies selected yet.",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: viewModel.allergies.length,
                        itemBuilder: (context, index) {
                          final allergy = viewModel.allergies.toList()[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    allergy,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => viewModel.removeAllergy(allergy),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Next Button (Standardized with Gender Screen)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30, top: 10),
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
        ),
      ],
    );
  }
}
