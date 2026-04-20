import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/medicines_provider.dart';
import '../../../models/medicine_model.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  String _selectedType = 'pill';
  List<String> _selectedSchedule = ['after_breakfast'];
  String _duration = '1 Month';
  String _frequency = 'Daily';
  String _description = '';
  bool _isLoadingInfo = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus && _nameController.text.isNotEmpty) {
        _fetchInfo();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchInfo() async {
    setState(() {
      _isLoadingInfo = true;
    });

    try {
      final info = await context.read<MedicinesProvider>().getMedicationInfo(_nameController.text);
      if (mounted) {
        setState(() {
          _description = info['description'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching info: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInfo = false;
        });
      }
    }
  }

  final List<Map<String, dynamic>> _types = [
    {"type": "pill", "image": "lib/assets/pill.png"},
    {"type": "syringe", "image": "lib/assets/syringes.png"},
    {"type": "eye-drops", "image": "lib/assets/eye-drops.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Reminder",
          style: GoogleFonts.poppins(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildVisualHeader(),
            const SizedBox(height: 40),
            _buildFieldLabel("Medicine Name"),
            _buildTextField(_nameController, "e.g., Panadol", focusNode: _nameFocusNode),
            if (_isLoadingInfo)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.transparent),
              ),
            if (_description.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _description,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark, fontStyle: FontStyle.italic),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _buildScheduleSelector(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildInteractiveInfoSelector("Duration", _duration, Icons.calendar_today, ["1 Month", "3 Months", "6 Months"])),
                const SizedBox(width: 16),
                Expanded(child: _buildInteractiveInfoSelector("Frequency", _frequency, Icons.access_time, ["Daily", "Weekly", "Custom"])),
              ],
            ),
            const SizedBox(height: 48),
            _buildSubmitButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualHeader() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
          Image.asset(_getImageForType(_selectedType), width: 100, height: 100, fit: BoxFit.contain),
        ],
      ),
    );
  }

  String _getImageForType(String type) {
    try {
      return _types.firstWhere((t) => t["type"] == type)["image"];
    } catch (e) {
      return "lib/assets/pill.png";
    }
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {FocusNode? focusNode}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("Type"),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _types.map((t) {
            final isSelected = t["type"] == _selectedType;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = t["type"]),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: 2),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(t["image"], fit: BoxFit.contain),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("Time & Schedule"),
        Row(
          children: [
            _buildScheduleButton("After Breakfast", "after_breakfast"),
            const SizedBox(width: 12),
            _buildScheduleButton("After Dinner", "after_dinner"),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.secondary, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleButton(String label, String value) {
    final isSelected = _selectedSchedule.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSchedule.remove(value);
          } else {
            _selectedSchedule.add(value);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4ECDC4).withOpacity(0.15) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF4ECDC4).withOpacity(0.3) : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF4ECDC4) : AppColors.textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveInfoSelector(String label, String value, IconData icon, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        GestureDetector(
          onTap: () {
            // Simple dialog or bottom sheet to pick options
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (context) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Select $label", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    ...options.map((opt) => ListTile(
                      title: Text(opt, style: GoogleFonts.poppins()),
                      onTap: () {
                        setState(() {
                          if (label == "Duration") _duration = opt;
                          if (label == "Frequency") _frequency = opt;
                        });
                        Navigator.pop(context);
                      },
                    )).toList(),
                  ],
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4ECDC4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Text(
          "Add Reminder",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) return;

    final medicine = Medicine(
      id: '',
      name: _nameController.text,
      type: _selectedType,
      dosage: '', // Removed from UI
      schedule: _selectedSchedule,
      duration: _duration,
      frequency: _frequency,
      cause: 'Général',
      capSize: '',
      description: _description,
      startDate: DateTime.now(),
      isActive: true,
    );

    final success = await context.read<MedicinesProvider>().addMedicine(medicine);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
