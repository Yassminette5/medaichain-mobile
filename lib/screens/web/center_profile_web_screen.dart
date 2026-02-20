import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Écran du profil du centre d'analyse adapté pour le web
class CenterProfileWebScreen extends StatefulWidget {
  const CenterProfileWebScreen({super.key});

  @override
  State<CenterProfileWebScreen> createState() => _CenterProfileWebScreenState();
}

class _CenterProfileWebScreenState extends State<CenterProfileWebScreen> {
  String? _labName;
  String? _localisation;
  List<String> _categories = [];
  String? _phone;
  String? _email;
  bool _onlineBookingEnabled = true;
  bool _isActive = true;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _localisationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Liste des catégories disponibles
  final List<String> _availableCategories = [
    'Biologie',
    'Radiologie',
    'Imagerie',
    'Cardiologie',
    'Neurologie',
    'Oncologie',
    'Gynécologie',
    'Pédiatrie',
    'Génétique',
    'Microbiologie',
    'Hématologie',
    'Biochimie',
    'Immunologie',
  ];

  @override
  void initState() {
    super.initState();
    _loadCenterProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _localisationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCenterProfile() async {
    setState(() => _isLoading = true);

    try {
      final labProfile = await ApiService.getLabProfile();
      if (mounted) {
        setState(() {
          _labName = labProfile['centreName'] ?? labProfile['name'] ?? labProfile['centre_name'] ?? '';
          _localisation = labProfile['localisation'] ?? '';
          
          if (labProfile['categorie'] != null) {
            if (labProfile['categorie'] is List) {
              _categories = List<String>.from(labProfile['categorie']);
            } else if (labProfile['categorie'] is String) {
              _categories = [labProfile['categorie']];
            } else {
              _categories = [];
            }
          } else {
            _categories = [];
          }
          
          _phone = labProfile['phone'] ?? '';
          _email = labProfile['email'] ?? '';
          _onlineBookingEnabled = labProfile['onlineBooking'] ?? labProfile['reservation_en_ligne'] ?? true;
          _isActive = labProfile['isActive'] ?? true;
          
          _nameController.text = _labName ?? '';
          _localisationController.text = _localisation ?? '';
          _phoneController.text = _phone ?? '';
          _emailController.text = _email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Erreur de chargement du profil: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Le nom du centre est requis');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'centreName': _nameController.text.trim(),
        'localisation': _localisationController.text.trim(),
        'categorie': _categories,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'onlineBooking': _onlineBookingEnabled,
        'isActive': _isActive,
      };

      await ApiService.updateLabProfile(updateData);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _labName = _nameController.text.trim();
          _localisation = _localisationController.text.trim();
          _phone = _phoneController.text.trim();
          _email = _emailController.text.trim();
        });

        _showSuccessSnackBar('Profil mis à jour avec succès');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Erreur de sauvegarde: $e');
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec bouton d'édition
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profil du Centre',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!_isEditing)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isEditing = true);
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.text = _labName ?? '';
                          _localisationController.text = _localisation ?? '';
                          _phoneController.text = _phone ?? '';
                          _emailController.text = _email ?? '';
                        });
                      },
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 32),
          // Formulaire en deux colonnes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonne gauche
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informations générales'),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom du centre',
                      icon: Icons.business_rounded,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _localisationController,
                      label: 'Localisation',
                      icon: Icons.location_on_rounded,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone_rounded,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_rounded,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Colonne droite
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Catégories d\'analyses'),
                    const SizedBox(height: 20),
                    _buildCategoriesSection(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Paramètres'),
                    const SizedBox(height: 20),
                    _buildSwitchTile(
                      title: 'Réservation en ligne activée',
                      subtitle: 'Permettre aux patients de prendre rendez-vous en ligne',
                      value: _onlineBookingEnabled,
                      onChanged: _isEditing
                          ? (value) {
                              setState(() => _onlineBookingEnabled = value);
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      title: 'Centre actif',
                      subtitle: 'Le centre apparaît dans les recherches',
                      value: _isActive,
                      onChanged: _isEditing
                          ? (value) {
                              setState(() => _isActive = value);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Material(
      color: Colors.transparent,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: enabled ? AppColors.background : AppColors.surface,
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
            Text(
              'Sélectionnez les catégories proposées par votre centre',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableCategories.map((category) {
              final isSelected = _categories.contains(category);
              return Material(
                color: Colors.transparent,
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: _isEditing
                      ? (selected) {
                          setState(() {
                            if (selected) {
                              if (!_categories.contains(category)) {
                                _categories.add(category);
                              }
                            } else {
                              _categories.remove(category);
                            }
                          });
                        }
                      : null,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
