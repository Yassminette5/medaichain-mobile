import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

class OpeningHoursScreen extends StatefulWidget {
  const OpeningHoursScreen({super.key});

  @override
  State<OpeningHoursScreen> createState() => _OpeningHoursScreenState();
}

class _OpeningHoursScreenState extends State<OpeningHoursScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  final Map<String, dynamic> _openingHours = {
    'lundi': {'open': '08:00', 'close': '18:00', 'isOpen': true},
    'mardi': {'open': '08:00', 'close': '18:00', 'isOpen': true},
    'mercredi': {'open': '08:00', 'close': '18:00', 'isOpen': true},
    'jeudi': {'open': '08:00', 'close': '18:00', 'isOpen': true},
    'vendredi': {'open': '08:00', 'close': '18:00', 'isOpen': true},
    'samedi': {'open': '09:00', 'close': '13:00', 'isOpen': true},
    'dimanche': {'open': '', 'close': '', 'isOpen': false},
  };

  final List<String> _days = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
  ];

  final Map<String, String> _dayLabels = {
    'lundi': 'Lundi',
    'mardi': 'Mardi',
    'mercredi': 'Mercredi',
    'jeudi': 'Jeudi',
    'vendredi': 'Vendredi',
    'samedi': 'Samedi',
    'dimanche': 'Dimanche',
  };

  @override
  void initState() {
    super.initState();
    _loadOpeningHours();
  }

  Future<void> _loadOpeningHours() async {
    try {
      final profile = await ApiService.getLabProfile();
      if (profile['openingHours'] != null) {
        setState(() {
          // Merge with defaults to ensure all days are present
          final hours = profile['openingHours'] as Map<String, dynamic>;
          hours.forEach((key, value) {
            if (_openingHours.containsKey(key)) {
              _openingHours[key] = Map<String, dynamic>.from(value);
            }
          });
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des horaires');
    }
  }

  Future<void> _saveOpeningHours() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.updateLabProfile({'openingHours': _openingHours});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horaires mis à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Erreur lors de la sauvegarde');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _selectTime(String day, bool isOpenTime) async {
    final currentStr = _openingHours[day][isOpenTime ? 'open' : 'close'] as String;
    TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 0);

    if (currentStr.isNotEmpty) {
      final parts = currentStr.split(':');
      if (parts.length == 2) {
        initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _openingHours[day][isOpenTime ? 'open' : 'close'] = formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Horaires d\'ouverture',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      final day = _days[index];
                      final hours = _openingHours[day];
                      final bool isOpen = hours['isOpen'] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  _dayLabels[day]!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Switch.adaptive(
                                  value: isOpen,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      _openingHours[day]['isOpen'] = val;
                                      if (val && hours['open'].isEmpty) {
                                        _openingHours[day]['open'] = '08:00';
                                        _openingHours[day]['close'] = '18:00';
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (isOpen) ...[
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTimeSelector(
                                      label: 'Ouverture',
                                      time: hours['open'],
                                      onTap: () => _selectTime(day, true),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTimeSelector(
                                      label: 'Fermeture',
                                      time: hours['close'],
                                      onTap: () => _selectTime(day, false),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildSaveButton(),
              ],
            ),
    );
  }

  Widget _buildTimeSelector({required String label, required String time, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.isEmpty ? '--:--' : time,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveOpeningHours,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Enregistrer les horaires',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
