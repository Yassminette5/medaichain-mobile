import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medaichainmobile/core/theme/app_colors.dart';
import 'package:medaichainmobile/providers/auth_provider.dart';
import 'package:medaichainmobile/providers/calendar_provider.dart';
import 'package:medaichainmobile/providers/patients_provider.dart';
import 'package:medaichainmobile/models/calendar_event_model.dart';
import 'package:medaichainmobile/screens/patients/patient_access_request_screen.dart';
import 'package:medaichainmobile/screens/patients/patient_medical_record_screen.dart';
import 'package:medaichainmobile/screens/ai/ai_decision_support_screen.dart';
import 'package:medaichainmobile/medecin/screens/profile/doctor_profile_screen.dart';
import 'package:medaichainmobile/medecin/screens/agenda/agenda_screen.dart';
import 'package:medaichainmobile/screens/patientnesrine/notifications_screen.dart';
import 'package:medaichainmobile/screens/consultations/new_consultation_screen.dart';
import 'package:medaichainmobile/screens/consultations/all_consultations_screen.dart';
import 'package:medaichainmobile/screens/video_call/video_call_screen.dart';
import 'package:medaichainmobile/services/api_service.dart';

/// Tableau de Bord Moderne avec Navigation
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _pages = [
    const _HomeView(),
    const _PatientsView(),
    const AgendaScreen(),
    const AiDecisionSupportScreen(),
    const DoctorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Accueil'),
              _buildNavItem(1, Icons.people_rounded, 'Patients'),
              _buildNavItem(2, Icons.calendar_month_rounded, 'Agenda'),
              _buildNavItem(3, Icons.auto_awesome, 'IA'),
              _buildNavItem(4, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textLight, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  List<Map<String, dynamic>> _accessRequests = [];

  @override
  void initState() {
    super.initState();
    _loadAccessRequests();
    // Rafraîchir les consultations depuis le backend à l'affichage du tableau de bord
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      calendarProvider.refresh();
    });
  }

  Future<void> _loadAccessRequests() async {
    try {
      final list = await ApiService.getAccessRequestsForDoctor();
      if (mounted) setState(() => _accessRequests = list);
    } catch (_) {
      if (mounted) setState(() => _accessRequests = []);
    }
  }

  Future<void> _refreshFromBackend() async {
    await Future.wait([
      _loadAccessRequests(),
      Provider.of<CalendarProvider>(context, listen: false).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.background],
          stops: const [0, 0.3],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshFromBackend,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 28),
                _buildNotificationsSection(context),
                const SizedBox(height: 28),
                _buildUpcomingEvents(context),
                const SizedBox(height: 28),
                _buildStatsGrid(context),
                const SizedBox(height: 28),
                _buildQuickActions(context),
                const SizedBox(height: 28),
                _buildPendingRequests(context),
                const SizedBox(height: 28),
                _buildTodayConsultations(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final doctorProfile = authProvider.doctorProfile;
    final doctorName = doctorProfile?.displayName ?? 'Dr. Docteur';
    final initials = doctorProfile?.initials ?? 'DR';
    final todayEvents = calendarProvider.getEventsForDay(DateTime.now());
    final eventCount = todayEvents.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                  'Bonjour 👋',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctorName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Navigate to Notifications screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
                  if (eventCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$eventCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final alertEvents = calendarProvider.eventsWithAlerts;

    if (alertEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show max 4 alerts
    final displayAlerts = alertEvents.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${alertEvents.length} alerte${alertEvents.length > 1 ? 's' : ''} active${alertEvents.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${alertEvents.length}',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayAlerts.map((event) => _buildNotificationItem(context, event)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, CalendarEvent event) {
    final now = DateTime.now();
    final diff = event.dateTime.difference(now);
    String timeLabel;
    if (diff.inDays > 0) {
      timeLabel = 'Dans ${diff.inDays}j';
    } else if (diff.inHours > 0) {
      timeLabel = 'Dans ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      timeLabel = 'Dans ${diff.inMinutes}min';
    } else {
      timeLabel = 'Maintenant';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: event.type.lightColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: event.type.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.alarm_rounded, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: event.type.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.type.displayName,
                        style: TextStyle(
                          color: event.type.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.notifications_outlined, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      event.alertBefore.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [event.type.color, event.type.color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              timeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final allUpcoming = calendarProvider.upcomingEvents;

    if (allUpcoming.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show max 3
    final displayEvents = allUpcoming.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Prochains rendez-vous',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllConsultationsScreen(),
                    ),
                  );
                },
                child: Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayEvents.map((event) => _buildEventCard(context, event)),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    final isToday = event.dateTime.year == DateTime.now().year &&
        event.dateTime.month == DateTime.now().month &&
        event.dateTime.day == DateTime.now().day;
    final timeStr = DateFormat('HH:mm').format(event.dateTime);
    final dateStr = isToday ? "Aujourd'hui" : DateFormat('EEE d MMM', 'fr_FR').format(event.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: event.type.lightColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: event.type.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: event.type.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(event.type.icon, color: Colors.white, size: 16),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      event.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: event.type.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $dateStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (event.patientName != null && event.patientName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          event.patientName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (event.alertBefore != AlertOption.none)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.alarm_rounded, color: Colors.orange, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aujourd\'hui',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  '24',
                  'Patients du jour',
                  Icons.people_alt_rounded,
                  AppColors.primary,
                  AppColors.primaryGradient,
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernStatCard(
                  '8',
                  'En attente',
                  Icons.pending_actions_rounded,
                  AppColors.warning,
                  LinearGradient(
                    colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
                  ),
                  false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  '3',
                  'Alertes critiques',
                  Icons.warning_rounded,
                  AppColors.error,
                  LinearGradient(
                    colors: [AppColors.error, AppColors.error.withValues(alpha: 0.7)],
                  ),
                  false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernStatCard(
                  '12',
                  'Suggestions IA',
                  Icons.auto_awesome,
                  AppColors.ai,
                  AppColors.aiGradient,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(String value, String label, IconData icon, Color color, Gradient gradient, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isHighlighted ? gradient : null,
        color: isHighlighted ? null : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted ? null : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted ? Colors.white : color,
                  size: 20,
                ),
              ),
              if (isHighlighted)
                Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isHighlighted ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isHighlighted ? Colors.white.withValues(alpha: 0.9) : color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildModernActionButton(
                context,
                Icons.add_circle_outline,
                'Nouvelle\nConsult.',
                AppColors.primary,
                AppColors.primaryGradient,
              ),
              const SizedBox(width: 12),
              _buildModernActionButton(
                context,
                Icons.auto_awesome,
                'Aide\nIA',
                AppColors.secondary,
                AppColors.aiGradient,
              ),
              const SizedBox(width: 12),
              _buildModernActionButton(
                context,
                Icons.video_call_outlined,
                'Appel\nVidéo',
                AppColors.diagnosis,
                LinearGradient(colors: [AppColors.diagnosis, AppColors.diagnosis.withValues(alpha: 0.7)]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(BuildContext context, IconData icon, String label, Color color, Gradient gradient) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (label.contains('Consult')) {
            _showAddConsultationDialog(context);
          } else if (label.contains('IA')) {
            final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
            dashboardState?.navigateToTab(3);
          } else if (label.contains('Planifier')) {
            final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
            dashboardState?.navigateToTab(2);
          } else if (label.contains('Vidéo') || label.contains('Appel')) {
            _showVideoCallPatientPicker(context);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddConsultationDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewConsultationScreen(),
      ),
    );
  }

  void _showVideoCallPatientPicker(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final patientsProvider = Provider.of<PatientsProvider>(context, listen: false);
    final doctorId = authProvider.user?.id;
    if (doctorId == null || doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée. Reconnectez-vous.')),
      );
      return;
    }
    final patients = patientsProvider.patients;
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun patient avec accès partagé. Acceptez des demandes dans l\'onglet "Demandes d\'accès" (Voir tout).'),
          duration: Duration(seconds: 4),
        ),
      );
      patientsProvider.loadPatients();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choisir un patient pour l\'appel vidéo',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: patients.length,
                itemBuilder: (ctx, index) {
                  final patient = patients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        (patient.fullName).split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(patient.fullName),
                    subtitle: Text(patient.phone ?? patient.email ?? ''),
                    onTap: () {
                      Navigator.pop(ctx);
                      final patientUserId = patient.userId ?? patient.id;
                      final channel = ApiService.videoCallChannelName(doctorId, patientUserId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoCallScreen(
                            channelName: channel,
                            remoteUserName: patient.fullName,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequests(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.key_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Demandes d'accès",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAccessRequestScreen()));
                  _loadAccessRequests();
                },
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_accessRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Aucune demande en attente',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            )
          else
            ..._accessRequests.take(3).map((req) {
              final patient = req['patientId'] is Map ? req['patientId'] as Map<String, dynamic> : null;
              final name = patient?['fullName'] ?? 'Patient';
              final reason = req['reason']?.toString() ?? 'Demande d\'accès';
              final urgency = (req['urgency']?.toString() ?? 'normal').toLowerCase();
              final priorityColor = urgency == 'urgent' ? AppColors.error : urgency == 'low' ? AppColors.success : AppColors.warning;
              final priorityLabel = urgency == 'urgent' ? 'URGENT' : urgency == 'low' ? 'BASSE' : 'NORMALE';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildModernRequestItem(name, reason, priorityColor, priorityLabel),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildModernRequestItem(String name, String type, Color priorityColor, String priority) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [priorityColor.withValues(alpha: 0.1), priorityColor.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [priorityColor, priorityColor.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: priorityColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [priorityColor, priorityColor.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: priorityColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              priority,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayConsultations(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final todayEvents = calendarProvider.getEventsForDay(DateTime.now());
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Consultations du jour",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (todayEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Aucune consultation aujourd\'hui',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            )
          else
            ...List.generate(todayEvents.length, (index) {
              final event = todayEvents[index];
              final timeStr = DateFormat('HH:mm').format(event.dateTime);
              final name = event.patientName ?? event.title;
              final typeLabel = event.title;
              final color = event.type.color;
              final isNow = event.dateTime.isBefore(now.add(const Duration(hours: 1))) &&
                  event.dateTime.isAfter(now.subtract(const Duration(minutes: 30)));
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildModernConsultationItem(context, name, timeStr, typeLabel, color, isNow, patientId: event.patientId),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildModernConsultationItem(BuildContext context, String name, String time, String type, Color color, bool isNow, {String? patientId}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientMedicalRecordScreen(patientId: patientId, patientName: name))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isNow
              ? LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)])
              : LinearGradient(colors: [AppColors.background, AppColors.surface]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNow ? color.withValues(alpha: 0.3) : AppColors.textLight.withValues(alpha: 0.1),
          ),
          boxShadow: isNow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isNow
                    ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                    : null,
                color: isNow ? null : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: isNow ? null : Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time.split(':')[0],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isNow ? Colors.white : color,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    time.split(':')[1],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isNow ? Colors.white.withValues(alpha: 0.9) : color.withValues(alpha: 0.8),
                      fontSize: 12,
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
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isNow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'EN COURS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _PatientsView extends StatefulWidget {
  const _PatientsView();

  @override
  State<_PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<_PatientsView> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _acceptedList = [];
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> get _acceptedPatients {
    final byId = <String, Map<String, dynamic>>{};
    for (final r in _acceptedList) {
      final p = r['patientId'];
      if (p is Map<String, dynamic>) {
        final id = p['_id']?.toString();
        if (id != null && id.isNotEmpty) byId[id] = p;
      }
    }
    return byId.values.toList();
  }

  List<Map<String, dynamic>> get _filteredPatients {
    final list = _acceptedPatients;
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((p) {
      final name = (p['fullName'] ?? p['email'] ?? '').toString().toLowerCase();
      final email = (p['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _loadAccepted() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAcceptedPatientsForDoctor();
      if (mounted) setState(() { _acceptedList = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccepted());
  }

  @override
  Widget build(BuildContext context) {
    final patients = _filteredPatients;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Patients', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAccepted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Patients ayant partagé l\'accès à leur dossier',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 15)],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un patient...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textLight),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAccepted,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            else if (patients.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: AppColors.textLight),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Aucun patient n\'a partagé l\'accès.\nAcceptez des demandes dans "Demandes d\'accès".'
                            : 'Aucun résultat',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final p = patients[index];
                    final id = p['_id']?.toString() ?? '';
                    final name = p['fullName']?.toString() ?? p['email']?.toString() ?? 'Patient';
                    return _buildPatientCard(
                      context,
                      name,
                      'Accès partagé',
                      _getColorForIndex(index),
                      patientId: id,
                      patientName: name,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppColors.warning,
      AppColors.error,
      AppColors.success,
      AppColors.prescription,
      AppColors.primary,
      AppColors.secondary,
    ];
    return colors[index % colors.length];
  }

  Widget _buildPatientCard(BuildContext context, String name, String condition, Color color, {String? patientId, String? patientName}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientMedicalRecordScreen(patientId: patientId, patientName: patientName ?? name))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 15)],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(condition, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_right, color: color),
            ),
          ],
        ),
      ),
    );
  }
}


