import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Écran du profil du centre d'analyse
class CenterProfileScreen extends StatefulWidget {
  const CenterProfileScreen({super.key});

  @override
  State<CenterProfileScreen> createState() => _CenterProfileScreenState();
}

class _CenterProfileScreenState extends State<CenterProfileScreen> {
  String? _labName;
  String? _localisation;
  List<String> _categories = [];
  String? _phone;
  String? _email;
  String? _profilePhoto;
  bool _onlineBookingEnabled = true;
  bool _isActive = true;
  bool _isEditing = false;
  bool _isLoading = true;

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
    'Tous',
  ];

  @override
  void initState() {
    super.initState();
    _loadCenterProfile();
  }

  Future<void> _loadCenterProfile() async {
    try {
      final labProfile = await ApiService.getLabProfile();
      if (mounted) {
        setState(() {
          _labName = labProfile['centreName'] ?? labProfile['name'] ?? labProfile['centre_name'] ?? '';
          _localisation = labProfile['localisation'] ?? '';
          // Gérer categorie comme tableau ou chaîne
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
          final profilePhotoPath = labProfile['profilePhoto'] ?? 
                         labProfile['photo'] ?? 
                         labProfile['photoUrl'] ?? 
                         labProfile['image'] ?? 
                         labProfile['imageUrl'] ?? 
                         labProfile['logo'] ?? 
                         labProfile['logoUrl'];
          _profilePhoto = profilePhotoPath;
          debugPrint('🔵 Profile: ProfilePhotoPath: $profilePhotoPath');
          debugPrint('🔵 Profile: ProfilePhoto URL finale: ${_profilePhoto != null && _profilePhoto!.isNotEmpty ? _buildImageUrl(_profilePhoto!) : null}');
          _onlineBookingEnabled = labProfile['onlineBooking'] ?? labProfile['reservation_en_ligne'] ?? true;
          _isActive = labProfile['isActive'] ?? true;
          
          // Normaliser la localisation pour correspondre exactement à un item du dropdown
          if (_localisation != null && _localisation!.isNotEmpty) {
            final normalizedLocation = _normalizeLocation(_localisation!);
            _localisation = normalizedLocation;
          }
          
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
          _labName = '';
          _localisation = '';
          _categories = [];
          _phone = '';
          _email = '';
          _nameController.text = '';
          _localisationController.text = '';
          _phoneController.text = '';
          _emailController.text = '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _localisationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    try {
      final updateData = {
        'centreName': _nameController.text,
        'localisation': _localisationController.text,
        'categorie': _categories,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'onlineBooking': _onlineBookingEnabled,
        'isActive': _isActive,
      };

      await ApiService.updateLabProfile(updateData);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _labName = _nameController.text;
          _localisation = _localisationController.text;
          _phone = _phoneController.text;
          _email = _emailController.text;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onNameChanged(String value) {
    setState(() {
      // Le nom sera mis à jour automatiquement dans la carte de profil
      // car on utilise _nameController.text dans l'affichage
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Profil du Centre',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () => setState(() => _isEditing = true),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.check, color: AppColors.success),
                onPressed: _saveProfile,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildIsActiveCard(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                  const SizedBox(height: 20), // Espace en bas pour le scroll
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _profilePhoto != null && _profilePhoto!.isNotEmpty
                  ? Image.network(
                      _buildImageUrl(_profilePhoto!),
                      width: 77,
                      height: 77,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 77,
                          height: 77,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Profile: Erreur chargement image: $error');
                        // Si l'image n'est pas trouvée, afficher un placeholder avec les initiales
                        final initials = _labName?.split(' ').map((n) => n[0]).take(2).join().toUpperCase() ?? 'LY';
                        return Container(
                          width: 77,
                          height: 77,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 77,
                      height: 77,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _labName?.split(' ').map((n) => n[0]).take(2).join().toUpperCase() ?? 'LY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isNotEmpty ? _nameController.text : (_labName ?? ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildIsActiveCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isActive ? AppColors.success : AppColors.textSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isActive ? 'Compte actif' : 'Compte désactivé',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isActive 
                      ? 'Les patients peuvent prendre rendez-vous'
                      : 'Les rendez-vous sont désactivés',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: _isEditing ? (value) {
              setState(() {
                _isActive = value;
              });
            } : null,
            activeThumbColor: AppColors.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations du Centre',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          Icons.business_rounded,
          'Nom du Centre',
          _isEditing ? null : (_nameController.text.isNotEmpty ? _nameController.text : _labName),
          _nameController,
          AppColors.primary,
          onChanged: _onNameChanged,
        ),
        const SizedBox(height: 12),
        _buildLocationField(),
        const SizedBox(height: 12),
        _buildCategoryField(),
        const SizedBox(height: 12),
        _buildInfoItem(
          Icons.phone_rounded,
          'Téléphone',
          _isEditing ? null : _phone,
          _phoneController,
          AppColors.prescription,
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          Icons.email_rounded,
          'Email',
          _isEditing ? null : _email,
          _emailController,
          AppColors.diagnosis,
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String? value, TextEditingController controller, Color iconColor, {Function(String)? onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _isEditing
                    ? TextField(
                        controller: controller,
                        onChanged: onChanged,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      )
                    : Text(
                        value ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildImageUrl(String profilePhotoPath) {
    if (profilePhotoPath.isEmpty) return '';
    
    if (profilePhotoPath.startsWith('http')) {
      return profilePhotoPath;
    } else {
      // Construire l'URL complète en extrayant le nom du fichier
      // Format attendu: /lab/uploads/profiles/filename.png ou uploads/profiles/filename.png
      final filename = profilePhotoPath.split('/').last;
      final imageUrl = '${ApiService.baseUrl}/lab/uploads/profiles/$filename';
      debugPrint('🔵 Profile: Construction URL image: $imageUrl');
      return imageUrl;
    }
  }

  String _normalizeLocation(String location) {
    // Normaliser la localisation pour correspondre exactement à un item du dropdown
    final tunisianCities = [
      'Tunis',
      'Ariana',
      'Ben Arous',
      'Manouba',
      'Bizerte',
      'Nabeul',
      'Zaghouan',
      'Sousse',
      'Monastir',
      'Mahdia',
      'Sfax',
      'Kairouan',
      'Kasserine',
      'Sidi Bouzid',
      'Gafsa',
      'Tozeur',
      'Kebili',
      'Gabès',
      'Médenine',
      'Tataouine',
      'Béja',
      'Jendouba',
      'Le Kef',
      'Siliana',
    ];
    
    // Chercher une correspondance insensible à la casse
    final lowerLocation = location.toLowerCase();
    for (final city in tunisianCities) {
      if (city.toLowerCase() == lowerLocation) {
        return city; // Retourner la version avec la bonne casse
      }
    }
    return location; // Si aucune correspondance, retourner l'original
  }

  Widget _buildLocationField() {
    final tunisianCities = [
      'Tunis',
      'Ariana',
      'Ben Arous',
      'Manouba',
      'Bizerte',
      'Nabeul',
      'Zaghouan',
      'Sousse',
      'Monastir',
      'Mahdia',
      'Sfax',
      'Kairouan',
      'Kasserine',
      'Sidi Bouzid',
      'Gafsa',
      'Tozeur',
      'Kebili',
      'Gabès',
      'Médenine',
      'Tataouine',
      'Béja',
      'Jendouba',
      'Le Kef',
      'Siliana',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Localisation',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _isEditing
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _localisation?.isEmpty ?? true 
                                ? null 
                                : (tunisianCities.contains(_localisation) ? _localisation : null),
                            isExpanded: true,
                            hint: Text(
                              'Sélectionner une ville',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textLight,
                              ),
                            ),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 22),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            dropdownColor: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            items: tunisianCities.map((String city) {
                              return DropdownMenuItem<String>(
                                value: city,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    city,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _localisation = newValue != null ? _normalizeLocation(newValue) : null;
                                _localisationController.text = _localisation ?? '';
                              });
                            },
                          ),
                        ),
                      )
                    : Text(
                        _localisation ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.category_rounded, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catégorie',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _isEditing
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableCategories.map((category) {
                          final isSelected = _categories.contains(category);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _categories.remove(category);
                                } else {
                                  _categories.add(category);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.secondary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.secondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : _categories.isEmpty
                        ? Text(
                            'Aucune catégorie',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((category) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
