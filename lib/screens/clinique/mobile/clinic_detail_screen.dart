import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/api_service.dart';
import 'clinic_appointment_booking_screen.dart';

/// Écran de détails d'une clinique pour les patients
class ClinicDetailScreen extends StatefulWidget {
  final String clinicId;

  const ClinicDetailScreen({
    super.key,
    required this.clinicId,
  });

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  Map<String, dynamic>? _clinicData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClinicDetails();
  }

  Future<void> _loadClinicDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clinicData = await ApiService.getClinicById(widget.clinicId);
      if (mounted) {
        setState(() {
          _clinicData = clinicData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Détails de la Clinique',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Erreur de chargement',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadClinicDetails,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _clinicData == null
                  ? const Center(
                      child: Text('Aucune donnée disponible'),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(),
                          const SizedBox(height: 20),
                          _buildInfoSection(),
                          const SizedBox(height: 20),
                          _buildOnlineBookingStatus(),
                          const SizedBox(height: 30),
                          _buildAppointmentButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeaderCard() {
    final clinicName = _clinicData!['name'] ?? 'Clinique';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: AppColors.primary,
                  size: 50,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinicName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_clinicData!['address'] != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _clinicData!['address'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineBookingStatus() {
    final isActive = _clinicData!['isActive'] == true;
    final canBook = isActive;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: canBook 
            ? AppColors.successLight 
            : AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canBook 
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            canBook ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: canBook ? AppColors.success : AppColors.warning,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canBook 
                      ? 'Réservation en ligne disponible'
                      : 'Réservation en ligne non disponible',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: canBook ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  canBook
                      ? 'Vous pouvez prendre rendez-vous en ligne'
                      : 'Cette clinique ne prend pas de rendez-vous en ligne. Vous pouvez la contacter directement.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          if (_clinicData!['address'] != null)
            _buildInfoRow(
              Icons.location_on_rounded,
              'Localisation',
              _clinicData!['address'] ?? '',
              AppColors.success,
            ),
          if (_clinicData!['email'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.email_rounded,
              'Email',
              _clinicData!['email'] ?? '',
              AppColors.diagnosis,
            ),
          ],
          if (_clinicData!['phoneNumber'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.phone_rounded,
              'Téléphone',
              _clinicData!['phoneNumber'] ?? '',
              AppColors.prescription,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentButton() {
    final isActive = _clinicData!['isActive'] == true;
    final canBook = isActive;

    if (canBook) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClinicAppointmentBookingScreen(
                clinicId: widget.clinicId,
                clinicName: _clinicData!['name'] ?? 'Clinique',
              ),
            ),
          );
        },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 12),
              Text(
                'Prendre un rendez-vous',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
