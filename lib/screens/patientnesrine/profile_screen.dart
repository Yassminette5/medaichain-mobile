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
import '../patientnesrine/document_list_screen.dart';
import '../patient/patient_upload_analysis_screen.dart';
import '../patientnesrine/ocr_analyze_screen.dart';
import '../patientnesrine/ocr_document_detail_screen.dart';
import '../../widgets/ai_assistant_chat.dart';


import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isExporting = false;
  bool _temporaryAccessEnabled = false;
  DateTime? _temporaryAccessUntil;
  bool _isUpdatingTemporaryAccess = false;
  bool _accessStateInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_accessStateInitialized) return;
    final user = context.read<AuthProvider>().user;
    if (user?.role == UserRole.patient) {
      _temporaryAccessEnabled = user?.temporaryAccessEnabled ?? false;
      _temporaryAccessUntil = user?.temporaryAccessUntil;
      _accessStateInitialized = true;
    }
  }

  Future<void> _exportMedicalRecord(BuildContext context) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final response = await ApiService.exportOcrPdf();
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/medical_record.pdf');
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dossier médical exporté avec succès !'), backgroundColor: AppColors.success),
          );
          await OpenFilex.open(file.path);
        }
      } else {
        throw Exception('Erreur lors de la génération du PDF');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

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
                          "ID: #${(user?.id != null && user!.id.length >= 8) ? user.id.substring(user.id.length - 8).toUpperCase() : (user?.id.toUpperCase() ?? 'UNKNOWN')}",
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
                        child: Column(
                          children: [
                            Container(
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
                      ],
                    ),
                  );
                },
              ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportMedicalRecord(context),
                    icon: _isExporting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(
                      _isExporting ? "Exportation en cours..." : "Exporter Dossier Médical",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
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
                  _buildTemporaryAccessTile(),
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
              activeThumbColor: AppColors.primary,
              onChanged: (val) {},
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTemporaryAccess(bool enabled) async {
    if (_isUpdatingTemporaryAccess) return;
    setState(() => _isUpdatingTemporaryAccess = true);

    try {
      final until = enabled ? DateTime.now().add(const Duration(hours: 24)) : null;
      await context.read<AuthProvider>().updatePatientTemporaryAccess(
            enabled: enabled,
            until: until,
          );
      if (!mounted) return;
      setState(() {
        _temporaryAccessEnabled = enabled;
        _temporaryAccessUntil = until;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Accès temporaire activé pour 24h' : 'Accès temporaire désactivé'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingTemporaryAccess = false);
    }
  }

  Widget _buildTemporaryAccessTile() {
    final enabled = _temporaryAccessEnabled;
    final untilText = enabled && _temporaryAccessUntil != null
        ? 'Expire le ${DateFormat('dd/MM/yyyy HH:mm').format(_temporaryAccessUntil!.toLocal())}'
        : 'Activé pour 24h quand vous l’allumez';

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
              gradient: enabled ? AppColors.primaryGradient : null,
              color: enabled ? null : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.access_time,
              color: enabled ? Colors.white : AppColors.textGrey,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temporary Access (24h)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  untilText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: enabled,
              activeColor: AppColors.primary,
              onChanged: _isUpdatingTemporaryAccess ? null : (val) => _toggleTemporaryAccess(val),
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
      final results = await Future.wait([
        ApiService.getPatientAnalysisResults(widget.userId).catchError((_) => <dynamic>[]),
        ApiService.getPatientAnalyses().catchError((_) => <dynamic>[]),
      ]);
      if (mounted) {
        setState(() {
          _labResults = results[0];
          _patientAnalyses = results[1];
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
          // Accéder au dossier médical
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
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8F89FF)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.folder_shared_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mon dossier médical',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        Text(
                          "Analyses, ordonnances, examens",
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Accéder à l'Assistant IA
          GestureDetector(
            onTap: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AiAssistantChat(userId: authProvider.user?.id),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.small,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.aiGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assistant IA Média',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        Text(
                          "Posez vos questions de santé",
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Titre de la liste
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Résultats d'analyse",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCount document${totalCount > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
              : totalCount == 0
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
                              "Aucun résultat d'analyse pour le moment.\nAjoutez-en via le bouton ci-dessus.",
                              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Lab results
                        for (int i = 0; i < _labResults.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _buildLabResultItem(_labResults[i]),
                        ],
                        if (_labResults.isNotEmpty && _patientAnalyses.isNotEmpty)
                          const SizedBox(height: 12),
                        // Patient-uploaded analyses
                        for (int i = 0; i < _patientAnalyses.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _buildPatientAnalysisItem(_patientAnalyses[i]),
                        ],
                      ],
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OcrDocumentDetailScreen(document: m)),
        );
      },
      child: Container(
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
              Icon(Icons.chevron_right_rounded, color: AppColors.textGrey, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientAnalysisItem(dynamic a) {
    final m = a is Map<String, dynamic> ? a : <String, dynamic>{};
    final title = m['title']?.toString() ?? '';
    final type = m['analysisType'] ?? m['analysisTypeOther'] ?? '';
    final typeStr = type.toString().replaceAll('_', ' ').toLowerCase();
    final label = title.isNotEmpty ? title : (typeStr.isNotEmpty ? typeStr : 'Analyse');
    final date = m['analysisDate'] ?? m['createdAt'];
    String dateStr = '—';
    if (date != null) {
      try {
        dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(date.toString()));
      } catch (_) {}
    }
    final centreName = m['centreName']?.toString() ?? '';
    final source = m['source']?.toString() ?? '';
    final id = m['_id']?.toString() ?? '';
    final imageName = m['image_name']?.toString() ?? '';
    final isImage = imageName.toLowerCase().endsWith('.jpg') ||
        imageName.toLowerCase().endsWith('.jpeg') ||
        imageName.toLowerCase().endsWith('.png') ||
        imageName.toLowerCase().endsWith('.webp');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OcrDocumentDetailScreen(document: m)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.small,
          border: Border.all(color: AppColors.success.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isImage ? Icons.image_rounded : Icons.description_rounded,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  if (centreName.isNotEmpty)
                    Text(centreName, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
                  Row(
                    children: [
                      Text(dateStr, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
                      if (source.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: source == 'patient'
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            source == 'patient' ? 'Personnel' : 'Centre',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: source == 'patient' ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (id.isNotEmpty)
              IconButton(
                onPressed: () => _deletePatientAnalysis(id),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                tooltip: 'Supprimer',
                style: IconButton.styleFrom(backgroundColor: AppColors.error.withOpacity(0.08)),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: AppColors.textGrey, size: 22),
          ],
        ),
      ),
    );
  }
}