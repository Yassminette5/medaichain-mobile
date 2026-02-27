import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class AppointmentsCalendarView extends StatefulWidget {
  const AppointmentsCalendarView({super.key});

  @override
  State<AppointmentsCalendarView> createState() => _AppointmentsCalendarViewState();
}

class _AppointmentsCalendarViewState extends State<AppointmentsCalendarView> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  List<dynamic> _appointments = [];
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  String _viewMode = 'week'; // 'week' or 'day'

  final List<String> _timeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final appointments = await ApiService.getAppointments();
      List<dynamic> doctors = [];
      try { doctors = await ApiService.getDoctorsByClinic(); } catch (_) {}
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _doctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getAppointmentsForDate(DateTime date) {
    return _appointments.where((a) {
      if (a['date'] == null) return false;
      final d = DateTime.parse(a['date']);
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList()
      ..sort((a, b) => (a['timeSlot'] ?? '').compareTo(b['timeSlot'] ?? ''));
  }

  List<DateTime> get _weekDays {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // ======= CALENDAR HEADER =======
        _buildCalendarHeader(),
        const SizedBox(height: 16),

        // ======= MINI CALENDAR (WEEK STRIP) =======
        _buildWeekStrip(),
        const SizedBox(height: 20),

        // ======= APPOINTMENTS =======
        Expanded(
          child: _viewMode == 'week'
              ? _buildWeekView()
              : _buildDayView(),
        ),
      ],
    );
  }

  // ======= CALENDAR HEADER =======
  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryMedical, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              _formatMonthYear(_focusedMonth),
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
            ),
          ],
        ),
        Row(
          children: [
            // View toggle
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _viewToggle('Semaine', 'week'),
                  _viewToggle('Jour', 'day'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Navigation
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        _focusedMonth = _selectedDate;
                      });
                    },
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    splashRadius: 18,
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _selectedDate = DateTime.now();
                      _focusedMonth = DateTime.now();
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMedical.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Aujourd\'hui', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryMedical)),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 7));
                        _focusedMonth = _selectedDate;
                      });
                    },
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _showCreateAppointmentDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Nouveau RDV', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMedical,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _viewToggle(String label, String mode) {
    bool isActive = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryMedical : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppTheme.textSecondary),
        ),
      ),
    );
  }

  // ======= WEEK STRIP =======
  Widget _buildWeekStrip() {
    final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return Row(
      children: _weekDays.asMap().entries.map((entry) {
        final date = entry.value;
        final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
        final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
        final count = _getAppointmentsForDate(date).length;

        return Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedDate = date),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryMedical : (isToday ? AppTheme.primaryMedical.withOpacity(0.06) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryMedical : (isToday ? AppTheme.primaryMedical.withOpacity(0.2) : AppTheme.dividerLight.withOpacity(0.5)),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    dayNames[entry.key],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : (isToday ? AppTheme.primaryMedical : AppTheme.darkNavy),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (count > 0)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.primaryMedical.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppTheme.primaryMedical),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ======= WEEK VIEW =======
  Widget _buildWeekView() {
    final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dividerLight.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 60), // time column
                ...List.generate(7, (i) {
                  final date = _weekDays[i];
                  final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
                  return Expanded(
                    child: Center(
                      child: Text(
                        '${dayNames[i]} ${date.day}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isToday ? AppTheme.primaryMedical : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          // Grid
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: _timeSlots.map((time) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time label
                      SizedBox(
                        width: 60,
                        height: 50,
                        child: Center(
                          child: Text(
                            time,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      // Day cells
                      ...List.generate(7, (dayIndex) {
                        final date = _weekDays[dayIndex];
                        final dayAppts = _getAppointmentsForDate(date);
                        final matching = dayAppts.where(
                          (a) => (a['timeSlot'] ?? '').startsWith(time),
                        ).toList();
                        final appt = matching.isNotEmpty ? matching.first : null;

                        return Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: AppTheme.dividerLight.withOpacity(0.3)),
                                bottom: BorderSide(color: AppTheme.dividerLight.withOpacity(0.3)),
                              ),
                            ),
                            child: appt != null
                                ? Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: InkWell(
                                      onTap: () => _showAppointmentDetail(appt),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(appt['status']).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border(
                                            left: BorderSide(color: _getStatusColor(appt['status']), width: 3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              appt['patientName'] ?? 'Patient',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.darkNavy),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              appt['reason'] ?? '',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppTheme.textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======= DAY VIEW =======
  Widget _buildDayView() {
    final dayAppts = _getAppointmentsForDate(_selectedDate);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.dividerLight.withOpacity(0.5)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: _timeSlots.map((time) {
                  final matching = dayAppts.where(
                    (a) => (a['timeSlot'] ?? '').startsWith(time),
                  ).toList();
                  final appt = matching.isNotEmpty ? matching.first : null;

                  return Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.dividerLight.withOpacity(0.3))),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Center(
                            child: Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                          ),
                        ),
                        Container(width: 1, color: AppTheme.dividerLight.withOpacity(0.3)),
                        Expanded(
                          child: appt != null
                              ? Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: InkWell(
                                    onTap: () => _showAppointmentDetail(appt),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(appt['status']).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border(left: BorderSide(color: _getStatusColor(appt['status']), width: 3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  appt['patientName'] ?? 'Patient',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy),
                                                ),
                                                Text(
                                                  '${appt['reason'] ?? 'Consultation'} • ${appt['doctorName'] ?? ''}',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(appt['status']).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getStatusLabel(appt['status']),
                                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: _getStatusColor(appt['status'])),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Day summary sidebar
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.dividerLight.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDayName(_selectedDate),
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                ),
                Text(
                  _formatMonthYear(_selectedDate),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                _dayStat('Total RDV', dayAppts.length.toString(), AppTheme.primaryMedical),
                const SizedBox(height: 10),
                _dayStat('Confirmés', dayAppts.where((a) => a['status'] == 'confirmed').length.toString(), AppTheme.success),
                const SizedBox(height: 10),
                _dayStat('En attente', dayAppts.where((a) => a['status'] == 'pending').length.toString(), AppTheme.warning),
                const SizedBox(height: 10),
                _dayStat('Annulés', dayAppts.where((a) => a['status'] == 'cancelled').length.toString(), AppTheme.error),
                const SizedBox(height: 10),
                _dayStat('No-show', dayAppts.where((a) => a['status'] == 'no_show').length.toString(), Colors.grey),
                const Spacer(),
                // Legend
                Text('Légende', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                const SizedBox(height: 10),
                _legendItem('Confirmé', AppTheme.success),
                _legendItem('En attente', AppTheme.warning),
                _legendItem('En cours', AppTheme.primaryMedical),
                _legendItem('Terminé', const Color(0xFF6366F1)),
                _legendItem('Annulé', AppTheme.error),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(3), border: Border(left: BorderSide(color: color, width: 3)))),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ======= APPOINTMENT DETAIL =======
  void _showAppointmentDetail(dynamic appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.event_rounded, color: AppTheme.primaryMedical, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rendez-vous', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.darkNavy)),
                  Text(appt['timeSlot'] ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(appt['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_getStatusLabel(appt['status']), style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _getStatusColor(appt['status']))),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.person_rounded, 'Patient', appt['patientName'] ?? '-'),
              _detailRow(Icons.medical_services_rounded, 'Médecin', appt['doctorName'] ?? '-'),
              _detailRow(Icons.local_hospital_rounded, 'Motif', appt['reason'] ?? 'Consultation'),
              _detailRow(Icons.calendar_today_rounded, 'Date',
                  appt['date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(appt['date'])) : '-'),
              if (appt['notes'] != null && appt['notes'].isNotEmpty)
                _detailRow(Icons.note_rounded, 'Notes', appt['notes']),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          // Status change buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (appt['status'] == 'pending')
                _statusBtn('Confirmer', AppTheme.success, () async {
                  await ApiService.updateAppointment(appointmentId: appt['_id'], status: 'confirmed');
                  Navigator.pop(ctx);
                  _loadData();
                }),
              if (appt['status'] == 'confirmed')
                _statusBtn('Démarrer', AppTheme.primaryMedical, () async {
                  await ApiService.updateAppointment(appointmentId: appt['_id'], status: 'in_progress');
                  Navigator.pop(ctx);
                  _loadData();
                }),
              if (appt['status'] == 'in_progress')
                _statusBtn('Terminer', AppTheme.success, () async {
                  await ApiService.updateAppointment(appointmentId: appt['_id'], status: 'completed');
                  Navigator.pop(ctx);
                  _loadData();
                }),
              const SizedBox(width: 8),
              if (appt['status'] != 'cancelled' && appt['status'] != 'completed')
                _statusBtn('No-show', Colors.grey, () async {
                  await ApiService.updateAppointment(appointmentId: appt['_id'], status: 'no_show');
                  Navigator.pop(ctx);
                  _loadData();
                }),
            ],
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Fermer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _statusBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: AppTheme.primaryMedical),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
            ],
          ),
        ],
      ),
    );
  }

  // ======= CREATE APPOINTMENT DIALOG =======
  void _showCreateAppointmentDialog() {
    final nameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'Consultation');
    DateTime selectedDate = _selectedDate;
    String selectedTime = '09:00';
    String? selectedDoctorId;
    String? selectedDoctorName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_circle_rounded, color: AppTheme.primaryMedical, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Nouveau Rendez-vous', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.darkNavy)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: _inputDecor('Nom du patient', Icons.person_rounded),
                ),
                const SizedBox(height: 16),
                Text('Motif', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: _inputDecor('Motif de consultation', Icons.local_hospital_rounded),
                ),
                const SizedBox(height: 16),
                if (_doctors.isNotEmpty) ...[
                  Text('Médecin', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDoctorId,
                        isExpanded: true,
                        hint: Text('Choisir un médecin', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                        items: _doctors.map((d) => DropdownMenuItem(
                          value: d['_id'].toString(),
                          child: Text('${d['fullName']} (${d['speciality'] ?? ''})', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedDoctorId = val;
                            final matches = _doctors.where((d) => d['_id'].toString() == val).toList();
                            selectedDoctorName = matches.isNotEmpty ? matches.first['fullName'] : null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (picked != null) setDialogState(() => selectedDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryMedical),
                                  const SizedBox(width: 10),
                                  Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Heure', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedTime,
                                isExpanded: true,
                                items: _timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList(),
                                onChanged: (v) => setDialogState(() => selectedTime = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || selectedDoctorId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
                  );
                  return;
                }
                try {
                  await ApiService.createAppointment(
                    doctorId: selectedDoctorId!,
                    date: selectedDate.toIso8601String().split('T')[0],
                    timeSlot: '$selectedTime - ${_addMinutes(selectedTime, 30)}',
                    reason: reasonCtrl.text,
                    patientName: nameCtrl.text,
                    doctorName: selectedDoctorName,
                  );
                  Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
                }
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text('Créer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMedical,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 13),
      filled: true,
      fillColor: AppTheme.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]) + minutes;
    return '${(h + m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed': return AppTheme.success;
      case 'pending': return AppTheme.warning;
      case 'in_progress': return AppTheme.primaryMedical;
      case 'completed': return const Color(0xFF6366F1);
      case 'cancelled': return AppTheme.error;
      case 'no_show': return Colors.grey;
      default: return AppTheme.warning;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'confirmed': return 'Confirmé';
      case 'pending': return 'En attente';
      case 'in_progress': return 'En cours';
      case 'completed': return 'Terminé';
      case 'cancelled': return 'Annulé';
      case 'no_show': return 'Absent';
      default: return status ?? '-';
    }
  }

  static const _frenchMonths = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  static const _frenchDays = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
  ];

  String _formatMonthYear(DateTime date) {
    return '${_frenchMonths[date.month - 1]} ${date.year}';
  }

  String _formatDayName(DateTime date) {
    return '${_frenchDays[date.weekday - 1]} ${date.day}';
  }
}
