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
import '../patientnesrine/subscription_screen.dart';
import '../patientnesrine/document_list_screen.dart';
import '../patient/patient_upload_analysis_screen.dart';


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
                        onTap: () => _showMedicalCardModal(context, user),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF0288D1)],
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

            // ── Plan & Abonnement ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mon Abonnement",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade600]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.colored(AppColors.primary),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan Gratuit',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gérez votre abonnement',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

  void _showMedicalCardModal(BuildContext context, User? user) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Main Card Content
            Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF0288D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 36),
                            ),

                          ],
                        ),
                        const SizedBox(height: 32),

                        // Patient Info
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Medical ID Card",
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user?.fullName?.toUpperCase() ?? "UTILISATEUR",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Text(
                                  "ID: #${(user?.id != null && user!.id.length >= 8) ? user.id.substring(user.id.length - 8).toUpperCase() : (user?.id?.toUpperCase() ?? 'UNKNOWN')}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.monitor_weight_outlined, color: Colors.white.withOpacity(0.8), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${user?.weight ?? '-'} kg",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Container(width: 1, height: 14, color: Colors.white.withOpacity(0.3)),
                                    ),
                                    Icon(Icons.height_rounded, color: Colors.white.withOpacity(0.8), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${user?.height ?? '-'} cm",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Large QR Code
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2,
                                  size: 180,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "SCAN FOR MEDICAL RECORDS",
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Additional Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "This QR code contains your medical information",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Close Button
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
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

/// Section Résultats d'analyse dans le profil patient
class _ProfileAnalysisResultsSection extends StatefulWidget {
  const _ProfileAnalysisResultsSection({required this.userId});
  final String userId;

  @override
  State<_ProfileAnalysisResultsSection> createState() => _ProfileAnalysisResultsSectionState();
}

class _ProfileAnalysisResultsSectionState extends State<_ProfileAnalysisResultsSection> {
  List<dynamic> _labResults = [];
  List<dynamic> _patientAnalyses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final futures = await Future.wait([
        ApiService.getPatientAnalysisResults(widget.userId).catchError((_) => <dynamic>[]),
        ApiService.getPatientAnalyses().catchError((_) => <dynamic>[]),
      ]);
      if (mounted) {
        setState(() {
          _labResults = futures[0] is List ? futures[0] : [];
          _patientAnalyses = futures[1] is List ? futures[1] : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _labResults = []; _patientAnalyses = []; _loading = false; });
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

  Future<void> _navigateToUpload() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PatientUploadAnalysisScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _deletePatientAnalysis(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Supprimer l'analyse ?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Cette action est irréversible.", style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.poppins(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deletePatientAnalysis(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyse supprimée'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _labResults.length + _patientAnalyses.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mon dossier",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
<<<<<<< HEAD
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentListScreen(
                    title: 'Mon dossier',
                    icon: Icons.folder_shared_rounded,
                    gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8F89FF)]),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.small,
                border: Border.all(color: AppColors.border),
=======

          // Bouton Ajouter une analyse
          GestureDetector(
            onTap: _navigateToUpload,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.colored(AppColors.primary),
>>>>>>> origin/preprod3
              ),
              child: Row(
                children: [
                  Container(
<<<<<<< HEAD
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8F89FF)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.folder_shared_rounded, color: Colors.white),
=======
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 22),
>>>>>>> origin/preprod3
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
<<<<<<< HEAD
                          'Accéder à vos documents (analyses, ordonnances, examens)',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Ouvrir le dossier",
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary),
=======
                          "Ajouter une analyse PDF",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Centre d'analyse ou personnel",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
>>>>>>> origin/preprod3
                        ),
                      ],
                    ),
                  ),
<<<<<<< HEAD
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
=======
                  Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.8)),
>>>>>>> origin/preprod3
                ],
              ),
            ),
          ),
