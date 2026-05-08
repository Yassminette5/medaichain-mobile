import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';
import '../../services/api_service.dart';
import '../../services/subscription_service.dart';
import 'premium_paywall_screen.dart';

/// Écran Aide à la Décision IA
class AiDecisionSupportScreen extends StatefulWidget {
  const AiDecisionSupportScreen({super.key});

  @override
  State<AiDecisionSupportScreen> createState() =>
      _AiDecisionSupportScreenState();
}

class _AiDecisionSupportScreenState extends State<AiDecisionSupportScreen> {
  int _selectedTab = 0;
  bool _isLoading = false;
  bool _isLoadingPending = true;
  bool _isAiAvailable = false;
  String _aiProvider = '';
  String? _errorMessage;

  // Timer pour afficher le temps écoulé pendant l'analyse
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  String? _analyzingItemId; // ID de l'item en cours d'analyse

  // Données dynamiques provenant de l'IA
  final List<Map<String, dynamic>> _aiAnalyses = [];
  final List<Map<String, dynamic>> _pendingAnalyses = [];

  // Données statiques existantes (alertes et conseils)
  final List<Map<String, dynamic>> _riskAlerts = [
    {
      'title': 'Risque complications diabétiques',
      'description':
          'Jean Dupont présente un risque élevé de néphropathie diabétique selon les niveaux HbA1c récents.',
      'severity': 'high',
      'action': 'Envisager orientation vers néphrologue',
      'timestamp': 'Il y a 2 heures',
    },
    {
      'title': "Alerte interaction médicamenteuse",
      'description':
          "Interaction potentielle entre Lisinopril et suppléments de Potassium pour Pierre Dubois.",
      'severity': 'medium',
      'action': 'Réviser liste médicaments',
      'timestamp': 'Il y a 4 heures',
    },
    {
      'title': 'Suivi manqué',
      'description':
          'Marie Martin a manqué le suivi cardiologie prévu depuis 2 semaines.',
      'severity': 'low',
      'action': 'Planifier nouveau rendez-vous',
      'timestamp': 'Hier',
    },
  ];

