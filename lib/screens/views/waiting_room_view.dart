import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class WaitingRoomView extends StatefulWidget {
  const WaitingRoomView({super.key});

  @override
  State<WaitingRoomView> createState() => _WaitingRoomViewState();
}

class _WaitingRoomViewState extends State<WaitingRoomView> {
  List<dynamic> _admissions = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadAdmissions();
    // Auto-refresh every 30 seconds for real-time feel
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAdmissions());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAdmissions() async {
    try {
      final admissions = await ApiService.getAdmissions();
      if (mounted) {
        setState(() {
          _admissions = admissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredAdmissions {
    if (_filterStatus == 'all') return _admissions;
    return _admissions.where((a) => a['status'] == _filterStatus).toList();
  }

  int _countByStatus(String status) {
    return _admissions.where((a) => a['status'] == status).length;
  }

  String _getWaitTime(dynamic admission) {
    if (admission['createdAt'] != null) {
      final created = DateTime.parse(admission['createdAt']);
      final diff = DateTime.now().difference(created);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      return '${diff.inHours}h ${diff.inMinutes % 60}min';
    }
    return '-';
  }

  Future<void> _updateStatus(String admissionId, String newStatus) async {
    try {
      await ApiService.updateAdmission(admissionId: admissionId, status: newStatus);
      _loadAdmissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Statut mis à jour', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // ======= STATUS SUMMARY CARDS =======
        Row(
          children: [
            Expanded(child: _buildStatusSummary(
              'En attente',
              _countByStatus('waiting'),
              Icons.hourglass_top_rounded,
              AppTheme.warning,
              'waiting',
            )),
            const SizedBox(width: 14),
            Expanded(child: _buildStatusSummary(
              'En consultation',
              _countByStatus('in_consultation'),
              Icons.medical_services_rounded,
              AppTheme.primaryMedical,
              'in_consultation',
            )),
            const SizedBox(width: 14),
            Expanded(child: _buildStatusSummary(
              'Terminé',
              _countByStatus('completed'),
              Icons.check_circle_rounded,
              AppTheme.success,
              'completed',
            )),
            const SizedBox(width: 14),
            Expanded(child: _buildStatusSummary(
              'Total du jour',
              _admissions.length,
              Icons.groups_rounded,
              AppTheme.indigo,
              'all',
            )),
          ],
        ),
        const SizedBox(height: 24),

        // ======= FILTER + ACTIONS BAR =======
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMedical.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_seat_rounded, color: AppTheme.primaryMedical, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Salle d\'attente',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMedical.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Auto-refresh 30s',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.primaryMedical, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _loadAdmissions,
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryMedical),
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ======= PATIENT LIST =======
        Expanded(
          child: _filteredAdmissions.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredAdmissions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _buildPatientCard(_filteredAdmissions[index], index),
                ),
        ),
      ],
    );
  }

  // ======= STATUS SUMMARY CARD =======
  Widget _buildStatusSummary(String label, int count, IconData icon, Color color, String status) {
    bool isActive = _filterStatus == status;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _filterStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? color.withOpacity(0.3) : AppTheme.dividerLight.withOpacity(0.5)),
          boxShadow: isActive
              ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: count.toDouble()),
                    duration: const Duration(milliseconds: 800),
                    builder: (_, val, __) => Text(
                      val.toInt().toString(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                    ),
                  ),
                  Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======= PATIENT CARD =======
  Widget _buildPatientCard(dynamic admission, int index) {
    final status = admission['status'] ?? 'waiting';
    final statusInfo = _getStatusInfo(status);
    final queueNumber = admission['queueNumber'] ?? (index + 1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusInfo['color'].withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Queue Number
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusInfo['color'], statusInfo['color'].withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: statusInfo['color'].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: Text(
                '#$queueNumber',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admission['patientName'] ?? 'Patient',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.darkNavy, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_hospital_rounded, size: 13, color: AppTheme.textSecondary.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        admission['reason'] ?? 'Consultation',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (admission['patientPhone'] != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.phone_rounded, size: 13, color: AppTheme.textSecondary.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        admission['patientPhone'],
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Wait Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  _getWaitTime(admission),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkNavy),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusInfo['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusInfo['color'].withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == 'in_consultation')
                  _buildPulse(statusInfo['color']),
                Text(
                  statusInfo['label'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusInfo['color'],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action Buttons
          PopupMenuButton<String>(
            onSelected: (val) => _updateStatus(admission['_id'], val),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.more_vert_rounded, color: AppTheme.darkNavy, size: 18),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => [
              if (status == 'waiting')
                _buildMenuItem('in_consultation', 'Passer en consultation', Icons.medical_services_rounded, AppTheme.primaryMedical),
              if (status == 'in_consultation')
                _buildMenuItem('completed', 'Marquer terminé', Icons.check_circle_rounded, AppTheme.success),
              if (status != 'cancelled')
                _buildMenuItem('cancelled', 'Annuler', Icons.cancel_rounded, AppTheme.error),
              if (status == 'completed' || status == 'cancelled')
                _buildMenuItem('waiting', 'Remettre en attente', Icons.replay_rounded, AppTheme.warning),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
        ],
      ),
    );
  }

  Widget _buildPulse(Color color) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'waiting':
        return {'label': 'En attente', 'color': AppTheme.warning};
      case 'in_consultation':
        return {'label': 'En consultation', 'color': AppTheme.primaryMedical};
      case 'completed':
        return {'label': 'Terminé', 'color': AppTheme.success};
      case 'cancelled':
        return {'label': 'Annulé', 'color': AppTheme.error};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryMedical.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_seat_rounded, size: 48, color: AppTheme.primaryMedical.withOpacity(0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            'Salle d\'attente vide',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.darkNavy),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun patient en attente pour le moment',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
