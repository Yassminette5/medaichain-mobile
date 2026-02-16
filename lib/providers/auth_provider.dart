import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/doctor_profile_model.dart';
import '../services/api_service.dart';

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
      if (savedUser != null) {
        // Vérifier si le token est encore valide
        _user = await ApiService.getProfile();
        // Charger le profil médecin si applicable
        if (_user?.role == UserRole.medecin) {
          await fetchDoctorProfile();
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
    String? firstName,
    String? lastName,
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
        firstName: firstName,
        lastName: lastName,
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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );
      _user = response.user;
      // Charger le profil médecin si applicable
      if (_user?.role == UserRole.medecin) {
        await fetchDoctorProfile();
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
}
