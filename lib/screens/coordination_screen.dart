import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/app_images.dart';

class CoordinationScreen extends StatelessWidget {
  const CoordinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            'Coordination & Partenaires',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkNavy,
            ),
          ),
          bottom: TabBar(
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryBlue,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Analyses & Labo"),
              Tab(text: "Pharmacie & Stock"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AnalysisTab(),
            _PharmacyTab(),
          ],
        ),
      ),
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  const _AnalysisTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAnalysisHeader(),
        const SizedBox(height: 24),
        _buildSectionTitle("Analyses Récentes"),
        const SizedBox(height: 16),
        _buildAnalysisCard(
          context,
          "Sophie Martin",
          "Analyse Sanguine Complète (NFS)",
          "Reçu",
          AppTheme.success,
          1.0,
          "https://i.pravatar.cc/150?img=5",
        ),
        _buildAnalysisCard(
          context,
          "Jean Dupont",
          "Radio Thorax",
          "En cours",
          AppTheme.warning,
          0.6,
          "https://i.pravatar.cc/150?img=13",
        ),
        _buildAnalysisCard(
          context,
          "Paul Martin",
          "Test PCR",
          "Envoyé",
          AppTheme.primaryBlue,
          0.2,
          "https://i.pravatar.cc/150?img=33",
        ),
      ],
    );
  }

  Widget _buildAnalysisHeader() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AppImages.provider(AppImages.analyse, AppImages.triageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Laboratoire Partenaire",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              "Centre d'Analyses",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18, 
        fontWeight: FontWeight.bold,
        color: AppTheme.darkNavy,
      ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context, String patientName, String testType, String status, Color color, double progress, String avatarUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName, 
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800, 
                          fontSize: 16,
                          color: AppTheme.darkNavy
                        )
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.biotech_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              testType, 
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(
                      color: color, 
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            if (status == "Reçu") ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text("Voir"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text("Télécharger PDF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _PharmacyTab extends StatelessWidget {
  const _PharmacyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPharmacyHeader(),
        const SizedBox(height: 24),
        _buildOrderCard(context, "Sophie Martin", "Ordonnance #8739", 3, [
          _Medicine("Doliprane 1000mg", true),
          _Medicine("Amoxicilline", false),
          _Medicine("Sirop Toux", true),
        ]),
        _buildOrderCard(context, "Jean Dupont", "Ordonnance #8740", 1, [
           _Medicine("Ibuprofène", true),
        ]),
      ],
    );
  }

  Widget _buildPharmacyHeader() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AppImages.provider(AppImages.pharma, AppImages.pharmaUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Partenaire Certifié",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              "Pharmacie Centrale",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, String patient, String ref, int itemsCount, List<_Medicine> medicines) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryTeal, size: 24),
          ),
          title: Text(
            ref, 
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, 
              color: AppTheme.darkNavy,
              fontSize: 16,
            )
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  patient, 
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[600], 
                    fontSize: 13, 
                    fontWeight: FontWeight.w500
                  )
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4, height: 4, 
                  decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)
                ),
                const SizedBox(width: 8),
                Text(
                  "$itemsCount articles", 
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primaryTeal, 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Divider(color: Colors.grey.withValues(alpha: 0.1)),
                  const SizedBox(height: 8),
                  ...medicines.map((m) => _buildMedicineItem(m)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                           onPressed: () {},
                           style: OutlinedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             side: BorderSide(color: Colors.grey.shade300),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             foregroundColor: Colors.grey[700],
                           ),
                           child: Text("Modifier", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text("Transmettre"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineItem(_Medicine medicine) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(medicine.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: medicine.available ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              medicine.available ? "En Stock" : "Rupture",
              style: GoogleFonts.plusJakartaSans(
                color: medicine.available ? AppTheme.success : AppTheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Medicine {
  final String name;
  final bool available;
  _Medicine(this.name, this.available);
}
