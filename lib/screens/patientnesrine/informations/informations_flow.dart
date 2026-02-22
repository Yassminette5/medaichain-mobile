import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../../models/user_info_view_model.dart';
import '../../../../services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../homeScreen.dart';
import '../main_screen.dart';
import 'gender.dart';
import 'date_naissance.dart';
import 'height.dart';
import 'weight.dart';
import 'allergies.dart';
import 'name.dart';

/// Orchestrator widget with Premium UI Wrapper
class InformationsFlow extends StatefulWidget {
  const InformationsFlow({super.key});

  @override
  State<InformationsFlow> createState() => _InformationsFlowState();
}

class _InformationsFlowState extends State<InformationsFlow> {
  final PageController _pageController = PageController();
  late UserInfoViewModel _vm;
  bool _isSaving = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _vm = UserInfoViewModel();
    // Initialize with existing user data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null && user.fullName != null) {
        _vm.setFullName(user.fullName!);
      }
    });
  }

  void _goToNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goToPrev() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finishAndSave() async {
    final vm = _vm;
    debugPrint('[InformationsFlow] _finishAndSave called');
    debugPrint('[InformationsFlow] vm.fullName: ${vm.fullName}');
    debugPrint('[InformationsFlow] vm.gender: ${vm.gender}');
    debugPrint('[InformationsFlow] vm.age: ${vm.age}');
    debugPrint('[InformationsFlow] vm.currentHeight: ${vm.currentHeight}');
    debugPrint('[InformationsFlow] vm.currentWeight: ${vm.currentWeight}');
    debugPrint('[InformationsFlow] vm.allergies: ${vm.allergies}');

    if (vm.age == null) {
      debugPrint('[InformationsFlow] Age is null, showing snackbar and returning');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner votre date de naissance"),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    debugPrint('[InformationsFlow] _isSaving set to true');

    try {
      debugPrint('[InformationsFlow] Calling updatePatientInformation...');
      await context.read<AuthProvider>().updatePatientInformation(
        fullName: vm.fullName,
        gender: vm.gender,
        age: vm.age!,
        height: vm.currentHeight,
        weight: vm.currentWeight,
        allergies: vm.allergies.toList(),
      );
      debugPrint('[InformationsFlow] updatePatientInformation successful');
    } catch (e) {
      debugPrint('[InformationsFlow] Profile save error: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de sauvegarde: $e')),
        );
      }
    } finally {
      if (mounted) {
        debugPrint('[InformationsFlow] Finalizing, navigating to MainScreen');
        setState(() => _isSaving = false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        debugPrint('[InformationsFlow] Not mounted after save, skipping navigation');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.darkGradient, // Premium dark background
          ),
          child: Stack(
            children: [
              // Background ambient effects
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 100,
                        spreadRadius: 20,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        blurRadius: 80,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
              ),

              // Main Content
              SafeArea(
                child: Column(
                  children: [
                    // Persistent Header with Progress
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          if (_currentPage > 0)
                            GestureDetector(
                              onTap: _goToPrev,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                              ),
                            )
                          else
                            const SizedBox(width: 40), // Spacer to keep title centered if desired
                          
                          Expanded(
                            child: Center(
                              child: Text(
                                "Étape ${_currentPage + 1}/6",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          
                          // Progress Indicator (Circular or Linear)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: (_currentPage + 1) / 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              strokeWidth: 3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Page View
                    Expanded(
                      child: Builder(builder: (ctx) {
                        return PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (page) => setState(() => _currentPage = page),
                           children: [
                            NameStep(onNext: _goToNext),
                            GenderScreen(onNextClicked: _goToNext),
                            DateOfBirthScreen(
                              onDateSelected: (_) {}, 
                              onNextClicked: _goToNext,
                              onBackClicked: _goToPrev,
                            ),
                            HeightStepScreen(onNextClicked: _goToNext),
                            WeightStepScreen(onNext: _goToNext),
                            AllergiesScreen(onNext: _finishAndSave, onBack: _goToPrev),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Loading Overlay
              if (_isSaving)
                Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          "Sauvegarde de votre profil...",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
