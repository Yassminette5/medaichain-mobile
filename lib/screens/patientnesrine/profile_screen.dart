import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../patientnesrine/edit_profile_screen.dart';
import '../patientnesrine/patient_qr_screen.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header with Gradient
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.user;
                return Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: AppColors.colored(AppColors.primary),
                  ),
                  child: Column(
                    children: [
                      // Edit Button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Profile Avatar with Gradient Border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.accentGradient,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 46,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.fullName ?? "Utilisateur",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "ID: #${(user?.id != null && user!.id.length >= 8) ? user.id.substring(user.id.length - 8).toUpperCase() : (user?.id?.toUpperCase() ?? 'UNKNOWN')}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Medical NFT Card with Enhanced Design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Medical Card",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final user = auth.user;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PatientQrScreen()),
                        ),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF8F89FF), Color(0xFFB4A5FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: AppColors.colored(AppColors.primary),
                          ),
                          child: Stack(
                            children: [
                              // Decorative Elements
                              Positioned(
                                top: -40,
                                right: -40,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -50,
                                left: -50,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 28),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.verified, color: Colors.white, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                "NFT Verified",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user?.fullName ?? "Utilisateur",
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "Age: ${user?.age ?? '-'} | ${user?.gender ?? '-'}",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.qr_code_2, size: 50, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Résultats d'analyse (centre d'analyse)
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final userId = auth.user?.id;
                if (userId == null || userId.isEmpty) return const SizedBox.shrink();
                return _ProfileAnalysisResultsSection(userId: userId);
              },
            ),
            const SizedBox(height: 32),

            // Access Control with Glassmorphic Design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Access Control",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAccessTile("Allow Emergency Access", true, Icons.emergency),
                  _buildAccessTile("Share Record with Dr. Smith", true, Icons.share),
                  _buildAccessTile("Temporary Access (24h)", false, Icons.access_time),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.small,
                  border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
                ),
                child: InkWell(
                  onTap: () async {
                    // Confirm logout
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Déconnexion", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        content: Text("Êtes-vous sûr de vouloir vous déconnecter ?", style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text("Annuler", style: GoogleFonts.poppins(color: AppColors.textGrey)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text("Déconnexion", style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await Provider.of<AuthProvider>(context, listen: false).logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        "Se déconnecter",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }


  Widget _buildAccessTile(String title, bool isActive, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.small,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.primaryGradient : null,
              color: isActive ? null : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textGrey,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isActive,
              activeColor: AppColors.primary,
              onChanged: (val) {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Résultats d'analyse dans My Medical Card (profil patient)
class _ProfileAnalysisResultsSection extends StatefulWidget {
  const _ProfileAnalysisResultsSection({required this.userId});
  final String userId;

  @override
  State<_ProfileAnalysisResultsSection> createState() => _ProfileAnalysisResultsSectionState();
}

class _ProfileAnalysisResultsSectionState extends State<_ProfileAnalysisResultsSection> {
  List<dynamic> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getPatientAnalysisResults(widget.userId);
      if (mounted) setState(() { _results = list is List ? list : []; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _results = []; _loading = false; });
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted && !ok) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le PDF')));
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Résultats d'analyse",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _loading
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.small,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : _results.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.small,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.science_rounded, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              "Aucun résultat d'analyse pour le moment.",
                              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < _results.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _buildResultItem(_results[i]),
                        ],
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildResultItem(dynamic a) {
    final m = a is Map<String, dynamic> ? a : <String, dynamic>{};
    final type = m['analysisType'] ?? m['analysisTypeOther'] ?? 'Analyse';
    final typeStr = type.toString().replaceAll('_', ' ').toLowerCase();
    final date = m['analysisDate'];
    String dateStr = '—';
    if (date != null) {
      try {
        dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(date.toString()));
      } catch (_) {}
    }
    final lab = m['labId'];
    String labName = '';
    if (lab is Map<String, dynamic>) {
      labName = lab['centreName'] ?? lab['name'] ?? '';
    }
    final resultFile = m['resultFile']?.toString() ?? '';
    final filename = resultFile.contains('/') ? resultFile.split('/').last : resultFile;
    final pdfUrl = filename.isNotEmpty ? '${ApiService.baseUrl}/lab/uploads/results/$filename' : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.small,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.biotech_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeStr.isNotEmpty ? typeStr : 'Résultat',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                if (labName.isNotEmpty)
                  Text(labName, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
                Text(dateStr, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          if (pdfUrl != null && pdfUrl.isNotEmpty)
            IconButton(
              onPressed: () => _openPdf(pdfUrl),
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 28),
              tooltip: 'Ouvrir le PDF',
              style: IconButton.styleFrom(backgroundColor: AppColors.error.withOpacity(0.1)),
            )
          else
            Icon(Icons.description_outlined, color: AppColors.textGrey, size: 24),
        ],
      ),
    );
  }
}