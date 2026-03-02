import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medaichainmobile/services/api_service.dart';
import 'package:medaichainmobile/clinique/theme/app_theme.dart';
import 'package:intl/intl.dart';

class OnlineAppointmentsView extends StatefulWidget {
  const OnlineAppointmentsView({super.key});

  @override
  State<OnlineAppointmentsView> createState() => _OnlineAppointmentsViewState();
}

class _OnlineAppointmentsViewState extends State<OnlineAppointmentsView> {
  late Future<List<dynamic>> _onlineAppointments;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _onlineAppointments = ApiService.getOnlineAppointments();
  }

  void _refresh() {
    setState(() {
      _onlineAppointments = ApiService.getOnlineAppointments();
    });
  }

  Future<void> _updateStatus(String id, String status) async {
    setState(() => _isProcessing = true);
    try {
      final success = await ApiService.updateAppointmentStatus(id, status);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'confirmed' 
                  ? 'Rendez-vous accepté !' 
                  : 'Rendez-vous refusé.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: status == 'confirmed' ? Colors.green : Colors.red,
            ),
          );
        }
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demandes de rendez-vous en ligne',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkNavy,
                  ),
                ),
                Text(
                  'Gérez les réservations provenant de l\'application mobile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.darkNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryMedical),
              tooltip: 'Actualiser',
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _onlineAppointments,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              final apps = snapshot.data ?? [];

              if (apps.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune demande en attente',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final app = apps[index];
                  final patientName = app['patientName'] ?? 'Patient Inconnu';
                  final dateStr = app['date'] ?? '';
                  final timeSlot = app['timeSlot'] ?? '';
                  final reason = app['reason'] ?? 'Aucun motif précisé';
                  final status = app['status'] ?? 'pending';
                  final id = app['_id'] ?? '';

                  DateTime? date;
                  try {
                    date = DateTime.parse(dateStr);
                  } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: _getStatusColor(status).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    date != null ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date) : dateStr,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeSlot,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Motif: $reason',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppTheme.darkNavy.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (status == 'pending') ...[
                          TextButton(
                            onPressed: _isProcessing ? null : () => _updateStatus(id, 'cancelled'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Refuser'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isProcessing ? null : () => _updateStatus(id, 'confirmed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Accepter'),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusLabel(status),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'pending': return Icons.hourglass_empty_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed': return 'Accepté';
      case 'cancelled': return 'Refusé';
      case 'pending': return 'En attente';
      default: return status;
    }
  }
}