<<<<<<< HEAD
=======
          const SizedBox(height: 16),

          if (_loading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.small,
              ),
              child: const Center(
                child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else if (totalCount == 0)
            Container(
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
                      "Aucun résultat d'analyse pour le moment.\nAppuyez ci-dessus pour en ajouter.",
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Analyses uploadées par le patient
                if (_patientAnalyses.isNotEmpty) ...[
                  _buildSubHeader('Mes analyses uploadées', Icons.upload_file_rounded, AppColors.primary),
                  const SizedBox(height: 10),
                  for (int i = 0; i < _patientAnalyses.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _buildPatientAnalysisItem(_patientAnalyses[i]),
                  ],
                ],
                if (_patientAnalyses.isNotEmpty && _labResults.isNotEmpty)
                  const SizedBox(height: 20),
                // Résultats du centre d'analyse
                if (_labResults.isNotEmpty) ...[
                  _buildSubHeader('Résultats du centre d\'analyse', Icons.biotech_rounded, AppColors.secondary),
                  const SizedBox(height: 10),
                  for (int i = 0; i < _labResults.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _buildLabResultItem(_labResults[i]),
                  ],
                ],
              ],
            ),
>>>>>>> origin/preprod3
        ],
      ),
    );
  }

  Widget _buildSubHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _buildPatientAnalysisItem(dynamic a) {
    final m = a is Map<String, dynamic> ? a : <String, dynamic>{};
    final id = m['_id']?.toString() ?? '';
    final title = m['title']?.toString() ?? 'Analyse';
    final type = m['analysisType'] ?? m['analysisTypeOther'] ?? '';
    final typeStr = type.toString().replaceAll('_', ' ');
    final source = m['source']?.toString() ?? '';
    final centreName = m['centreName']?.toString() ?? '';
    final date = m['analysisDate'];
    String dateStr = '—';
    if (date != null) {
      try { dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(date.toString())); } catch (_) {}
    }

    final resultFile = m['resultFile']?.toString() ?? '';
    final filename = resultFile.contains('/') ? resultFile.split('/').last : resultFile;
    final pdfUrl = filename.isNotEmpty ? '${ApiService.baseUrl}/uploads/patient-analyses/$filename' : null;

    final isFromCentre = source == 'centre_analyse';
    final color = isFromCentre ? AppColors.secondary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
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
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFromCentre ? Icons.business_rounded : Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                if (typeStr.isNotEmpty)
                  Text(typeStr, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
                if (centreName.isNotEmpty)
                  Text(centreName, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
                Row(
                  children: [
                    Text(dateStr, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isFromCentre ? 'Centre' : 'Personnel',
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (pdfUrl != null && pdfUrl.isNotEmpty)
            IconButton(
              onPressed: () => _openPdf(pdfUrl),
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24),
              tooltip: 'Ouvrir le PDF',
              style: IconButton.styleFrom(backgroundColor: AppColors.error.withOpacity(0.08)),
            ),
          if (id.isNotEmpty)
            IconButton(
              onPressed: () => _deletePatientAnalysis(id),
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.error.withOpacity(0.7), size: 22),
              tooltip: 'Supprimer',
            ),
        ],
      ),
    );
  }

  Widget _buildLabResultItem(dynamic a) {
    final m = a is Map<String, dynamic> ? a : <String, dynamic>{};
    final type = m['analysisType'] ?? m['analysisTypeOther'] ?? 'Analyse';
    final typeStr = type.toString().replaceAll('_', ' ').toLowerCase();
    final date = m['analysisDate'];
    String dateStr = '—';
    if (date != null) {
      try { dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(date.toString())); } catch (_) {}
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
      padding: const EdgeInsets.all(16),
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
              gradient: LinearGradient(colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 20),
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
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24),
              tooltip: 'Ouvrir le PDF',
              style: IconButton.styleFrom(backgroundColor: AppColors.error.withOpacity(0.08)),
            )
          else
            Icon(Icons.description_outlined, color: AppColors.textGrey, size: 24),
        ],
      ),
    );
  }
}