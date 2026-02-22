import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class DashboardHomeView extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const DashboardHomeView({super.key, this.onNavigate});

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  late Future<Map<String, dynamic>> _dashboardStats;

  @override
  void initState() {
    super.initState();
    _dashboardStats = ApiService.getDashboardStats();
  }

  void _refresh() {
    setState(() {
      _dashboardStats = ApiService.getDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardStats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryMedical));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur lors du chargement des statistiques: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {};
        final overview = stats['overview'] ?? {};
        final totalDoctors = overview['totalDoctors']?.toString() ?? '0';
        final totalAppointments = overview['totalAppointmentsToday']?.toString() ?? '0';
        final totalAdmissions = overview['totalAdmissionsToday']?.toString() ?? '0';
        final pendingAppointments = overview['pendingAppointments']?.toString() ?? '0';

        final finance = stats['finance'] ?? {};
        final rawRevenue = finance['totalRevenue'] ?? 0;
        final revenue = rawRevenue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');

        // New Analytics Data
        final analytics = stats['analytics'] ?? {};
        final recentActivities = stats['recentActivities'] ?? [];
        final totalMonthlyAppointments = analytics['appointments']?['totalMonth'] ?? 0;
        final completedMonthlyAppointments = analytics['appointments']?['completedMonth'] ?? 0;
        double completionRate = 0;
        if (totalMonthlyAppointments > 0) {
          completionRate = (completedMonthlyAppointments / totalMonthlyAppointments) * 100;
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vue d\'ensemble',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Résumé des activités de la clinique aujourd\'hui',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.sync_rounded, color: AppTheme.primaryMedical),
                    onPressed: _refresh,
                    tooltip: 'Rafraîchir les données',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // KPI Cards
            Row(
              children: [
                Expanded(child: _buildKpiCard('Admissions du jour', totalAdmissions, Icons.people_outline, AppTheme.primaryMedical)),
                const SizedBox(width: 20),
                Expanded(child: _buildKpiCard('RDV en attente', pendingAppointments, Icons.pending_actions, AppTheme.error)),
                const SizedBox(width: 20),
                Expanded(child: _buildKpiCard('RDV du jour', totalAppointments, Icons.check_circle_outline, AppTheme.accentMedical)),
                const SizedBox(width: 20),
                Expanded(child: _buildKpiCard('Médecins Actifs', totalDoctors, Icons.medical_information, AppTheme.warning)),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Actions rapides',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildActionCard('Nouvelle Admission', 'Enregistrer un patient', Icons.how_to_reg, AppTheme.primaryMedical, 2)),
                const SizedBox(width: 20),
                Expanded(child: _buildActionCard('Planifier RDV', 'Ajouter dans le calendrier', Icons.calendar_today, AppTheme.accentMedical, 3)),
                const SizedBox(width: 20),
                Expanded(child: _buildActionCard('Ajouter Médecin', 'Nouveau membre du staff', Icons.person_add, AppTheme.success, 1)),
              ],
            ),
            const SizedBox(height: 40),
            
            // Nouveau Bloc : Statistiques d'occupation & Activité
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bloc de Gauche : Taux de complétion des RDV
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Efficacité Mensuelle', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Icon(Icons.insights_rounded, color: Colors.white.withOpacity(0.8), size: 28),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Taux de RDV complétés ce mois-ci', style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${completionRate.toStringAsFixed(1)}%', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, height: 1)),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('($completedMonthlyAppointments / $totalMonthlyAppointments)', style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: completionRate / 100,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Bloc de Droite : Activité Récente List
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Activité Récente', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                            Text('Voir tout', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryMedical)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (recentActivities.isEmpty)
                           Center(
                             child: Padding(
                               padding: const EdgeInsets.symmetric(vertical: 30),
                               child: Text("Aucune activité récente.", style: TextStyle(color: Colors.grey[400])),
                             ),
                           )
                        else
                        ...List.generate(recentActivities.length > 3 ? 3 : recentActivities.length, (index) {
                          final act = recentActivities[index];
                          IconData actIcon = Icons.notifications;
                          Color actColor = Colors.grey;
                          if (act['type'] == 'appointment') { actIcon = Icons.calendar_today; actColor = AppTheme.primaryMedical; }
                          if (act['type'] == 'admission') { actIcon = Icons.transfer_within_a_station; actColor = AppTheme.warning; }
                          if (act['type'] == 'invoice') { actIcon = Icons.receipt_long; actColor = AppTheme.success; }

                          // Format time difference nicely
                          String timeText = '';
                          if (act['date'] != null) {
                            final actDate = DateTime.parse(act['date']);
                            final diff = DateTime.now().difference(actDate);
                            if (diff.inMinutes < 60) timeText = 'Il y a ${diff.inMinutes} min';
                            else if (diff.inHours < 24) timeText = 'Il y a ${diff.inHours}h';
                            else timeText = 'Il y a ${diff.inDays}j';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: actColor.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(actIcon, size: 16, color: actColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        act['title'] ?? 'Action',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.darkNavy, fontSize: 14),
                                      ),
                                      Text(
                                        act['description'] ?? '',
                                        style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(timeText, style: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Nouveau Bloc : Classement & Graphique
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bloc Gauche : Graphe des Revenus (Trend)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Revenus de la Semaine', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                        const SizedBox(height: 8),
                        Text('Évolution des encaissements (en DA)', style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 180,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBarChartColumn('Lun', 2000, 10000),
                              _buildBarChartColumn('Mar', 4500, 10000),
                              _buildBarChartColumn('Mer', 3000, 10000),
                              _buildBarChartColumn('Jeu', 8500, 10000),
                              _buildBarChartColumn('Auj.', rawRevenue.toDouble(), 10000, isToday: true),
                              _buildBarChartColumn('Sam', 0, 10000),
                              _buildBarChartColumn('Dim', 0, 10000),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Bloc Droite : Top Docteurs
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Médecins du Mois', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                            Icon(Icons.star_rounded, color: Colors.orange[400], size: 24),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildTopDoctorRow('Dr. Amine Benali', 'Cardiologie', '14 RDV', 1),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFEEEEEE))),
                        _buildTopDoctorRow('Dr. Sara Mansouri', 'Pédiatrie', '9 RDV', 2),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFEEEEEE))),
                        _buildTopDoctorRow('Dr. Karim Ziani', 'Généraliste', '5 RDV', 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }
  );
}


  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkNavy,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, int targetIndex) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        if (widget.onNavigate != null) {
          widget.onNavigate!(targetIndex);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDoctorRow(String name, String spec, String value, int rank) {
    Color rankColor = rank == 1 ? Colors.orange[400]! : (rank == 2 ? Colors.blueGrey[400]! : Colors.brown[300]!);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: rankColor.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text('#$rank', style: GoogleFonts.plusJakartaSans(color: rankColor, fontWeight: FontWeight.bold, fontSize: 13))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.darkNavy, fontSize: 14)),
              Text(spec, style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
          child: Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.primaryMedical, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildBarChartColumn(String label, double value, double maxValue, {bool isToday = false}) {
    final double percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (value > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${(value / 1000).toStringAsFixed(1)}k',
              style: GoogleFonts.plusJakartaSans(
                color: isToday ? AppTheme.darkNavy : Colors.grey[500], 
                fontSize: 10, 
                fontWeight: isToday ? FontWeight.w800 : FontWeight.bold
              ),
            ),
          ),
        Container(
          width: isToday ? 36 : 28,
          height: 120 * percentage + 4,
          decoration: BoxDecoration(
            gradient: isToday ? AppTheme.primaryGradient : null,
            color: isToday ? null : AppTheme.primaryMedical.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label, 
          style: GoogleFonts.plusJakartaSans(
            color: isToday ? AppTheme.primaryMedical : Colors.grey[600], 
            fontSize: 12, 
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600
          ),
        ),
      ],
    );
  }
}
