import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure google_fonts is added
import '../../../../models/user_info_view_model.dart';
import '../../../../core/theme/app_colors.dart';

/// ----------------------
/// Date Of Birth Screen (Step 2 of 5)
/// ----------------------
class DateOfBirthScreen extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final VoidCallback onNextClicked;
  final VoidCallback onBackClicked;

  const DateOfBirthScreen({
    super.key,
    required this.onDateSelected,
    required this.onNextClicked,
    required this.onBackClicked,
  });

  @override
  State<DateOfBirthScreen> createState() => _DateOfBirthScreenState();
}

class _DateOfBirthScreenState extends State<DateOfBirthScreen> {
  String selectedDate = "";
  DateTime _currentDate = DateTime.now().subtract(const Duration(days: 365 * 20));

  Future<void> _showDatePicker() async {
    final viewModel = Provider.of<UserInfoViewModel>(context, listen: false);
    
    // Modern Bottom Sheet Picker
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: Text("Annuler", style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.6))),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text("Confirmer", style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        _saveDate(_currentDate, viewModel);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              
              const Divider(color: Colors.white12),
              
              // Cupertino Picker
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    initialDateTime: _currentDate,
                    mode: CupertinoDatePickerMode.date,
                    maximumDate: DateTime.now(),
                    minimumDate: DateTime(1900),
                    onDateTimeChanged: (val) {
                      _currentDate = val;
                      // Optional: update live
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveDate(DateTime picked, UserInfoViewModel viewModel) {
    viewModel.setDateOfBirth(picked);

    final formatted =
        "${picked.day.toString().padLeft(2, '0')}/"
        "${picked.month.toString().padLeft(2, '0')}/"
        "${picked.year}";

    setState(() {
      selectedDate = formatted;
    });

    widget.onDateSelected(picked);
  }



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
              TextSpan(text: "Quelle est votre\n"),
              TextSpan(
                text: "Date de naissance ?",
                style: TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          "Cela nous aide à calculer votre âge pour des diagnostics précis.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 50),

        // Display Box / Trigger
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selectedDate.isNotEmpty ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_rounded, 
                  color: selectedDate.isNotEmpty ? AppColors.primary : Colors.white.withValues(alpha: 0.5),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  selectedDate.isEmpty ? "JJ/MM/AAAA" : selectedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: selectedDate.isNotEmpty ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Age Display
        if (viewModel.age != null) ...[
          Text(
            "Vous avez",
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.neonGradient.createShader(bounds),
            child: Text(
              "${viewModel.age} ans",
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],

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
                gradient: selectedDate.isNotEmpty 
                    ? AppColors.primaryGradient 
                    : LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade600]),
                shape: BoxShape.circle,
                boxShadow: selectedDate.isNotEmpty 
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: selectedDate.isNotEmpty ? widget.onNextClicked : null,
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
