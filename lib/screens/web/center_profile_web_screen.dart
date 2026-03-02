import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
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
  String? _profileImageUrl;
  PlatformFile? _selectedImageFile;
  bool _isActive = true;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

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
      debugPrint('🔍 Center Profile Web: Chargement du profil...');
      final labProfile = await ApiService.getLabProfile();
      debugPrint('✅ Center Profile Web: Profil récupéré: $labProfile');
      
      if (mounted) {
        setState(() {
          _labName = labProfile['centreName'] ?? labProfile['name'] ?? labProfile['centre_name'] ?? '';
          _localisation = labProfile['localisation'] ?? '';
          
          debugPrint('🔍 Center Profile Web: Nom: $_labName');
          debugPrint('🔍 Center Profile Web: Localisation: $_localisation');
          debugPrint('🔍 Center Profile Web: Catégories brutes: ${labProfile['categorie']}');
          
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
          
          debugPrint('🔍 Center Profile Web: Catégories parsées: $_categories');
          
          _phone = labProfile['phone'] ?? '';
          _email = labProfile['email'] ?? '';
          _isActive = labProfile['isActive'] ?? labProfile['is_active'] ?? true;
          
          // Le backend utilise 'profilePhoto' comme champ principal
          final profilePhotoPath = labProfile['profilePhoto'] ?? 
                                   labProfile['photo'] ?? 
                                   labProfile['photoUrl'] ?? 
                                   labProfile['image'] ?? 
                                   labProfile['imageUrl'] ?? 
                                   labProfile['logo'] ?? 
                                   labProfile['logoUrl'] ?? 
                                   '';
          
          // Construire l'URL complète si c'est un chemin relatif
          if (profilePhotoPath.isNotEmpty) {
            if (profilePhotoPath.startsWith('http')) {
              _profileImageUrl = profilePhotoPath;
            } else {
              // Essayer d'abord la route API qui gère mieux CORS
              // Format: /lab/uploads/profiles/filename.png
              final filename = profilePhotoPath.split('/').last;
              _profileImageUrl = '${ApiService.baseUrl}/lab/uploads/profiles/$filename';
              debugPrint('🔍 Center Profile Web: URL image (route API): $_profileImageUrl');
            }
          } else {
            _profileImageUrl = null;
          }
          
          debugPrint('🔍 Center Profile Web: Téléphone: $_phone');
          debugPrint('🔍 Center Profile Web: Email: $_email');
          debugPrint('🔍 Center Profile Web: Actif: $_isActive');
          debugPrint('🔍 Center Profile Web: ProfilePhotoPath: $profilePhotoPath');
          debugPrint('🔍 Center Profile Web: Image URL finale: $_profileImageUrl');
          
          _nameController.text = _labName ?? '';
          _localisationController.text = _localisation ?? '';
          _phoneController.text = _phone ?? '';
          _emailController.text = _email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Center Profile Web: Erreur: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Erreur de chargement du profil: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final extension = file.extension?.toLowerCase() ?? '';
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        
        // Vérifier l'extension du fichier
        if (!allowedExtensions.contains(extension)) {
          _showErrorSnackBar('Format non supporté. Formats acceptés: JPG, JPEG, PNG, GIF, WEBP');
          return;
        }
        
        setState(() {
          _selectedImageFile = file;
        });
        
        // Uploader l'image immédiatement
        await _uploadImage();
      }
    } catch (e) {
      debugPrint('❌ Center Profile Web: Erreur lors de la sélection de l\'image: $e');
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageFile == null || _selectedImageFile!.bytes == null) {
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      final imageBytes = _selectedImageFile!.bytes!;
      final fileName = _selectedImageFile!.name;
      
      debugPrint('🔍 Center Profile Web: Upload de l\'image...');
      debugPrint('🔍 Center Profile Web: Taille du fichier: ${imageBytes.length} bytes');
      final imageUrl = await ApiService.uploadLabProfilePhoto(imageBytes, fileName);
      
      if (mounted) {
        // Mettre à jour l'URL de l'image immédiatement
        setState(() {
          _profileImageUrl = imageUrl;
          _isUploadingImage = false;
          _selectedImageFile = null;
        });
        
        // Recharger le profil pour avoir les données à jour depuis le backend
        await _loadCenterProfile();
        
        _showSuccessSnackBar('Photo uploadée avec succès');
        debugPrint('✅ Center Profile Web: Image uploadée: $imageUrl');
        debugPrint('✅ Center Profile Web: Image URL après rechargement: $_profileImageUrl');
      }
    } catch (e) {
      debugPrint('❌ Center Profile Web: Erreur lors de l\'upload: $e');
      if (mounted) {
        setState(() => _isUploadingImage = false);
        _showErrorSnackBar('Erreur lors de l\'upload de l\'image: $e');
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
      // Si une nouvelle image a été sélectionnée mais pas encore uploadée, l'uploader d'abord
      if (_selectedImageFile != null && _selectedImageFile!.bytes != null) {
        await _uploadImage();
      }

      // Extraire le chemin relatif si c'est une URL complète
      String? profilePhotoPath;
      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        if (_profileImageUrl!.startsWith('http')) {
          // Extraire le chemin relatif depuis l'URL complète
          final uri = Uri.parse(_profileImageUrl!);
          profilePhotoPath = uri.path;
        } else {
          profilePhotoPath = _profileImageUrl;
        }
      }
      
      final updateData = {
        'centreName': _nameController.text.trim(),
        'localisation': _localisationController.text.trim(),
        'categorie': _categories,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'isActive': _isActive,
        // Inclure le chemin relatif de l'image si elle existe
        if (profilePhotoPath != null && profilePhotoPath.isNotEmpty)
          'profilePhoto': profilePhotoPath,
      };

      await ApiService.updateLabProfile(updateData);
      
      // Recharger le profil pour avoir les données à jour
      await _loadCenterProfile();

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

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/profile_backend.jpg'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
        color: AppColors.surface,
      ),
      child: SingleChildScrollView(
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
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _isEditing = true);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_rounded, size: 22, color: Colors.white),
                            const SizedBox(width: 10),
                            const Text(
                              'Modifier',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.text = _labName ?? '';
                          _localisationController.text = _localisation ?? '';
                          _phoneController.text = _phone ?? '';
                          _emailController.text = _email ?? '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded, size: 20),
                      label: const Text('Annuler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        side: BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        _isSaving ? 'Enregistrement...' : 'Enregistrer',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
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
                    _buildProfileCard(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Catégories d\'analyses'),
                    const SizedBox(height: 20),
                    _buildCategoriesSection(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Colonne droite
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informations complémentaires'),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom du centre',
                      icon: Icons.apartment_rounded,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _localisationController,
                      label: 'Localisation',
                      icon: Icons.place_rounded,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone_in_talk_rounded,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.alternate_email_rounded,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Paramètres'),
                    const SizedBox(height: 20),
                    _buildSwitchTile(
                      title: 'Rendez-vous en ligne',
                      subtitle: 'Permettre aux patients de prendre rendez-vous en ligne',
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

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Image de profil
          Stack(
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _isUploadingImage
                      ? Container(
                          color: Colors.white.withValues(alpha: 0.2),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : (_selectedImageFile != null && _selectedImageFile!.bytes != null)
                          ? Image.memory(
                              Uint8List.fromList(_selectedImageFile!.bytes!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                            )
                          : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                              ? Image.network(
                                  '$_profileImageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                  fit: BoxFit.cover,
                                  cacheWidth: 320,
                                  cacheHeight: 320,
                                  headers: const {
                                    'Accept': 'image/*',
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Container(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('❌ Profile Card: Erreur chargement image: $error');
                                    debugPrint('❌ Profile Card: URL: $_profileImageUrl');
                                    
                                    // Fallback : essayer la route API alternative
                                    if (_profileImageUrl != null && _profileImageUrl!.contains('/uploads/lab-profiles/')) {
                                      final filename = _profileImageUrl!.split('/').last.split('?').first;
                                      final alternativeUrl = '${ApiService.baseUrl}/lab/uploads/profiles/$filename';
                                      debugPrint('­ƒöä Profile Card: Tentative route API: $alternativeUrl');
                                      return Image.network(
                                        '$alternativeUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                        fit: BoxFit.cover,
                                        cacheWidth: 320,
                                        cacheHeight: 320,
                                        headers: const {
                                          'Accept': 'image/*',
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildDefaultAvatar();
                                        },
                                      );
                                    }
                                    
                                    return _buildDefaultAvatar();
                                  },
                                )
                              : _buildDefaultAvatar(),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      onTap: _isUploadingImage ? null : _pickImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: _isUploadingImage
                            ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 28),
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _labName ?? 'Centre d\'Analyses',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
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
          const Text(
            'Photo du profil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Aperçu de l'image
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: _isUploadingImage
                          ? Container(
                              color: AppColors.background,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : (_selectedImageFile != null && _selectedImageFile!.bytes != null)
                              ? Image.memory(
                                  Uint8List.fromList(_selectedImageFile!.bytes!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('❌ Profile Card: Erreur chargement image: $error');
                                    debugPrint('❌ Profile Card: URL: $_profileImageUrl');
                                    
                                    // Fallback : essayer la route API alternative
                                    if (_profileImageUrl != null && _profileImageUrl!.contains('/uploads/lab-profiles/')) {
                                      final filename = _profileImageUrl!.split('/').last.split('?').first;
                                      final alternativeUrl = '${ApiService.baseUrl}/lab/uploads/profiles/$filename';
                                      debugPrint('­ƒöä Profile Card: Tentative route API: $alternativeUrl');
                                      return Image.network(
                                        '$alternativeUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                        fit: BoxFit.cover,
                                        cacheWidth: 320,
                                        cacheHeight: 320,
                                        headers: const {
                                          'Accept': 'image/*',
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildDefaultAvatar();
                                        },
                                      );
                                    }
                                    
                                    return _buildDefaultAvatar();
                                  },
                                )
                              : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                                  ? Image.network(
                                      '$_profileImageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                      fit: BoxFit.cover,
                                      cacheWidth: 240,
                                      cacheHeight: 240,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          color: AppColors.background,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('❌ Center Profile Web: Erreur chargement image: $error');
                                        debugPrint('❌ Center Profile Web: StackTrace: $stackTrace');
                                        debugPrint('❌ Center Profile Web: URL: $_profileImageUrl');
                                        
                                        // Fallback : essayer la route API alternative si disponible
                                        if (_profileImageUrl!.contains('/uploads/lab-profiles/')) {
                                          final filename = _profileImageUrl!.split('/').last.split('?').first;
                                          final alternativeUrl = '${ApiService.baseUrl}/lab/uploads/profiles/$filename';
                                          debugPrint('­ƒöä Center Profile Web: Tentative avec route API alternative: $alternativeUrl');
                                          return Image.network(
                                            '$alternativeUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                            fit: BoxFit.cover,
                                            cacheWidth: 240,
                                            cacheHeight: 240,
                                            headers: const {
                                              'Accept': 'image/*',
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              debugPrint('❌ Center Profile Web: Erreur route API alternative: $error');
                                              return _buildDefaultAvatar();
                                            },
                                          );
                                        }
                                        
                                        return _buildDefaultAvatar();
                                      },
                                    )
                                  : _buildDefaultAvatar(),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _isUploadingImage ? null : _pickImage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: _isUploadingImage
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing) ...[
                      ElevatedButton.icon(
                        onPressed: _isUploadingImage ? null : _pickImage,
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text('Changer la photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Formats acceptés: JPG, JPEG, PNG, GIF, WEBP',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aucune limite de taille',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.local_hospital_rounded,
        size: 60,
        color: Colors.white,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? AppColors.primary.withValues(alpha: 0.2) : AppColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          readOnly: !enabled,
          inputFormatters: keyboardType == TextInputType.phone
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: TextStyle(
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: enabled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.5),
              size: 22,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ),
    );
    

  }

  Widget _buildCategoriesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
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
          if (_categories.isEmpty && !_isEditing)
            Text(
              'Aucune catégorie enregistrée',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _isEditing
                  ? _availableCategories.map((category) {
                      final isSelected = _categories.contains(category);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _categories.remove(category);
                              } else {
                                _categories.add(category);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList()
                  : _categories.map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }
}
