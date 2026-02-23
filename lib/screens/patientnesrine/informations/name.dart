import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_info_view_model.dart';

class NameStep extends StatefulWidget {
  final VoidCallback onNext;

  const NameStep({super.key, required this.onNext});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final model = Provider.of<UserInfoViewModel>(context, listen: false);
    _controller = TextEditingController(text: model.fullName);
    
    // Listen for changes in the model (e.g. when AuthProvider updates it in post-frame)
    model.addListener(_onModelChanged);
  }

  void _onModelChanged() {
    final model = Provider.of<UserInfoViewModel>(context, listen: false);
    if (_controller.text != model.fullName) {
      _controller.text = model.fullName;
    }
  }

  @override
  void dispose() {
    final model = Provider.of<UserInfoViewModel>(context, listen: false);
    model.removeListener(_onModelChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserInfoViewModel>(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Commençons par votre nom",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Vérifiez que votre nom complet est correct pour votre dossier médical.",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 48),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.small,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _controller,
              onChanged: (val) => viewModel.setFullName(val),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: "Nom complet",
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textGrey.withOpacity(0.5),
                ),
                border: InputBorder.none,
                icon: const Icon(Icons.badge_outlined, color: AppColors.primary),
              ),
            ),
          ),
          
          const Spacer(),
          
          GestureDetector(
            onTap: () {
              if (_controller.text.trim().isNotEmpty) {
                viewModel.setFullName(_controller.text.trim());
                widget.onNext();
              }
            },
            child: Container(
              width: double.infinity,
              height: 65,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.colored(AppColors.primary),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Suivant",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
