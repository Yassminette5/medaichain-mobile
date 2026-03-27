import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/doctor_profile_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  DoctorProfile? _doctorProfile;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  DoctorProfile? get doctorProfile => _doctorProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isProfileCompleted => _user?.isProfileCompleted ?? false;

  // Initialiser - vérifier si déjà connecté
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedUser = await ApiService.getSavedUser();

      // Attempt to fetch fresh profile
      User? fetchedUser;
      try {
        fetchedUser = await ApiService.getProfile();
      } catch (e) {
        // If fetch fails but we have saved user, use saved user
        if (savedUser != null) {
          _user = savedUser;
        }
      }

      if (fetchedUser != null) {
        debugPrint('[AuthProvider] Fetched user from API: ${fetchedUser.fullName}, role: ${fetchedUser.role}');
        // Merge strategy: Use fetched user but fall back to saved user for missing profile fields
        // This handles cases where backend doesn't yet return the new fields
        _user = User(
          id: fetchedUser.id,
          email: fetchedUser.email,
          phone: fetchedUser.phone,
          role: fetchedUser.role,
          isEmailVerified: fetchedUser.isEmailVerified,
          isProfileCompleted: fetchedUser.isProfileCompleted || (savedUser?.isProfileCompleted ?? false),
          isActive: fetchedUser.isActive,
          createdAt: fetchedUser.createdAt,
          lastLoginAt: fetchedUser.lastLoginAt,
          fullName: fetchedUser.fullName ?? savedUser?.fullName,
          gender: fetchedUser.gender ?? savedUser?.gender,
          age: fetchedUser.age ?? savedUser?.age,
          height: fetchedUser.height ?? savedUser?.height,
          weight: fetchedUser.weight ?? savedUser?.weight,
          allergies: (fetchedUser.allergies != null && fetchedUser.allergies!.isNotEmpty)
              ? fetchedUser.allergies
              : savedUser?.allergies,
        );
        debugPrint('[AuthProvider] Merged user fullName: ${_user?.fullName}');
      } else if (savedUser != null) {
        _user = savedUser;
      }

      // Modifier: If we have a user, check for doctor profile
      if (_user?.role == UserRole.medecin) {
        await fetchDoctorProfile();
      }

      // Initialize notifications if user is logged in
      if (_user != null) {
        try {
          await NotificationService().init();
        } catch (e) {
          debugPrint('❌ Failed to initialize notifications: $e');
        }
      }
    } catch (e) {
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Inscription
  Future<bool> register({
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? fullName,
    String? speciality,
    String? hospital,
    String? licenseNumber,
    String? centreName,
    String? categorie,
    String? localisation,
    String? wilaya,
    String? pharmacyName,
    String? ownerName,
    String? gouvernorat,
    String? delegation,
    String? address,
    int? yearsOfExperience,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.register(
        email: email,
        password: password,
        phone: phone,
        role: role,
        fullName: fullName,
        speciality: speciality,
        hospital: hospital,
        licenseNumber: licenseNumber,
        centreName: centreName,
        categorie: categorie,
        localisation: localisation,
        wilaya: wilaya,
        pharmacyName: pharmacyName,
        ownerName: ownerName,
        gouvernorat: gouvernorat,
        delegation: delegation,
        address: address,
        yearsOfExperience: yearsOfExperience,
      );
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Connexion
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      _user = response.user;
      // Charger le profil médecin si applicable
      if (_user?.role == UserRole.medecin) {
        await fetchDoctorProfile();
      }

      // Initialize notifications after successful login
      try {
        await NotificationService().init();
      } catch (e) {
        debugPrint('❌ Failed to initialize notifications after login: $e');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mot de passe oublié
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Compléter le profil
  Future<void> completeProfile() async {
    try {
      await ApiService.completeProfile();
      _user = await ApiService.getProfile();
      notifyListeners();
    } catch (e) {
      // Ignorer
    }
  }

  // Mettre à jour les informations patient
  Future<bool> updatePatientInformation({
    String? fullName,
    required String gender,
    required int age,
    required int height,
    required int weight,
    required List<String> allergies,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await ApiService.updatePatientInformation(
        fullName: fullName,
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        allergies: allergies,
      );
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Récupérer le profil médecin
  Future<void> fetchDoctorProfile() async {
    try {
      _doctorProfile = await ApiService.getDoctorProfile();
      notifyListeners();
    } catch (e) {
      _doctorProfile = null;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    _doctorProfile = null;
    notifyListeners();
  }

  // Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Définir l'utilisateur (pour completeInvite)
  void setUser(User user) {
    _user = user;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
