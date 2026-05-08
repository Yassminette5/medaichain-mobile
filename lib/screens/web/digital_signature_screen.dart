import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/theme/app_colors.dart';

/// Écran de signature numérique pour les résultats
class DigitalSignatureScreen extends StatefulWidget {
  const DigitalSignatureScreen({super.key});

  @override
  State<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends State<DigitalSignatureScreen> {
  final GlobalKey _signatureKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _resultsToSign = [];
  Map<String, dynamic>? _selectedResult;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _loadResultsToSign();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResultsToSign() async {
    // TODO: Charger les résultats en attente de signature depuis l'API
    setState(() {
      _resultsToSign = [
        {
          'id': '1',
          'patientName': 'Ahmed Benali',
          'analysisType': 'Analyse sanguine',
          'date': DateTime.now().subtract(const Duration(days: 2)),
          'fileUrl': 'resultat_001.pdf',
        },
        {
          'id': '2',
          'patientName': 'Fatima Zohra',
          'analysisType': 'Scanner',
          'date': DateTime.now().subtract(const Duration(days: 5)),
          'fileUrl': 'resultat_002.pdf',
        },
      ];
    });
  }

  Future<void> _signResult() async {
    if (_selectedResult == null) {
      _showErrorSnackBar('Veuillez sélectionner un résultat à signer');
      return;
    }

    setState(() => _isSigning = true);

    try {
      // TODO: Implémenter la signature numérique avec le backend
      // Capture de la signature depuis le canvas
      final RenderRepaintBoundary boundary =
          _signatureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // TODO: Envoyer la signature au backend
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          _showSuccessSnackBar('Résultat signé avec succès');
          setState(() {
            _selectedResult = null;
            _resultsToSign.removeWhere(
                (r) => r['id'] == _selectedResult?['id']);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la signature: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSigning = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Liste des résultats à signer
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Résultats à signer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _resultsToSign.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tous les résultats sont signés',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _resultsToSign.length,
                          itemBuilder: (context, index) {
                            final result = _resultsToSign[index];
                            final isSelected =
                                _selectedResult?['id'] == result['id'];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedResult = result;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result['patientName']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      result['analysisType']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        // Zone de signature
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _selectedResult == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sélectionnez un résultat à signer',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedResult!['patientName']?.toString() ??
                                      'Patient',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedResult!['analysisType']?.toString() ??
                                      '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedResult = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Annuler'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Zone de signature
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: RepaintBoundary(
                          key: _signatureKey,
                          child: SignaturePad(
                            onSignatureChanged: (signature) {
                              // Callback pour la signature
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              // TODO: Effacer la signature
                            },
                            child: const Text('Effacer'),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _isSigning ? null : _signResult,
                            icon: _isSigning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(_isSigning ? 'Signature...' : 'Signer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour capturer la signature
class SignaturePad extends StatefulWidget {
  final Function(String)? onSignatureChanged;

  const SignaturePad({super.key, this.onSignatureChanged});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<Offset> _points = [];

  void _clearSignature() {
    setState(() {
      _points = [];
    });
    widget.onSignatureChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          RenderBox box = context.findRenderObject() as RenderBox;
          _points.add(box.globalToLocal(details.globalPosition));
        });
      },
      onPanEnd: (details) {
        _points.add(const Offset(-1, -1)); // Marqueur de fin
      },
      child: CustomPaint(
        painter: SignaturePainter(_points),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != const Offset(-1, -1) &&
          points[i + 1] != const Offset(-1, -1)) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
