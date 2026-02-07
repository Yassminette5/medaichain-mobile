import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/app_images.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  String? _scannedData;
  bool _accessGranted = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _scannedData = null;
      _accessGranted = false;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      setState(() {
        _isScanning = false;
        _scannedData = barcodes.first.rawValue ?? "Unknown User";
        // Simulate Smart Contract Verification
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _accessGranted = true;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Immersive scan mode
      body: Stack(
        children: [
          // 1. Camera Layer or Placeholder Background
          if (_isScanning)
            MobileScanner(onDetect: _onDetect, fit: BoxFit.cover)
          else
            _buildStandardBackground(),

          // 2. Overlay UI
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _isScanning ? _buildScannerOverlay() : _buildResultContent(),
                ),
              ],
            ),
          ),
          
          // 3. Close Scan Button
          if (_isScanning)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.large(
                  backgroundColor: Colors.white,
                  onPressed: () => setState(() => _isScanning = false),
                  child: const Icon(Icons.close, color: Colors.black),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: !_isScanning && _scannedData == null
          ? FloatingActionButton.extended(
              onPressed: _startScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scanner Patient'),
              backgroundColor: AppTheme.primaryBlue,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStandardBackground() {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Opacity(
          opacity: 0.05,
          child: Icon(Icons.qr_code_2_rounded, size: 300, color: AppTheme.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: _isScanning ? Colors.white : AppTheme.darkNavy),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Réception & Check-in',
            style: GoogleFonts.plusJakartaSans(
              color: _isScanning ? Colors.white : AppTheme.darkNavy,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated Scanner Box
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          // Scanner Line
           AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 240,
                height: 2,
                color: AppTheme.primaryTeal,
                margin: EdgeInsets.only(top: 240 * (_animationController.value - 0.5)),
              );
            },
          ),
          Positioned(
            bottom: 100,
            child: Text(
              "Placez le QR Code ici",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent() {
    if (_scannedData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: ClipOval(
                child: Image(
                    image: AppImages.provider(AppImages.checkin, AppImages.checkinUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Icon(Icons.qr_code, size: 80, color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "Prêt à Scanner",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Approchez le QR Code du patient pour accéder à son dossier sécurisé via Blockchain.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSmartContractStatus(),
          const SizedBox(height: 24),
          if (_accessGranted) _buildPatientNftCard(),
          const SizedBox(height: 40), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSmartContractStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _accessGranted ? AppTheme.success.withValues(alpha: 0.05) : AppTheme.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accessGranted ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: _accessGranted 
              ? const Icon(Icons.verified_user_rounded, color: AppTheme.success, size: 28)
              : const SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.warning),
                ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Smart Contract Status",
                  style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  _accessGranted ? "Accès Autorisé" : "Vérification Blockchain...",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _accessGranted ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientNftCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkNavy.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Gradient
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              "DOSSIER PATIENT UNIVERSEL",
              style: GoogleFonts.sourceCodePro(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: const NetworkImage("https://i.pravatar.cc/150?img=5"), // Sophie Martin
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      Text(
                        "Sophie Martin",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                      Text(
                        "ID: #NFT-8873-XJ9",
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoBadge("Sang", "A+", Icons.bloodtype, Colors.red),
                    _buildInfoBadge("Age", "34", Icons.cake, Colors.orange),
                    _buildInfoBadge("Sexe", "F", Icons.female, Colors.purple),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_edu, color: AppTheme.darkNavy),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dernière visite",
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              "12 Oct 2023 • Cardiologie",
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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
  }

  Widget _buildInfoBadge(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
