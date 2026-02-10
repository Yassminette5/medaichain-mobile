import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
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
    String? gouvernorat,
    String? delegation,
    String? address,
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
        gouvernorat: gouvernorat,
        delegation: delegation,
        address: address,
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

  // Déconnexion
  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }

  // Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
