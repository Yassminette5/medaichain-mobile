import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/appointment_detail_content.dart';

class LabAppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic>? notificationData;

  const LabAppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.notificationData,
  });

  @override
  State<LabAppointmentDetailScreen> createState() => _LabAppointmentDetailScreenState();
}

class _LabAppointmentDetailScreenState extends State<LabAppointmentDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _appointment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final appt = await ApiService.getLabAppointmentById(widget.appointmentId);
      if (!mounted) return;
      setState(() {
        _appointment = appt;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleCentre = widget.notificationData?['centreName']?.toString().trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleCentre?.isNotEmpty == true ? 'RDV - $titleCentre' : 'Détails du RDV',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        const Text(
                          'Erreur de chargement',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!.replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AppointmentDetailContent(appointment: _appointment ?? const {}),
                ),
    );
  }
}

