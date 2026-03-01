import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medaichainmobile/clinique/theme/app_theme.dart';
import 'package:medaichainmobile/services/api_service.dart';

class ClinicProfileView extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const ClinicProfileView({super.key, this.onProfileUpdated});

  @override
  State<ClinicProfileView> createState() => _ClinicProfileViewState();
}

class _ClinicProfileViewState extends State<ClinicProfileView>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSaving = false;
  late TabController _tabController;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _wilayaCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _wilayaCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final clinic = await ApiService.getClinicProfile();
      setState(() {
        _nameCtrl.text = clinic['name'] ?? '';
        _emailCtrl.text = clinic['email'] ?? '';
        _phoneCtrl.text = clinic['phoneNumber'] ?? '';
        _addressCtrl.text = clinic['address'] ?? '';
        _cityCtrl.text = clinic['city'] ?? '';
        _wilayaCtrl.text = clinic['wilaya'] ?? '';
        _descriptionCtrl.text = clinic['description'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Erreur de chargement: $e', isError: true);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnackBar('Le nom de la clinique est obligatoire', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ApiService.updateClinicProfile({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'wilaya': _wilayaCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
      });
      if (mounted) {
        _showSnackBar('Profil mis à jour avec succès !', isError: false);
        // Notify parent to refresh clinic name in sidebar
        widget.onProfileUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur de sauvegarde: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                color: Colors.white, size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingSkeleton();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerLight.withOpacity(0.5)),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Informations Générales'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Horaires & Options'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 620,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildScheduleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======= PROFILE HEADER =======
  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF132E57), Color(0xFF1A4B8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0A1628).withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.03)))),
          Positioned(right: 40, bottom: -20, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.02)))),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppTheme.primaryMedical.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: Text(
                      _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'C',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Clinique',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildHeaderChip(Icons.location_on_rounded, _cityCtrl.text.isNotEmpty ? _cityCtrl.text : 'Ville'),
                          const SizedBox(width: 10),
                          _buildHeaderChip(Icons.verified_rounded, 'Vérifiée'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildHeaderStat('Email', _emailCtrl.text.isNotEmpty ? _emailCtrl.text : '-'),
                          const SizedBox(width: 24),
                          _buildHeaderStat('Téléphone', _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : '-'),
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
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.chainAccent, size: 14),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  // ======= INFO TAB =======
  Widget _buildInfoTab() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded, color: AppTheme.primaryMedical, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modifier les informations', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                  Text('Mettez à jour les données de votre clinique', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Row 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPremiumField('Nom de la clinique *', _nameCtrl, Icons.local_hospital_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _buildPremiumField('Email', _emailCtrl, Icons.email_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPremiumField('Téléphone', _phoneCtrl, Icons.phone_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _buildPremiumField('Adresse', _addressCtrl, Icons.location_on_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          // Row 3
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPremiumField('Ville', _cityCtrl, Icons.location_city_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _buildPremiumField('Wilaya', _wilayaCtrl, Icons.map_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          // Description
          _buildPremiumField('Description de la clinique', _descriptionCtrl, Icons.description_rounded, maxLines: 3),
          const Spacer(),
          // Save buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('Réinitialiser', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Sauvegarde...' : 'Sauvegarder les modifications',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======= SCHEDULE TAB =======
  Widget _buildScheduleTab() {
    final days = ['Samedi', 'Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];
    final openDays = [true, true, true, true, true, true, false];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.accentMedical.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.access_time_rounded, color: AppTheme.accentMedical, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horaires d\'ouverture', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                  Text('Configurez les heures de travail', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: days.length,
              separatorBuilder: (_, __) => Divider(color: AppTheme.dividerLight.withOpacity(0.5), height: 1),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(days[index], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.darkNavy, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (openDays[index] ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          openDays[index] ? 'Ouvert' : 'Fermé',
                          style: GoogleFonts.plusJakartaSans(color: openDays[index] ? AppTheme.success : AppTheme.error, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      if (openDays[index])
                        Row(
                          children: [
                            _buildTimeChip('08:00'),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('—', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5))),
                            ),
                            _buildTimeChip('17:00'),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
    );
  }

  // ======= PREMIUM FIELD =======
  Widget _buildPremiumField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.darkNavy),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1
                ? Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primaryMedical.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 18, color: AppTheme.primaryMedical),
                  )
                : null,
            hintText: 'Saisir $label',
            hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 14),
            filled: true,
            fillColor: AppTheme.background,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 14 : 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.dividerLight.withOpacity(0.5))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.dividerLight.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryMedical, width: 1.5)),
          ),
        ),
      ],
    );
  }

  // ======= LOADING SKELETON =======
  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        Container(height: 160, decoration: BoxDecoration(color: AppTheme.dividerLight.withOpacity(0.5), borderRadius: BorderRadius.circular(24))),
        const SizedBox(height: 24),
        Container(height: 50, decoration: BoxDecoration(color: AppTheme.dividerLight.withOpacity(0.3), borderRadius: BorderRadius.circular(16))),
        const SizedBox(height: 24),
        Expanded(child: Container(decoration: BoxDecoration(color: AppTheme.dividerLight.withOpacity(0.2), borderRadius: BorderRadius.circular(20)))),
      ],
    );
  }
}