  // Liste dynamique des conseils (remplie par l'IA)
  final List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _checkAiStatus();
    _loadPendingAnalyses();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _elapsedSeconds = 0;
  }

  String get _elapsedLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  Future<void> _loadPendingAnalyses() async {
    try {
      final list = await ApiService.getPendingPatientAnalyses();
      if (mounted) {
        setState(() {
          _pendingAnalyses.clear();
          _pendingAnalyses.addAll(list);
          _isLoadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPending = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _checkAiStatus() async {
    try {
      final status = await ApiService.getDoctorAiStatus();
      if (mounted) {
        setState(() {
          _isAiAvailable = status['available'] == true;
          _aiProvider = status['provider']?.toString() ?? 'inconnu';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAiAvailable = false;
          _aiProvider = 'hors ligne';
        });
      }
    }
  }

  bool _isUploadedDocumentRejected(Map<String, dynamic> response) {
    if (response['documentRejected'] == true) return true;
    final conf = response['confidence'];
    final diag = (response['diagnosis'] ?? '').toString().toLowerCase();
    if (conf is num && conf <= 0.12) {
      return diag.contains('ocr') ||
          diag.contains('ressemble pas') ||
          diag.contains('texte trop court') ||
          diag.contains('aucune image') ||
          diag.contains('peu fiable');
    }
    return false;
  }

  Future<void> _showInvalidAnalysisDialog(String? detail) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Veuillez importer une vraie analyse',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ce fichier ne correspond pas à un document médical exploitable : bilan de laboratoire, ordonnance ou compte-rendu lisible et bien cadré.',
                style: TextStyle(color: AppColors.textPrimary, height: 1.45),
              ),
              if (detail != null && detail.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  detail.trim(),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// Vérifie l'accès premium avant de lancer une analyse IA.
  /// Affiche TOUJOURS le paywall pour les utilisateurs gratuits (démo du flux complet).
  Future<bool> _checkPremiumAccess() async {
    final sub = SubscriptionService();
    await sub.refreshBackendStatus();

    // Premium → accès direct sans paywall
    if (sub.isPremium) return true;

    // Utilisateur gratuit → toujours afficher le paywall (pub ou abonnement)
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()),
    );

    if (result == true) {
      // Rafraîchir le statut depuis le backend après la pub/achat
      await sub.refreshBackendStatus();
      
      if (sub.isPremium || sub.adCredits > 0 || sub.remainingQuota > 0) {
        if (mounted) setState(() {}); // Rafraîchir l'affichage des crédits
        return true;
      }
    }

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun crédit reçu. Regardez la vidéo complète ou activez Premium.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    return false;
  }

  Future<void> _analyzePatientAnalysis(Map<String, dynamic> pending) async {
    // Gate premium
    final hasAccess = await _checkPremiumAccess();
    if (!hasAccess) return;

    setState(() {
      _isLoading = true;
      _analyzingItemId = pending['_id']?.toString();
      _errorMessage = null;
    });
    _startElapsedTimer();

    try {
      final response = await ApiService.analyzePatientAnalysisLocal(
        pending['_id'],
        context:
            'Analyse demandée par le patient ${pending['userId']?['fullName'] ?? ''}',
      );

      if (mounted) {
        _stopElapsedTimer();
        setState(() {
          _isLoading = false;
          _analyzingItemId = null;
          _aiAnalyses.insert(0, {
            '_id': pending['_id'],
            'patientId': pending['userId']?['_id'],
            'patientName': pending['userId']?['fullName'] ?? 'Patient',
            'diagnosis': response['diagnosis'] ?? 'Pas de diagnostic',
            'advice': response['advice'] ?? '',
            'prescriptions': response['prescription_suggestions'] ?? [],
            'emergency_level': response['emergency_level'] ?? 'faible',
            'timestamp': DateTime.now().toIso8601String(),
            'fileName': pending['title'] ?? 'Rapport patient',
          });

          if (response['advice'] != null &&
              response['advice'].toString().isNotEmpty) {
            _recommendations.insert(0, {
              'title':
                  'Conseil Patient : ${pending['userId']?['fullName'] ?? 'Patient Inconnu'}',
              'recommendation': response['advice'],
              'confidence': response['confidence'] ?? 0.85,
              'sources':
                  response['sources'] ??
                  ['IA: $_aiProvider', 'Analyse du dossier'],
            });
          }

          _pendingAnalyses.removeWhere((p) => p['_id'] == pending['_id']);
          _selectedTab = 2; // Aller à l'onglet Conseils pour montrer l'avis
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analyse IA terminée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _stopElapsedTimer();
        setState(() {
          _isLoading = false;
          _analyzingItemId = null;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        String msg = e.toString().replaceFirst("Exception: ", "");
        if (msg.contains("Timeout") || msg.contains("timeout")) {
          msg =
              "L'analyse IA prend trop de temps ($_elapsedLabel écoulées). "
              "Le modèle local est lent sur votre GPU. "
              "Réessayez ou utilisez un modèle 3B plus léger.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('❌ $msg')),
            ]),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _uploadAndAnalyze() async {
    // Gate premium
    final hasAccess = await _checkPremiumAccess();
    if (!hasAccess) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible de lire l’image. Réessayez ou choisissez un autre fichier.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
        _analyzingItemId = 'upload';
        _errorMessage = null;
      });
      _startElapsedTimer();

      final base64Image = base64Encode(bytes);

      // Appeler l'API d'analyse
      final response = Map<String, dynamic>.from(
        await ApiService.analyzeReport(
          reportImage: base64Image,
          context: 'Analyse de rapport médical uploadé par le médecin',
        ),
      );

      if (!mounted) return;

      _stopElapsedTimer();
      setState(() {
        _isLoading = false;
        _analyzingItemId = null;
      });

      if (_isUploadedDocumentRejected(response)) {
        await _showInvalidAnalysisDialog(response['diagnosis']?.toString());
        return;
      }

      setState(() {
        _aiAnalyses.insert(0, {
          'diagnosis': response['diagnosis'] ?? 'Pas de diagnostic',
          'advice': response['advice'] ?? '',
          'regime': response['regime'] ?? response['diet'] ?? '',
          'prescriptions': response['prescription_suggestions'] ?? [],
          'emergency_level': response['emergency_level'] ?? 'faible',
          'timestamp': DateTime.now().toIso8601String(),
          'fileName': result.files.first.name,
        });

        if (response['advice'] != null &&
            response['advice'].toString().isNotEmpty) {
          _recommendations.insert(0, {
            'title': 'Conseil IA',
            'recommendation': response['advice'],
            'confidence': response['confidence'] ?? 0.85,
            'sources': response['sources'] ?? ['IA: $_aiProvider'],
          });
        }
        
        if ((response['regime'] != null && response['regime'].toString().isNotEmpty) || 
            (response['diet'] != null && response['diet'].toString().isNotEmpty)) {
          _recommendations.insert(0, {
            'title': 'Régime Alimentaire Suggéré',
            'recommendation': response['regime'] ?? response['diet'],
            'confidence': response['confidence'] ?? 0.80,
            'sources': ['Analyse Diététique IA'],
          });
        }

        _selectedTab = 2; // Aller à l'onglet Conseils
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analyse terminée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _stopElapsedTimer();
        setState(() {
          _isLoading = false;
          _analyzingItemId = null;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        String msg = e.toString().replaceFirst("Exception: ", "");
        if (msg.contains("Timeout") || msg.contains("timeout")) {
          msg =
              "L'analyse IA prend trop de temps. "
              "Le modèle local est lent sur votre GPU ($_elapsedLabel écoulées). "
              "Essayez un modèle 3B plus léger.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('❌ $msg')),
            ]),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Aide à la Décision IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isAiAvailable
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isAiAvailable
                                      ? 'IA active ($_aiProvider)'
                                      : 'IA hors ligne',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PremiumPaywallScreen(),
                                      ),
                                    );
                                    // Si l'utilisateur a obtenu un accès (pub ou abonnement),
                                    // lancer automatiquement l'analyse IA
                                    if (result == true && mounted) {
                                      setState(() {}); // Rafraîchir l'affichage des crédits
                                      _uploadAndAnalyze();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SubscriptionService().isPremium
                                          ? Colors.amber
                                          : Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          SubscriptionService().isPremium
                                              ? Icons.diamond
                                              : Icons.token,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          SubscriptionService().isPremium
                                              ? 'Premium'
                                              : '${SubscriptionService().remainingQuota + SubscriptionService().adCredits} crédits',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
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
                      ),
                      // Bouton Upload
                      GestureDetector(
                        onTap: _isLoading ? null : _uploadAndAnalyze,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_photo_alternate,
                                  color: Colors.white,
                                  size: 26,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Contenu principal
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Disclaimer IA
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildAIDisclaimer(),
                      ),
                      const SizedBox(height: 16),
                      // Tabs
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _buildTab(0, 'Analyses', Icons.science),
                            _buildTab(1, 'Alertes', Icons.warning_amber),
                            _buildTab(2, 'Conseils', Icons.lightbulb),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: IndexedStack(
                          index: _selectedTab,
                          children: [
                            _buildAnalysesTab(),
                            _buildAlertsTab(),
                            _buildRecommendationsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Les suggestions IA sont à titre informatif uniquement. Toujours appliquer le jugement clinique.",
              style: TextStyle(
                color: AppColors.warning.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== ONGLET ANALYSES IA ==========
  Widget _buildAnalysesTab() {
    if (_aiAnalyses.isEmpty) {
      if (_isLoadingPending) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_pendingAnalyses.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.aiGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aucune analyse IA',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploadez un rapport médical ou attendez qu\'un patient en envoie un.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadAndAnalyze,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    _isLoading ? 'Analyse en cours...' : 'Analyser un rapport',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _pendingAnalyses.length,
          itemBuilder: (context, index) {
            final pending = _pendingAnalyses[index];
            final patientName =
                pending['userId']?['fullName'] ?? 'Patient Inconnu';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.file_present, color: AppColors.primary),
                ),
                title: Text(
                  pending['title'] ?? 'Analyse',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('De : $patientName'),
                trailing: _isLoading &&
                        _analyzingItemId == pending['_id']?.toString()
                    ? _buildItemLoadingWidget()
                    : _isLoading
                        ? const Icon(Icons.hourglass_top_rounded,
                            color: AppColors.textLight)
                        : const Icon(Icons.psychology, color: AppColors.primary),
                onTap: _isLoading
                    ? null
                    : () => _analyzePatientAnalysis(pending),
              ),
            );
          },
        );
      }
    }

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinner animé
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      backgroundColor: AppColors.borderLight,
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.blockchainLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_rounded,
                        color: AppColors.primary, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Analyse IA en cours...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Temps écoulé
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blockchainLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Temps écoulé : $_elapsedLabel',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Le modèle IA traite le document médicalement.\nCela peut prendre 1 à 3 minutes selon votre GPU.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              // Avertissement si ça prend trop longtemps
              if (_elapsedSeconds > 60)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _elapsedSeconds > 120
                              ? 'Analyse très longue ($_elapsedLabel). Modèle 7B lent sur GPU 4GB. '
                                  'Envisagez un modèle 3B.'
                              : 'L\'analyse prend plus d\'une minute. '
                                  'Modèle lourd sur GPU limité — veuillez patienter.',
                          style: TextStyle(
                              color: AppColors.warning, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _aiAnalyses.length,
      itemBuilder: (context, index) => _buildAnalysisCard(_aiAnalyses[index]),
    );
  }

  Widget _buildItemLoadingWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Analyse en cours...',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _elapsedLabel,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    final level = analysis['emergency_level']?.toString() ?? 'faible';
    final levelColor = level == 'critique'
        ? AppColors.error
        : level == 'moyen'
        ? AppColors.warning
        : AppColors.success;
    final levelBg = level == 'critique'
        ? AppColors.errorLight
        : level == 'moyen'
        ? AppColors.warningLight
        : AppColors.successLight;
    final levelLabel = level.toUpperCase();
    final prescriptions = analysis['prescriptions'] as List? ?? [];

    return MedicalCard(
      showBorder: level == 'critique',
      borderColor: level == 'critique'
          ? AppColors.error.withValues(alpha: 0.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnostic IA',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysis['fileName'] ?? 'Rapport analysé',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: levelBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  levelLabel,
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Diagnostic
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medical_information,
                      color: AppColors.diagnosis,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Diagnostic',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.diagnosis,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  analysis['diagnosis']?.toString() ?? '',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Conseils
          if (analysis['advice'] != null &&
              analysis['advice'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Conseils',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    analysis['advice'].toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          // Régime
          if (analysis['regime'] != null && analysis['regime'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // Vert très clair
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Régime Suggéré',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    analysis['regime'].toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          // Prescriptions
          if (prescriptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.diagnosisLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.medication,
                        color: AppColors.prescription,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prescriptions suggérées',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.prescription,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...prescriptions.map<Widget>(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.prescription,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${p['name'] ?? ''} - ${p['dosage'] ?? ''} (${p['frequency'] ?? ''})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _aiAnalyses.remove(analysis));
                  },
                  child: const Text('Ignorer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAcceptDialog(analysis),
                  child: const Text('Créer ordonnance'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider et Créer l\'ordonnance ?'),
        content: Text(
          'Voulez-vous valider cette analyse et générer une ordonnance pour le patient ?\n\n'
          'Patient: ${analysis['patientName'] ?? 'Actuel'}\n'
          'Diagnostic: ${analysis['diagnosis']}\n'
          'Niveau: ${analysis['emergency_level']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                if (analysis['_id'] != null) {
                  await ApiService.acceptPatientAnalysisSuggestion(
                    analysisId: analysis['_id'],
                    diagnosis: analysis['diagnosis'],
                    advice: analysis['advice'],
                    createAiPrescriptionDto:
                        (analysis['prescriptions'] as List).isNotEmpty
                        ? {
                            'patientId': analysis['patientId'],
                            'medications': analysis['prescriptions'],
                            'diagnosis': analysis['diagnosis'],
                            'notes': analysis['advice'],
                          }
                        : null,
                  );
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Analyse validée et ordonnance créée !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    _aiAnalyses.remove(analysis);
                    _isLoading = false;
                  });
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur : $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // ========== ONGLET ALERTES ==========
  Widget _buildAlertsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _riskAlerts.length,
      itemBuilder: (context, index) => _buildAlertCard(_riskAlerts[index]),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severityColor = alert['severity'] == 'high'
        ? AppColors.error
        : alert['severity'] == 'medium'
        ? AppColors.warning
        : AppColors.info;
    final severityIcon = alert['severity'] == 'high'
        ? Icons.error
        : alert['severity'] == 'medium'
        ? Icons.warning
        : Icons.info;

    return MedicalCard(
      showBorder: alert['severity'] == 'high',
      borderColor: AppColors.error.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(severityIcon, color: severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert['timestamp'],
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert['description'],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_forward, color: severityColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Suggéré: ${alert['action']}',
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== ONGLET RECOMMANDATIONS (Conseils) ==========
  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Aucun conseil généré pour l'instant. Lancez une analyse pour voir les recommandations IA.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) =>
          _buildRecommendationCard(_recommendations[index]),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final confidence = (rec['confidence'] as double) * 100;

    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rec['title'],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${confidence.toStringAsFixed(0)}% confiance',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rec['recommendation'],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rec['confidence'],
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (rec['sources'] as List)
                .map<Widget>(
                  (source) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          source,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.thumb_down_outlined, size: 16),
                  label: const Text('Pas utile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
