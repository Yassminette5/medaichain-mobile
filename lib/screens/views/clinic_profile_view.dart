import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class ClinicProfileView extends StatefulWidget {
  const ClinicProfileView({super.key});

  @override
  State<ClinicProfileView> createState() => _ClinicProfileViewState();
}

class _ClinicProfileViewState extends State<ClinicProfileView> {
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.updateClinicProfile({
        'name': _nameCtrl.text,
        'email': _emailCtrl.text,
        'phoneNumber': _phoneCtrl.text,
        'address': _addressCtrl.text,
        'city': _cityCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour !')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur sauvegarde: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryMedical));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de la clinique',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ces informations sont enregistrées sur la base de données Atlas.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            _buildTextField('Nom de la clinique', _nameCtrl, Icons.local_hospital),
            const SizedBox(height: 20),
            _buildTextField('Email', _emailCtrl, Icons.email),
            const SizedBox(height: 20),
            _buildTextField('Téléphone', _phoneCtrl, Icons.phone),
            const SizedBox(height: 20),
            _buildTextField('Adresse', _addressCtrl, Icons.location_on),
            const SizedBox(height: 20),
            _buildTextField('Ville', _cityCtrl, Icons.location_city),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMedical,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sauvegarder les modifications', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
