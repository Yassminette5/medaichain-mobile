import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/doctor_profile_model.dart';

class ApiService {
  // Changez cette URL pour votre backend
  static const String baseUrl = 'http://10.0.2.2:3000'; // Pour émulateur Android
  // static const String baseUrl = 'http://localhost:3000'; // Pour iOS/Web

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // ========== INSCRIPTION ==========
  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? fullName,
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
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'phone': phone,
      'role': role.value,
    };

    if (fullName != null) body['fullName'] = fullName;
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (speciality != null) body['speciality'] = speciality;
    if (hospital != null) body['hospital'] = hospital;
    if (licenseNumber != null) body['licenseNumber'] = licenseNumber;
    if (centreName != null) body['centreName'] = centreName;
    if (categorie != null) body['categorie'] = categorie;
    if (localisation != null) body['localisation'] = localisation;
    if (wilaya != null) body['wilaya'] = wilaya;
    if (pharmacyName != null) body['pharmacyName'] = pharmacyName;
    if (ownerName != null) body['ownerName'] = ownerName;
    if (gouvernorat != null) body['gouvernorat'] = gouvernorat;
    if (delegation != null) body['delegation'] = delegation;
    if (address != null) body['address'] = address;
    if (yearsOfExperience != null) body['yearsOfExperience'] = yearsOfExperience;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
      await _saveUser(authResponse.user);
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'inscription');
    }
  }

  // ========== CONNEXION ==========
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
      await _saveUser(authResponse.user);
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Email ou mot de passe incorrect');
    }
  }

  // ========== MOT DE PASSE OUBLIÉ ==========
  static Future<String> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur');
    }
  }

  // ========== RÉINITIALISER MOT DE PASSE ==========
  static Future<String> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de réinitialisation');
    }
  }

  // ========== RAFRAÎCHIR TOKEN ==========
  static Future<void> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (refreshToken == null) {
      throw Exception('Non connecté');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveTokens(data['accessToken'], data['refreshToken']);
    } else {
      await logout();
      throw Exception('Session expirée');
    }
  }

  // ========== PROFIL UTILISATEUR ==========
  static Future<User> getProfile() async {
    final token = await getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 401) {
      // Token expiré, essayer de rafraîchir
      await refreshToken();
      return getProfile();
    } else {
      throw Exception('Erreur de récupération du profil');
    }
  }

  // ========== PROFIL MÉDECIN (détaillé) ==========
  static Future<DoctorProfile?> getDoctorProfile() async {
    final token = await getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/profiles/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) return null;
      return DoctorProfile.fromJson(data);
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getDoctorProfile();
    } else {
      return null;
    }
  }

  // ========== METTRE À JOUR LE PROFIL PATIENT ==========
  static Future<User> updatePatientInformation({
    String? fullName,
    required String gender,
    required int age,
    required int height,
    required int weight,
    required List<String> allergies,
  }) async {
    final token = await getAccessToken();

    final body = {
      'gender': gender.trim().toLowerCase(),
      'age': age,
      'height': height,
      'weight': weight,
      'allergies': allergies,
    };

    if (fullName != null) body['fullName'] = fullName;

    final response = await http.put(
      Uri.parse('$baseUrl/profiles/patient'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final updatedUser = User.fromJson(data);
      await _saveUser(updatedUser);
      return updatedUser;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return updatePatientInformation(
        fullName: fullName,
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        allergies: allergies,
      );
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de mise à jour du profil');
    }
  }

  // ========== ANCIENNE MÉTHODE (deprecated) ==========
  static Future<void> updatePatientProfile({
    required String firstName,
    required String lastName,
    String? gender,
    int? age,
    int? height,
    int? weight,
    List<String>? allergies,
  }) async {
    final token = await getAccessToken();

    final body = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
    };
    if (gender != null) body['gender'] = gender.toLowerCase();
    if (height != null) body['height'] = height;
    if (weight != null) body['weight'] = weight;
    if (allergies != null) body['allergies'] = allergies;
    // Calculate approximate dateOfBirth from age
    if (age != null) {
      final dob = DateTime(DateTime.now().year - age, 1, 1);
      body['dateOfBirth'] = dob.toIso8601String();
    }

    final response = await http.put(
      Uri.parse('$baseUrl/profiles/patient'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await refreshToken();
      return updatePatientProfile(
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        allergies: allergies,
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur de mise à jour du profil patient');
    }
  }

  // ========== COMPLÉTER LE PROFIL ==========
  static Future<void> completeProfile() async {
    final token = await getAccessToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/complete-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur');
    }
  }

  // ========== DÉCONNEXION ==========
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  // ========== MÉDICAMENTS ==========
  static Future<List<dynamic>> getAllMedicines() async {
    final token = await getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/medicines'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getAllMedicines();
    } else {
      throw Exception('Erreur de récupération des médicaments');
    }
  }

  static Future<Map<String, dynamic>> createMedicine(Map<String, dynamic> data) async {
    final token = await getAccessToken();

    final response = await http.post(
      Uri.parse('$baseUrl/medicines'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return createMedicine(data);
    } else {
      throw Exception('Erreur de création du médicament');
    }
  }

  static Future<void> deleteMedicine(String id) async {
    final token = await getAccessToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/medicines/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return deleteMedicine(id);
    } else {
      throw Exception('Erreur de suppression du médicament');
    }
  }

  // ========== CALENDAR / AGENDA EVENTS ==========

  static Future<List<Map<String, dynamic>>> getCalendarEvents() async {
    final token = await getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getCalendarEvents();
    } else {
      throw Exception('Erreur de chargement des événements');
    }
  }

  static Future<Map<String, dynamic>> createCalendarEvent(Map<String, dynamic> eventData) async {
    final token = await getAccessToken();

    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await refreshToken();
      return createCalendarEvent(eventData);
    } else {
      throw Exception('Erreur de création de l\'événement');
    }
  }

  static Future<Map<String, dynamic>> updateCalendarEvent(String id, Map<String, dynamic> eventData) async {
    final token = await getAccessToken();

    final response = await http.put(
      Uri.parse('$baseUrl/appointments/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await refreshToken();
      return updateCalendarEvent(id, eventData);
    } else {
      throw Exception('Erreur de mise à jour de l\'événement');
    }
  }

  static Future<void> deleteCalendarEvent(String id) async {
    final token = await getAccessToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/appointments/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return deleteCalendarEvent(id);
    } else {
      throw Exception('Erreur de suppression de l\'événement');
    }
  }

  // ========== PATIENTS ==========

  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final token = await getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/profiles/patients'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getAllPatients();
    } else {
      throw Exception('Erreur de chargement des patients');
    }
  }

  // ========== NOTIFICATIONS ==========

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getNotifications();
    } else {
      throw Exception('Erreur de chargement des notifications');
    }
  }

  static Future<Map<String, dynamic>> getUnreadNotificationsCount() async {
    final token = await getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getUnreadNotificationsCount();
    } else {
      throw Exception('Erreur de chargement du compteur');
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    final token = await getAccessToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      await refreshToken();
      return markNotificationAsRead(notificationId);
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur de mise à jour de la notification');
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    final token = await getAccessToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      await refreshToken();
      return markAllNotificationsAsRead();
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur de mise à jour des notifications');
    }
  }

  // ========== HELPERS ==========
  static Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode({
      'id': user.id,
      'email': user.email,
      'phone': user.phone,
      'role': user.role.value,
      'isEmailVerified': user.isEmailVerified,
      'isProfileCompleted': user.isProfileCompleted,
      'isActive': user.isActive,
      'fullName': user.fullName,
      'gender': user.gender,
      'age': user.age,
      'height': user.height,
      'weight': user.weight,
      'allergies': user.allergies,
      'createdAt': user.createdAt.toIso8601String(),
    }));
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }
}
