import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../services/admin_service.dart';
import '../../models/pharmacy_statistics.dart';
import '../../utils/pdf_export.dart';
import 'admin_login_screen.dart';
import '../auth/login_web_screen.dart';

class _ChartData {
  final String label;
  final int value;
  final Color color;
  _ChartData(this.label, this.value, this.color);
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminService();
  String _currentSection = 'dashboard';
  Map<String, dynamic>? _stats;
  List<dynamic>? _users;
  List<TopMedication> _topMedications = const [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;

  void _goToLogin() {
    if (!mounted) return;

    // Web: revenir vers l'écran de login web (demandé)
    if (kIsWeb) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginWebScreen()),
        (route) => false,
      );
      return;
    }

    // Mobile/desktop: garder le login admin dédié
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAuthAndLoad();
    });
  }

  Future<void> _ensureAuthAndLoad() async {
    final ok = await _adminService.hasToken();
    if (!ok) {
      _goToLogin();
      return;
    }

    await _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final stats = await _adminService.getStats();
    if (!mounted) return;

    // Si token absent/expiré → rediriger vers login admin
    if (stats == null) {
      await _logout();
      return;
    }

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _adminService.getUsers();
    if (!mounted) return;

    if (users == null) {
      await _logout();
      return;
    }

    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _fetchMedicationStats() async {
    setState(() => _isLoading = true);
    final monthParam = _formatMonthParam(_selectedMonth);
    final list = await _adminService.getMedicationStatistics(month: monthParam);
    if (!mounted) return;

    if (list == null) {
      await _logout();
      return;
    }

    final meds = list
        .whereType<Map<String, dynamic>>()
        .map((item) => TopMedication.fromJson(item))
        .toList();

    setState(() {
      _topMedications = meds;
      _isLoading = false;
    });
  }

  Future<void> _exportMedicationStatsPdf() async {
    if (_topMedications.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune donnée à exporter.')),
      );
      return;
    }

    try {
      final bytes = await _buildMedicationStatsPdfBytes();
      final month = _formatMonthParam(_selectedMonth);
      final filename = 'rapport_medicaments_$month.pdf';

      await savePdf(bytes, filename: filename);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rapport PDF exporté.')));
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('Save cancelled')
          ? 'Export annulé.'
          : 'Échec export PDF: $e';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<Uint8List> _buildMedicationStatsPdfBytes() async {
    final doc = pw.Document();
    final monthLabel = _formatMonthLabel(_selectedMonth);
    final generatedAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Rapport — Statistiques Médicaments',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Mois: $monthLabel'),
            pw.Text(
              'Généré le: ${generatedAt.toIso8601String().replaceFirst('T', ' ').split('.').first}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(90),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _pdfCell('#', header: true),
                    _pdfCell('Médicament', header: true),
                    _pdfCell('Demandes', header: true),
                  ],
                ),
                ..._topMedications.asMap().entries.map((entry) {
                  final index = entry.key;
                  final med = entry.value;
                  return pw.TableRow(
                    children: [
                      _pdfCell('${index + 1}'),
                      _pdfCell(med.displayName.trim()),
                      _pdfCell('${med.requestCount}'),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 11 : 10,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _formatMonthParam(DateTime month) {
    final m = month.month.toString().padLeft(2, '0');
    return '${month.year}-$m';
  }

  String _formatMonthLabel(DateTime month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: 'Choisir un mois',
    );

    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });

    await _fetchMedicationStats();
  }

  Future<void> _logout() async {
    await _adminService.logout();
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF1E293B); // Slate 800
    const subTextColor = Color(0xFF64748B); // Slate 500
    const borderColor = Color(0xFFE2E8F0); // Slate 200

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Off-white background
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MEDAIChain',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // Nav Items
                _navItem(
                  icon: Icons.dashboard,
                  label: 'Tableau de bord',
                  id: 'dashboard',
                  onTap: () {
                    setState(() => _currentSection = 'dashboard');
                    _fetchStats();
                  },
                ),
                _navItem(
                  icon: Icons.person_add,
                  label: 'Envoyer Invitation',
                  id: 'invite',
                  onTap: () {
                    setState(() => _currentSection = 'invite');
                  },
                ),
                _navItem(
                  icon: Icons.people,
                  label: 'Utilisateurs',
                  id: 'users',
                  onTap: () {
                    setState(() => _currentSection = 'users');
                    _fetchUsers();
                  },
                ),
                _navItem(
                  icon: Icons.medication,
                  label: 'Statistiques Médicaments',
                  id: 'medicationStats',
                  onTap: () {
                    setState(() => _currentSection = 'medicationStats');
                    _fetchMedicationStats();
                  },
                ),

                const Spacer(),
                const Divider(color: borderColor),
                _navItem(
                  icon: Icons.logout,
                  label: 'Déconnexion',
                  id: 'logout',
                  isDestructive: true,
                  onTap: _logout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getHeaderTitle(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getHeaderSubtitle(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content Body
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(40),
                          child: _buildContent(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required String id,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isActive = _currentSection == id;
    final activeColor = const Color(0xFF7C3AED);
    final inactiveColor = const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: activeColor, width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? const Color(0xFFEF4444)
                  : (isActive ? activeColor : inactiveColor),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isDestructive
                    ? const Color(0xFFEF4444)
                    : (isActive ? activeColor : inactiveColor),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_currentSection) {
      case 'dashboard':
        return 'Tableau de bord';
      case 'invite':
        return 'Envoyer une invitation';
      case 'users':
        return 'Liste des utilisateurs';
      case 'medicationStats':
        return 'Statistiques Médicaments';
      default:
        return '';
    }
  }

  String _getHeaderSubtitle() {
    switch (_currentSection) {
      case 'dashboard':
        return 'Aperçu global de l\'activité';
      case 'invite':
        return 'Envoyez un lien d\'inscription aux professionnels';
      case 'users':
        return 'Gérer les comptes utilisateurs';
      case 'medicationStats':
        return 'Médicaments les plus demandés (filtre par mois)';
      default:
        return '';
    }
  }

  Widget _buildContent() {
    switch (_currentSection) {
      case 'dashboard':
        return Column(
          children: [
            SizedBox(height: 140, child: _buildStatsGrid()),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Répartition des Utilisateurs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(child: _buildBarChart()),
                  ],
                ),
              ),
            ),
          ],
        );
      case 'invite':
        return const _InviteUserForm();
      case 'users':
        return _buildUsersList();
      case 'medicationStats':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top médicaments demandés',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: _pickMonth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatMonthLabel(_selectedMonth),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.expand_more,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _fetchMedicationStats,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _exportMedicationStatsPdf,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Exporter PDF',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _topMedications.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune demande sur ce mois',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _topMedications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final med = _topMedications[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.displayName.trim(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${med.requestCount} demandes',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatMonthParam(_selectedMonth),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildStatsGrid() {
    if (_stats == null) return const SizedBox();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Médecins',
            value: '${_stats!['medecin']}',
            icon: Icons.medical_services,
            color: const Color(0xFF00BFA6),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _StatCard(
            title: 'Patients',
            value: '${_stats!['patient']}',
            icon: Icons.person,
            color: const Color(0xFF64748B),
          ),
        ), // Grey icon for patient
        const SizedBox(width: 20),
        Expanded(
          child: _StatCard(
            title: 'Pharmacies',
            value: '${_stats!['pharmacie']}',
            icon: Icons.local_pharmacy,
            color: const Color(0xFFFF6B6B),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _StatCard(
            title: 'Laboratoires',
            value: '${_stats!['centre_analyse']}',
            icon: Icons.science,
            color: const Color(0xFF4D96FF),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _StatCard(
            title: 'Cliniques',
            value: '${_stats!['clinique']}',
            icon: Icons.apartment,
            color: const Color(0xFFFFD93D),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _StatCard(
            title: 'Total',
            value: '${_stats!['total']}',
            icon: Icons.groups,
            color: const Color(0xFF7C3AED),
            isTotal: true,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    if (_stats == null) return const SizedBox();

    const gradient = LinearGradient(
      colors: [Color(0xFF22D3EE), Color(0xFF7C3AED)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final data = [
      _ChartData('Médecins', _stats!['medecin'], const Color(0xFF00BFA6)),
      _ChartData('Patients', _stats!['patient'], Colors.grey),
      _ChartData('Pharmacies', _stats!['pharmacie'], const Color(0xFFFF6B6B)),
      _ChartData('Labos', _stats!['centre_analyse'], const Color(0xFF4D96FF)),
      _ChartData('Cliniques', _stats!['clinique'], const Color(0xFFFFD93D)),
    ];

    double maxY = 10;
    for (var item in data) {
      if (item.value > maxY) maxY = item.value.toDouble();
    }
    maxY += 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[group.x.toInt()].label}\n',
                GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: (rod.toY).toInt().toString(),
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      data[value.toInt()].label,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value.toDouble(),
                gradient: gradient,
                width: 24,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: const Color(
                    0xFFF1F5F9,
                  ), // Light grey background for bars
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users == null || _users!.isEmpty) {
      return const Center(
        child: Text(
          'Aucun utilisateur trouvé',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users!.length,
        separatorBuilder: (c, i) => const Divider(color: Color(0xFFE2E8F0)),
        itemBuilder: (context, index) {
          final user = _users![index];
          final role = user['role'] ?? 'Autre';

          Color badgeColor;
          switch (role) {
            case 'medecin':
              badgeColor = const Color(0xFF00BFA6);
              break;
            case 'centre_analyse':
              badgeColor = const Color(0xFF4D96FF);
              break;
            case 'pharmacie':
              badgeColor = const Color(0xFFFF6B6B);
              break;
            case 'clinique':
              badgeColor = const Color(0xFFFFD93D);
              break;
            case 'admin':
              badgeColor = const Color(0xFF7C3AED);
              break;
            default:
              badgeColor = Colors.grey;
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: badgeColor.withOpacity(0.1),
              child: Text(
                (user['email'] as String)[0].toUpperCase(),
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user['email'],
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Rôle: ${role.toString().toUpperCase()}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user['isProfileCompleted']
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user['isProfileCompleted'] ? 'Actif' : 'En attente',
                style: TextStyle(
                  color: user['isProfileCompleted']
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isTotal;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
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
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1E293B),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteUserForm extends StatefulWidget {
  const _InviteUserForm();

  @override
  State<_InviteUserForm> createState() => _InviteUserFormState();
}

class _InviteUserFormState extends State<_InviteUserForm> {
  final _emailController = TextEditingController();
  String _selectedRole = 'medecin';
  final _adminService = AdminService();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  Future<void> _submit() async {
    if (_emailController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final error = await _adminService.inviteUser(
      _emailController.text,
      _selectedRole,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (error == null) {
          _message =
              'Invitation envoyée avec succès à ${_emailController.text}';
          _isError = false;
          _emailController.clear();
        } else {
          _message = error;
          _isError = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélection du rôle',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _roleItem('medecin', 'Médecin', Icons.medical_services),
              _roleItem('centre_analyse', 'Laboratoire', Icons.science),
              _roleItem('pharmacie', 'Pharmacie', Icons.local_pharmacy),
              _roleItem('clinique', 'Clinique', Icons.apartment),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'Destinataire',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              labelText: 'Adresse Email',
              labelStyle: const TextStyle(color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFFF1F5F9), // Light grey input
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF7C3AED)),
              ),
              prefixIcon: const Icon(Icons.email, color: Color(0xFF64748B)),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _isError
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isError
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: _isError
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _isError
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isLoading ? 'Envoi en cours...' : 'Envoyer l\'invitation',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleItem(String value, String label, IconData icon) {
    final isSelected = _selectedRole == value;
    final activeColor = const Color(0xFF7C3AED);

    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : const Color(0xFFF1F5F9), // Light grey inactive
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
