import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/doctor_profile_model.dart';

class ApiService {
  /// Override pour test sur téléphone réel : mets l'IP de ton PC (ex: 'http://192.168.1.10:3000').
  /// Sur émulateur, ne pas définir (baseUrl utilise 10.0.2.2).
  static String? backendUrlOverride;

  /// Base URL backend:
  /// - Si [backendUrlOverride] est défini (téléphone réel) : l'utiliser.
  /// - Web: 127.0.0.1
  /// - Android émulateur: 10.0.2.2 (machine hôte)
  /// - Téléphone réel: définir backendUrlOverride dans main.dart avec l'IP du PC (même WiFi).
  static String get baseUrl {
    if (backendUrlOverride != null && backendUrlOverride!.trim().isNotEmpty) {
      String url = backendUrlOverride!.trim();
      if (!url.startsWith('http')) url = 'http://$url';
      if (!url.contains(':3000') && !url.contains(':')) url = '$url:3000';
      return url;
    }
    if (kIsWeb) return 'http://127.0.0.1:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://127.0.0.1:3000';
  }

  /// Supprimer des documents OCR (liste d'IDs)
  /// Backend: DELETE /patient/ocr/documents  body: { ids: [...] }
  static Future<bool> deleteOcrDocuments(List<String> ids) async {
    if (ids.isEmpty) return true;
    final token = await getAccessToken();
    final url = '$baseUrl/patient/ocr/documents';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'ids': ids}),
    );
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    if (response.statusCode == 401) {
      await refreshToken();
      return deleteOcrDocuments(ids);
    }
    return false;
  }

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';

  // En mode "rememberMe = false", on garde la session uniquement en mémoire (valable jusqu’à fermeture de l’app)
  static String? _memAccessToken;
  static String? _memRefreshToken;
  static User? _memUser;

  static Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);

    if (!value) {
      // Si l'utilisateur ne veut pas être mémorisé: supprimer toute session persistée
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);
    }
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_rememberMeKey);
    if (v != null) return v;

    // Compat: si des tokens existent déjà (ancienne version), considérer rememberMe=true
    return prefs.containsKey(_accessTokenKey) || prefs.containsKey(_refreshTokenKey) || prefs.containsKey(_userKey);
  }

  /// À appeler au démarrage: si rememberMe=false, on purge les tokens persistés.
  static Future<void> enforceRememberPolicyOnStartup() async {
    final remember = await getRememberMe();
    if (!remember) {
      await logout();
    }
  }

  // ========== COMPLÉTER INVITATION ==========
  static Future<AuthResponse> completeInvite({
    required String token,
    required String email,
    required String password,
    required String phone,
    String? firstName,
    String? lastName,
    String? speciality,
    String? centreName,
    String? categorie,
    String? localisation,
    String? pharmacyName,
    String? gouvernorat,
    String? delegation,
    String? address,
  }) async {
    final Map<String, dynamic> body = {
      'token': token,
      'email': email,
      'password': password,
      'phone': phone,
    };

    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (speciality != null) body['speciality'] = speciality;
    if (centreName != null) body['centreName'] = centreName;
    if (categorie != null) body['categorie'] = categorie;
    if (localisation != null) body['localisation'] = localisation;
    if (pharmacyName != null) body['pharmacyName'] = pharmacyName;
    if (gouvernorat != null) body['gouvernorat'] = gouvernorat;
    if (delegation != null) body['delegation'] = delegation;
    if (address != null) body['address'] = address;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/complete-invite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      // Pour complete-invite: on persiste la session (flow d'inscription)
      await setRememberMe(true);
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken, persist: true);
      await _saveUser(authResponse.user, persist: true);
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de la finalisation de l\'invitation');
    }
  }

  // ========== INSCRIPTION ==========
  static Future<AuthResponse> register({
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
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'phone': phone,
      'role': role.value,
    };

    if (fullName != null) body['fullName'] = fullName;
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
      // Inscription: on persiste la session
      await setRememberMe(true);
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken, persist: true);
      await _saveUser(authResponse.user, persist: true);
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
    bool rememberMe = true,
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
      await setRememberMe(rememberMe);
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken, persist: rememberMe);
      await _saveUser(authResponse.user, persist: rememberMe);
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
    final refreshToken = prefs.getString(_refreshTokenKey) ?? _memRefreshToken;

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
      final remember = await getRememberMe();
      await _saveTokens(data['accessToken'], data['refreshToken'], persist: remember);
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
      debugPrint('[ApiService] Profile raw response: ${response.body}');
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

  // ========== PROFIL PATIENT (informations) ==========
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

    // 1. Send update to Backend
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
      
      // 2. Save to SharedPreferences
      final remember = await getRememberMe();
      await _saveUser(updatedUser, persist: remember);
      return updatedUser;
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
    _memAccessToken = null;
    _memRefreshToken = null;
    _memUser = null;
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

  static Future<List<Map<String, dynamic>>> getCalendarEventsByMonth({required int year, required int month}) async {
    final token = await getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/appointments/month?year=$year&month=$month'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 404) {
      // Fallback si l'endpoint spécifique n'existe pas
      final allEvents = await getCalendarEvents();
      return allEvents.where((e) {
        if (e['date'] == null) return false;
        try {
          final d = DateTime.parse(e['date'].toString());
          return d.year == year && d.month == month;
        } catch (_) {
          return false;
        }
      }).toList();
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getCalendarEventsByMonth(year: year, month: month);
    } else {
      throw Exception('Erreur de chargement des événements du mois');
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
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de création de l\'événement');
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
    if (token == null || token.isEmpty) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profiles/patients'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = response.body.trim();
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'];
        list = data is List ? data : [];
      } else {
        list = [];
      }
      return list.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getAllPatients();
    } else {
      debugPrint('[ApiService] getAllPatients: ${response.statusCode} ${response.body}');
      String msg = 'Erreur de chargement des patients';
      if (response.statusCode == 403) msg = 'Accès refusé aux patients.';
      else if (response.statusCode == 404) msg = 'Endpoint patients non disponible.';
      else if (response.statusCode >= 500) msg = 'Serveur indisponible. Réessayez plus tard.';
      throw Exception(msg);
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

    final response = await http.put(
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

    final response = await http.put(
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

  // ========== RECHERCHE MÉDECINS (public) ==========
  static Future<List<Map<String, dynamic>>> searchDoctors({
    String? speciality,
    String? city,
    String? wilaya,
  }) async {
    final query = <String, String>{};
    if (speciality != null && speciality.isNotEmpty) query['speciality'] = speciality;
    if (city != null && city.isNotEmpty) query['city'] = city;
    if (wilaya != null && wilaya.isNotEmpty) query['wilaya'] = wilaya;
    final uri = Uri.parse('$baseUrl/profiles/doctors/search').replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Erreur recherche médecins');
    final data = jsonDecode(response.body);
    return data is List ? data.cast<Map<String, dynamic>>() : [];
  }

  // ========== DEMANDES D'ACCÈS (patient → médecin) ==========
  static Future<Map<String, dynamic>> createAccessRequest({
    required String doctorId,
    required String reason,
    String urgency = 'normal',
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) throw Exception('Session expirée');
    final response = await http.post(
      Uri.parse('$baseUrl/access-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'doctorId': doctorId, 'reason': reason, 'urgency': urgency}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      await refreshToken();
      return createAccessRequest(doctorId: doctorId, reason: reason, urgency: urgency);
    }
    if (response.statusCode == 403) {
      final body = jsonDecode(response.body);
      final msg = body is Map ? (body['message'] ?? 'Réservé aux patients. Connectez-vous avec un compte patient.') : 'Réservé aux patients. Connectez-vous avec un compte patient.';
      throw Exception(msg);
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Erreur création demande');
  }

  static Future<List<Map<String, dynamic>>> getAccessRequestsForDoctor() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) throw Exception('Session expirée');
    final response = await http.get(
      Uri.parse('$baseUrl/access-requests/for-doctor'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data.cast<Map<String, dynamic>>() : [];
    }
    if (response.statusCode == 401) {
      await refreshToken();
      return getAccessRequestsForDoctor();
    }
    throw Exception('Erreur chargement demandes');
  }

  /// Liste des patients dont le médecin a accepté la demande d'accès (pour afficher dossier + analyses).
  static Future<List<Map<String, dynamic>>> getAcceptedPatientsForDoctor() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) throw Exception('Session expirée');
    final response = await http.get(
      Uri.parse('$baseUrl/access-requests/for-doctor/accepted'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data.cast<Map<String, dynamic>>() : [];
    }
    if (response.statusCode == 401) {
      await refreshToken();
      return getAcceptedPatientsForDoctor();
    }
    return [];
  }

  static Future<void> acceptAccessRequest(String id, {String duration = '24 heures'}) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) throw Exception('Session expirée');
    final response = await http.patch(
      Uri.parse('$baseUrl/access-requests/$id/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'duration': duration}),
    );
    if (response.statusCode == 200) return;
    if (response.statusCode == 401) {
      await refreshToken();
      return acceptAccessRequest(id, duration: duration);
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Erreur');
  }

  static Future<void> refuseAccessRequest(String id) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) throw Exception('Session expirée');
    final response = await http.patch(
      Uri.parse('$baseUrl/access-requests/$id/refuse'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return;
    if (response.statusCode == 401) {
      await refreshToken();
      return refuseAccessRequest(id);
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Erreur');
  }

  // ========== APPEL VIDÉO (Agora) ==========
  /// Récupère un token pour rejoindre un canal vidéo (médecin ou patient).
  /// Construit le nom de canal pour un appel médecin-patient (même ordre que le backend).
  static String videoCallChannelName(String doctorId, String patientId) {
    final ids = [doctorId, patientId]..sort();
    return 'medaichain-${ids[0]}-${ids[1]}';
  }

  /// [channelName] ex: medaichain-{doctorId}-{patientId}
  static Future<Map<String, dynamic>> getVideoCallToken(String channelName) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) throw Exception('Session expirée');
    final uri = Uri.parse('$baseUrl/video-call/token').replace(queryParameters: {'channelName': channelName});
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      await refreshToken();
      return getVideoCallToken(channelName);
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Erreur token vidéo');
  }

  // ========== HELPERS ==========
  static Future<void> _saveTokens(String accessToken, String refreshToken, {required bool persist}) async {
    // Toujours mettre en mémoire pour la session courante
    _memAccessToken = accessToken;
    _memRefreshToken = refreshToken;

    if (!persist) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> _saveUser(User user, {required bool persist}) async {
    _memUser = user;
    if (!persist) return;

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
    return prefs.getString(_accessTokenKey) ?? _memAccessToken;
  }

  static Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return _memUser;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }



  // ================= CLINIQUE DYNAMIQUE =================
  static String? _cachedClinicId;

  static Future<Map<String, String>> _getClinicHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static String _extractHttpErrorMessage(http.Response response, {String? fallback}) {
    try {
      final data = json.decode(response.body);
      if (data is Map && data['message'] != null) return data['message'].toString();
    } catch (_) {}
    return fallback ?? 'Erreur (${response.statusCode})';
  }

  static Future<String> _getClinicId() async {
    if (_cachedClinicId != null) return _cachedClinicId!;
    try {
      final headers = await _getClinicHeaders();
      final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/mine'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedClinicId = data['_id'];
        return _cachedClinicId!;
      }
    } catch (e) {
    }
    throw Exception('Non autorisé ou pas de clinique associée');
  }
  
  static void clearClinicCache() {
    _cachedClinicId = null;
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/dashboard'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load dashboard stats');
  }

  static Future<Map<String, dynamic>> getClinicProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load clinic');
  }

  static Future<void> updateClinicProfile(Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}'), headers: await _getClinicHeaders(), body: json.encode(data));
    if (response.statusCode != 200) throw Exception('Failed to update clinic');
  }

  static Future<List<dynamic>> getAvailableDoctors() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/doctors/available'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load available doctors');
  }

  static Future<List<dynamic>> getDoctorsByClinic() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/doctors'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load doctors');
  }

  static Future<void> addDoctor(String doctorId, String fullName, String email, String speciality) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/doctors'),
      headers: await _getClinicHeaders(),
      body: json.encode({'doctorId': doctorId, 'fullName': fullName, 'email': email, 'speciality': speciality}),
    );
    if (response.statusCode != 201) throw Exception(json.decode(response.body)['message'] ?? 'Failed to add doctor');
  }

  static Future<void> changeDoctorStatus(String clinicDoctorId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/clinic-management/doctors/$clinicDoctorId'),
      headers: await _getClinicHeaders(),
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update doctor');
  }

  static Future<void> removeDoctor(String clinicDoctorId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clinic-management/doctors/$clinicDoctorId'), headers: await _getClinicHeaders());
    if (response.statusCode != 200) throw Exception('Failed to remove doctor');
  }

  static Future<List<dynamic>> getAdmissions() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/admissions'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load admissions');
  }

  static String generateObjectId() {
    final now = DateTime.now();
    final timestamp = (now.millisecondsSinceEpoch ~/ 1000).toRadixString(16).padLeft(8, '0');
    final random = List.generate(16, (_) => (DateTime.now().microsecond % 16).toRadixString(16)).join();
    return (timestamp + random).substring(0, 24);
  }

  static Future<void> createAdmission({
    required String patientName,
    required String reason,
    String? patientPhone,
    String? doctorId,
    String? notes,
  }) async {
    final body = <String, dynamic>{'patientId': generateObjectId(), 'patientName': patientName, 'reason': reason};
    if (patientPhone != null && patientPhone.isNotEmpty) body['patientPhone'] = patientPhone;
    if (doctorId != null && doctorId.isNotEmpty) body['doctorId'] = doctorId;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await http.post(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/admissions'), headers: await _getClinicHeaders(), body: json.encode(body));
    if (response.statusCode != 201) throw Exception('Failed to create admission');
  }

  static Future<void> updateAdmission({
    required String admissionId,
    String? patientName,
    String? patientPhone,
    String? reason,
    String? status,
    String? doctorId,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (patientName != null) body['patientName'] = patientName;
    if (patientPhone != null) body['patientPhone'] = patientPhone;
    if (reason != null) body['reason'] = reason;
    if (status != null) body['status'] = status;
    if (doctorId != null) body['doctorId'] = doctorId;
    if (notes != null) body['notes'] = notes;

    final response = await http.put(Uri.parse('$baseUrl/clinic-management/admissions/$admissionId'), headers: await _getClinicHeaders(), body: json.encode(body));
    if (response.statusCode != 200) throw Exception('Failed to update admission');
  }

  static Future<void> deleteAdmission(String admissionId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clinic-management/admissions/$admissionId'), headers: await _getClinicHeaders());
    if (response.statusCode != 200) throw Exception('Failed to delete admission');
  }

  static Future<List<dynamic>> getAppointments() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/appointments'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load appointments');
  }

  // Version pour clinique (paramètres nommés)
  static Future<void> createAppointment({
    required String doctorId,
    required String date,
    required String timeSlot,
    String? reason,
    String? patientName,
    String? doctorName,
  }) async {
    final body = <String, dynamic>{'doctorId': doctorId, 'patientId': generateObjectId(), 'date': date, 'timeSlot': timeSlot};
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    if (patientName != null && patientName.isNotEmpty) body['patientName'] = patientName;
    if (doctorName != null && doctorName.isNotEmpty) body['doctorName'] = doctorName;

    final response = await http.post(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/appointments'), headers: await _getClinicHeaders(), body: json.encode(body));
    if (response.statusCode != 201) throw Exception('Failed to create appointment');
  }

  // Version pour centres d'analyse (patient) — POST /lab-appointments
  // Retourne l'objet RDV créé (incluant désormais `status`: accepted|pending|rejected)
  static Future<Map<String, dynamic>> createLabAppointment(Map<String, dynamic> appointmentData) async {
    final token = await getAccessToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl/lab-appointments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(appointmentData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['appointment'] is Map) {
            return Map<String, dynamic>.from(data['appointment'] as Map);
          }
          if (data['data'] is Map) {
            return Map<String, dynamic>.from(data['data'] as Map);
          }
          return data;
        }
      } catch (_) {
        // Certains backends peuvent répondre vide même en 201; on renvoie un fallback exploitable
      }
      return Map<String, dynamic>.from(appointmentData);
    } else if (response.statusCode == 401) {
      await refreshToken();
      return createLabAppointment(appointmentData);
    } else {
      // Essayer d'extraire un message d'erreur utile (souvent validation => 400)
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final errorData = Map<String, dynamic>.from(decoded);
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              errorData['statusMessage'] ??
              (errorData['errors']?.toString()) ??
              'Erreur de création du rendez-vous';
          throw Exception(errorMessage.toString());
        }
        throw Exception(decoded.toString());
      } catch (e) {
        // Si le backend renvoie du texte/HTML, garder un extrait pour debug
        final body = response.body.toString();
        final snippet = body.length > 400 ? '${body.substring(0, 400)}…' : body;
        debugPrint('[ApiService] createLabAppointment failed: ${response.statusCode} body=$snippet');
        if (e is Exception && e.toString().contains('Erreur')) {
          rethrow;
        }
        throw Exception('Erreur de création du rendez-vous (${response.statusCode})${snippet.trim().isNotEmpty ? ': $snippet' : ''}');
      }
    }
  }

  /// Liste des RDV du patient connecté — GET /lab-appointments/my
  static Future<List<Map<String, dynamic>>> getMyLabAppointments() async {
    final token = await getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/lab-appointments/my'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      if (data is Map && data['appointments'] != null) {
        return List<Map<String, dynamic>>.from(data['appointments']);
      }
      if (data is Map && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getMyLabAppointments();
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ??
            errorData['error'] ??
            errorData['statusMessage'] ??
            'Erreur de récupération des rendez-vous';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) rethrow;
        throw Exception('Erreur de récupération des rendez-vous: ${response.statusCode}');
      }
    }
  }

  /// Détails d'un RDV de labo (patient) — GET /lab-appointments/:id
  /// Si l'endpoint n'existe pas côté backend, on tentera un fallback via /lab-appointments/my.
  static Future<Map<String, dynamic>> getLabAppointmentById(String appointmentId) async {
    final token = await getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/lab-appointments/$appointmentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        if (data['appointment'] is Map) return Map<String, dynamic>.from(data['appointment'] as Map);
        if (data['data'] is Map) return Map<String, dynamic>.from(data['data'] as Map);
        return data;
      }
      throw Exception('Réponse invalide pour les détails du rendez-vous');
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getLabAppointmentById(appointmentId);
    } else {
      // Fallback: chercher dans la liste /my
      try {
        final list = await getMyLabAppointments();
        final found = list.firstWhere(
          (e) => (e['_id']?.toString() ?? e['id']?.toString()) == appointmentId,
          orElse: () => <String, dynamic>{},
        );
        if (found.isNotEmpty) return found;
      } catch (_) {}

      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ??
            errorData['error'] ??
            errorData['statusMessage'] ??
            'Erreur de chargement du rendez-vous';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) rethrow;
        throw Exception('Erreur de chargement du rendez-vous: ${response.statusCode}');
      }
    }
  }

  static Future<void> updateAppointment({
    required String appointmentId,
    String? status,
    String? date,
    String? timeSlot,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (date != null) body['date'] = date;
    if (timeSlot != null) body['timeSlot'] = timeSlot;
    if (notes != null) body['notes'] = notes;

    final response = await http.put(Uri.parse('$baseUrl/clinic-management/appointments/$appointmentId'), headers: await _getClinicHeaders(), body: json.encode(body));
    if (response.statusCode != 200) throw Exception('Failed to update appointment');
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clinic-management/appointments/$appointmentId'), headers: await _getClinicHeaders());
    if (response.statusCode != 200) throw Exception('Failed to delete appointment');
  }



  // ========== ADMISSIONS FILTRÉES ==========
  static Future<List<dynamic>> getAdmissionsByDate(String date) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/admissions?date=$date'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load admissions');
  }

  static Future<List<dynamic>> getAdmissionsByStatus(String status) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/admissions?status=$status'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load admissions');
  }

  // ========== APPOINTMENTS FILTRÉS ==========
  static Future<List<dynamic>> getAppointmentsByDate(String date) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/appointments?date=$date'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load appointments');
  }

  static Future<List<dynamic>> getAppointmentsByDoctor(String doctorId) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/appointments?doctorId=$doctorId'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load appointments');
  }

  // ========== FACTURATION (INVOICES) ==========
  static Future<List<dynamic>> getInvoices({String? paymentStatus, String? patientId}) async {
    String url = '$baseUrl/clinic-management/clinic/${await _getClinicId()}/invoices';
    final params = <String>[];
    if (paymentStatus != null) params.add('paymentStatus=$paymentStatus');
    if (patientId != null) params.add('patientId=$patientId');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    final response = await http.get(Uri.parse(url), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load invoices');
  }

  static Future<Map<String, dynamic>> getInvoiceById(String invoiceId) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/invoices/$invoiceId'), headers: await _getClinicHeaders());
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load invoice');
  }

  static Future<Map<String, dynamic>> createInvoice({
    required String patientId,
    required String patientName,
    String? doctorId,
    String? doctorName,
    String? appointmentId,
    required List<Map<String, dynamic>> items,
    double discount = 0,
    double discountPercentage = 0,
    String? paymentMethod,
    String? notes,
  }) async {
    // Nettoyer les items pour éviter que la propriété 'total' ne soit rejetée par le backend (DTO forbidNonWhitelisted)
    final cleanItems = items.map((item) => {
      'label': item['label'],
      'quantity': item['quantity'] ?? 1,
      'unitPrice': item['unitPrice'] ?? 0,
    }).toList();

    final body = <String, dynamic>{
      'patientId': patientId,
      'patientName': patientName,
      'items': cleanItems,
    };
    
    if (discount > 0) body['discount'] = discount;
    if (discountPercentage > 0) body['discountPercentage'] = discountPercentage;
    if (doctorId != null) body['doctorId'] = doctorId;
    if (doctorName != null) body['doctorName'] = doctorName;
    if (appointmentId != null) body['appointmentId'] = appointmentId;
    if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
    if (notes != null) body['notes'] = notes;

    final response = await http.post(
      Uri.parse('$baseUrl/clinic-management/clinic/${await _getClinicId()}/invoices'),
      headers: await _getClinicHeaders(),
      body: json.encode(body),
    );
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Failed to create invoice: ${response.body}');
  }

  static Future<void> updateInvoice(String invoiceId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/clinic-management/invoices/$invoiceId'),
      headers: await _getClinicHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode != 200) throw Exception('Failed to update invoice');
  }

  static Future<void> deleteInvoice(String invoiceId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clinic-management/invoices/$invoiceId'), headers: await _getClinicHeaders());
    if (response.statusCode != 200) throw Exception('Failed to delete invoice');
  }

  /// Dossiers médicaux de ma clinique (optionnel: filtrer par patientId pour lier clinique-patient)
  static Future<List<dynamic>> getMyMedicalRecords({String? patientId}) async {
    final headers = await _getClinicHeaders();
    var uri = Uri.parse('$baseUrl/clinic-management/my/medical-records');
    if (patientId != null && patientId.isNotEmpty) {
      uri = uri.replace(queryParameters: {'patientId': patientId});
    }
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) return json.decode(response.body);
    if (response.statusCode == 401) {
      await refreshToken();
      return getMyMedicalRecords(patientId: patientId);
    }
    throw Exception(_extractHttpErrorMessage(response, fallback: 'Impossible de charger les dossiers médicaux'));
  }

  /// Historique médical complet d'un patient (toutes cliniques)
  static Future<List<dynamic>> getPatientMedicalHistory(String patientId) async {
    final headers = await _getClinicHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/clinic-management/patient/$patientId/medical-history'),
      headers: headers,
    );
    if (response.statusCode == 200) return json.decode(response.body);
    if (response.statusCode == 401) {
      await refreshToken();
      return getPatientMedicalHistory(patientId);
    }
    throw Exception(_extractHttpErrorMessage(response, fallback: "Impossible de charger l'historique médical"));
  }

  /// Résultats d'analyse du patient (centre d'analyse) — médecin ou patient (ses propres résultats)
  static Future<List<dynamic>> getPatientAnalysisResults(String patientId) async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/lab/results/patient/$patientId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return json.decode(response.body);
    if (response.statusCode == 401) {
      await refreshToken();
      return getPatientAnalysisResults(patientId);
    }
    if (response.statusCode == 403 || response.statusCode == 404) return [];
    throw Exception(_extractHttpErrorMessage(response, fallback: 'Impossible de charger les analyses'));
  }

  // ========== PROFIL LABORATOIRE ==========
  static Future<Map<String, dynamic>> getLabProfile() async {
    final token = await getAccessToken();
    
    debugPrint('🔵 API Service: Récupération du profil lab...');
    debugPrint('🔵 API Service: URL (try): $baseUrl/lab/profile puis $baseUrl/profiles/me');
    debugPrint('🔵 API Service: Token présent: ${token != null && token.isNotEmpty}');

    // Backend lab (principal): /lab/profile
    http.Response response;
    try {
      response = await http.get(
        Uri.parse('$baseUrl/lab/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      response = await http.get(
        Uri.parse('$baseUrl/profiles/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    }

    // Fallback si /lab/profile n'est pas dispo / renvoie 404
    if (response.statusCode == 404) {
      response = await http.get(
        Uri.parse('$baseUrl/profiles/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    }

    debugPrint('🔵 API Service: Réponse status: ${response.statusCode}');
    debugPrint('🔵 API Service: Réponse body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = _extractFirstMap(decoded);
      debugPrint('✅ API Service: Profil récupéré avec succès');
      
      // Si le backend retourne un message indiquant que le profil doit être initialisé
      if (data['needsInit'] == true) {
        debugPrint('⚠️ API Service: Profil nécessite une initialisation');
        final init = await _initLabProfile();
        return _normalizeLabProfile(init);
      }
      
      // Vérifier si les données sont valides
      if (data.isEmpty || (data['centreName'] == null && data['name'] == null && data['centre_name'] == null)) {
        debugPrint('⚠️ API Service: Profil vide ou incomplet, tentative d\'initialisation');
        final init = await _initLabProfile();
        return _normalizeLabProfile(init);
      }
      
      return _normalizeLabProfile(data);
    } else if (response.statusCode == 404) {
      debugPrint('⚠️ API Service: Profil non trouvé (404), tentative d\'initialisation');
      final init = await _initLabProfile();
      return _normalizeLabProfile(init);
    } else if (response.statusCode == 401) {
      debugPrint('⚠️ API Service: Token expiré (401), rafraîchissement...');
      await refreshToken();
      return getLabProfile();
    } else {
      try {
        final error = jsonDecode(response.body);
        final errorMessage = error['message'] ?? 'Erreur de récupération du profil laboratoire';
        debugPrint('❌ API Service: Erreur du backend: $errorMessage');
        
        if (errorMessage.toLowerCase().contains('profil') && 
            errorMessage.toLowerCase().contains('trouvé')) {
          debugPrint('⚠️ API Service: Message "profil non trouvé" détecté, tentative d\'initialisation');
          final init = await _initLabProfile();
          return _normalizeLabProfile(init);
        }
        
        throw Exception(errorMessage);
      } catch (e) {
        debugPrint('❌ API Service: Erreur lors du parsing de la réponse: $e');
        debugPrint('⚠️ API Service: Tentative d\'initialisation du profil...');
        final init = await _initLabProfile();
        return _normalizeLabProfile(init);
      }
    }
  }

  // Initialiser le profil lab s'il n'existe pas
  static Future<Map<String, dynamic>> _initLabProfile() async {
    final token = await getAccessToken();
    
    debugPrint('🔵 API Service: Tentative d\'initialisation du profil...');
    
    try {
      // Nouveau backend
      http.Response response;
      try {
        response = await http.post(
          Uri.parse('$baseUrl/profiles/lab/init'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 404) {
          response = await http.post(
            Uri.parse('$baseUrl/lab/profile/init'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        }
      } catch (_) {
        response = await http.post(
          Uri.parse('$baseUrl/lab/profile/init'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      debugPrint('🔵 API Service: Init response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ API Service: Profil initialisé avec succès');
        return data;
      }
    } catch (e) {
      debugPrint('⚠️ API Service: Endpoint init non disponible: $e');
    }
    
    // Si l'endpoint n'existe pas, récupérer les données de l'utilisateur
    debugPrint('⚠️ API Service: Récupération des données utilisateur...');
    try {
      final user = await getProfile();
      debugPrint('✅ API Service: Données utilisateur récupérées');
      
      final defaultProfile = {
        'name': user.fullName ?? 'Centre d\'Analyses',
        'centreName': user.fullName ?? 'Centre d\'Analyses',
        'centre_name': user.fullName ?? 'Centre d\'Analyses',
        'email': user.email,
        'phone': user.phone,
        'localisation': '',
        'categorie': [],
        'onlineBooking': true,
        'isActive': true,
        'needsInit': true,
      };
      return defaultProfile;
    } catch (e) {
      debugPrint('❌ API Service: Erreur lors de la récupération du profil utilisateur: $e');
      return {
        'name': 'Centre d\'Analyses',
        'centreName': 'Centre d\'Analyses',
        'centre_name': 'Centre d\'Analyses',
        'email': '',
        'phone': '',
        'localisation': '',
        'categorie': [],
        'onlineBooking': true,
        'isActive': true,
        'needsInit': true,
      };
    }
  }

  // ========== METTRE À JOUR PROFIL LABORATOIRE ==========
  static Future<void> updateLabProfile(Map<String, dynamic> data) async {
    final token = await getAccessToken();

    // Le backend peut utiliser des clés différentes selon la version.
    // On envoie un payload compatible (camelCase + snake_case + alias courants).
    final payload = Map<String, dynamic>.from(data);

    final centreName = (data['centreName'] ?? data['name'] ?? data['centre_name'])?.toString();
    if (centreName != null && centreName.isNotEmpty) {
      payload['centreName'] = centreName;
      payload['name'] = centreName;
      payload['centre_name'] = centreName;
    }

    final localisation = (data['localisation'] ?? data['location'] ?? data['ville'] ?? data['address'] ?? data['adresse'])?.toString();
    if (localisation != null && localisation.isNotEmpty) {
      payload['localisation'] = localisation;
      payload['location'] = localisation;
    }

    final categorie = data['categorie'] ?? data['categories'] ?? data['category'];
    if (categorie != null) {
      payload['categorie'] = categorie;
      payload['categories'] = categorie;
    }

    final phone = (data['phone'] ?? data['telephone'] ?? data['tel'])?.toString();
    if (phone != null && phone.isNotEmpty) {
      payload['phone'] = phone;
      payload['telephone'] = phone;
      payload['tel'] = phone;
    }

    final email = (data['email'] ?? data['mail'])?.toString();
    if (email != null && email.isNotEmpty) {
      payload['email'] = email;
      payload['mail'] = email;
    }

    if (data.containsKey('onlineBooking') && !payload.containsKey('reservation_en_ligne')) {
      payload['reservation_en_ligne'] = data['onlineBooking'];
    }
    if (data.containsKey('isActive') && !payload.containsKey('is_active')) {
      payload['is_active'] = data['isActive'];
    }
    
    // Backend lab (principal) d'abord, fallback alias /profiles/lab
    http.Response response;
    try {
      response = await http.put(
        Uri.parse('$baseUrl/lab/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode == 404) {
        response = await http.put(
          Uri.parse('$baseUrl/profiles/lab'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        );
      }
    } catch (_) {
      response = await http.put(
        Uri.parse('$baseUrl/profiles/lab'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
    }

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return updateLabProfile(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de mise à jour du profil');
    }
  }

  // ========== RENDEZ-VOUS LABORATOIRE ==========
  static Future<List<Map<String, dynamic>>> getLabAppointments() async {
    final token = await getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/lab-appointments/lab/requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data['appointments'] != null) {
        return List<Map<String, dynamic>>.from(data['appointments']);
      } else if (data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getLabAppointments();
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur de récupération des rendez-vous';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) {
          rethrow;
        }
        throw Exception('Erreur de récupération des rendez-vous: ${response.statusCode}');
      }
    }
  }

  // ========== RÉSULTATS D'ANALYSE ==========
  static Future<List<Map<String, dynamic>>> getAnalysisResults({String? patientEmail}) async {
    final token = await getAccessToken();
    
    String url = '$baseUrl/lab/results';
    if (patientEmail != null && patientEmail.isNotEmpty) {
      url += '?patientEmail=$patientEmail';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data['results'] != null) {
        return List<Map<String, dynamic>>.from(data['results']);
      } else if (data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getAnalysisResults(patientEmail: patientEmail);
    } else {
      throw Exception('Erreur de récupération des résultats d\'analyse');
    }
  }

  // ========== UPLOAD PHOTO PROFIL LABORATOIRE ==========
  static Future<String> uploadLabProfilePhoto(List<int> imageBytes, String fileName) async {
    final token = await getAccessToken();
    
    debugPrint('🔵 API Service: Upload de la photo du profil lab...');
    debugPrint('🔵 API Service: Nom du fichier: $fileName');
    debugPrint('🔵 API Service: Taille: ${imageBytes.length} bytes');
    
    // Certains navigateurs donnent un nom sans extension (ex: "blob").
    // Le backend filtre souvent par mimetype ET/OU extension → on force les deux.
    final safe = _normalizeImageFileNameAndType(imageBytes, fileName);
    final safeFileName = safe.fileName;
    final contentType = safe.contentType;
    
    Future<http.Response> sendTo(String url, {required String fieldName}) async {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          imageBytes,
          filename: safeFileName,
          contentType: MediaType.parse(contentType),
        ),
      );
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    Future<String> handleResponse(http.Response response) async {
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final imageUrl = data['photoUrl'] ?? data['photo'] ?? data['url'] ?? data['profilePhoto'] ?? '';
        final fullImageUrl = imageUrl.startsWith('http')
            ? imageUrl
            : '$baseUrl/$imageUrl'.replaceAll('//', '/').replaceAll(':/', '://');
        debugPrint('✅ API Service: Photo uploadée avec succès: $fullImageUrl');
        return fullImageUrl;
      }

      if (response.statusCode == 401) {
        await refreshToken();
        return uploadLabProfilePhoto(imageBytes, fileName);
      }

      // Message backend
      String msg = 'Erreur lors de l\'upload de la photo';
      try {
        final err = jsonDecode(response.body);
        msg = (err['message'] ?? err['error'] ?? msg).toString();
      } catch (_) {}

      // Si profil lab pas encore initialisé → init puis retry 1 fois
      final lower = msg.toLowerCase();
      if (lower.contains('profil') && lower.contains('laboratoire') && lower.contains('trouv')) {
        debugPrint('⚠️ API Service: Profil lab non trouvé → init puis retry upload...');
        await _initLabProfile();

        // Retry sur le nouvel endpoint puis fallback ancien
        final r1 = await sendTo('$baseUrl/profiles/lab/photo', fieldName: 'image');
        if (r1.statusCode != 404) return handleResponse(r1);
        final r2 = await sendTo('$baseUrl/lab/profile/photo', fieldName: 'image');
        return handleResponse(r2);
      }

      // Certains backends attendent field name "file" au lieu de "image"
      if (lower.contains('unexpected field') || lower.contains('image') && lower.contains('required')) {
        debugPrint('⚠️ API Service: Field image rejeté → retry avec field "file"...');
        final retry = await sendTo('$baseUrl/profiles/lab/photo', fieldName: 'file');
        if (retry.statusCode != 404) return handleResponse(retry);
        final retry2 = await sendTo('$baseUrl/lab/profile/photo', fieldName: 'file');
        return handleResponse(retry2);
      }

      throw Exception(msg);
    }

    try {
      // Backend lab (principal) d'abord
      var response = await sendTo('$baseUrl/lab/profile/photo', fieldName: 'image');
      if (response.statusCode == 404) {
        response = await sendTo('$baseUrl/profiles/lab/photo', fieldName: 'image');
      }
      
      return await handleResponse(response);
    } catch (e) {
      debugPrint('❌ API Service: Exception lors de l\'upload: $e');
      throw Exception('Erreur lors de l\'upload de la photo: $e');
    }
  }

  // ===== Helpers (Lab profile parsing / image upload) =====

  static Map<String, dynamic> _extractFirstMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      // souvent: { data: {...} } ou { profile: {...} } ou { labProfile: {...} }
      for (final k in ['data', 'profile', 'labProfile', 'lab', 'centre', 'center', 'result']) {
        final v = decoded[k];
        if (v is Map<String, dynamic>) return v;
      }
      // parfois: { data: { profile: {...} } }
      final d = decoded['data'];
      if (d is Map<String, dynamic>) {
        for (final k in ['profile', 'labProfile', 'lab', 'centre', 'center']) {
          final v = d[k];
          if (v is Map<String, dynamic>) return v;
        }
      }
      return decoded;
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _normalizeLabProfile(Map<String, dynamic> raw) {
    String? pickString(List<String> keys) {
      for (final k in keys) {
        final v = raw[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    bool? pickBool(List<String> keys) {
      for (final k in keys) {
        final v = raw[k];
        if (v is bool) return v;
        if (v is num) return v != 0;
        if (v is String) {
          final s = v.toLowerCase().trim();
          if (s == 'true' || s == '1' || s == 'yes') return true;
          if (s == 'false' || s == '0' || s == 'no') return false;
        }
      }
      return null;
    }

    List<String> parseCategories(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
      }
      if (v is String && v.trim().isNotEmpty) return [v.trim()];
      return <String>[];
    }

    final centreName = pickString(['centreName', 'centre_name', 'name', 'centerName', 'labName', 'nom']) ?? '';
    final localisation = pickString(['localisation', 'location', 'ville', 'adresse', 'address', 'localization']) ?? '';
    final categorie = raw.containsKey('categorie')
        ? raw['categorie']
        : (raw.containsKey('categories') ? raw['categories'] : raw['category']);

    final phone = pickString(['phone', 'telephone', 'tel']) ?? '';
    final email = pickString(['email', 'mail']) ?? '';
    final profilePhoto = pickString(['profilePhoto', 'photo', 'photoUrl', 'image', 'imageUrl', 'logo', 'logoUrl']);

    final onlineBooking = pickBool(['onlineBooking', 'reservation_en_ligne', 'online_booking']) ?? true;
    final isActive = pickBool(['isActive', 'is_active', 'active']) ?? true;

    // Conserver les champs originaux, mais garantir les clés attendues par l'UI
    return <String, dynamic>{
      ...raw,
      'centreName': centreName,
      'localisation': localisation,
      'categorie': parseCategories(categorie),
      'phone': phone,
      'email': email,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
      'onlineBooking': onlineBooking,
      'isActive': isActive,
    };
  }

  static ({String fileName, String contentType}) _normalizeImageFileNameAndType(List<int> bytes, String originalName) {
    final lower = originalName.toLowerCase();
    final hasDot = lower.contains('.');
    final ext = hasDot ? lower.split('.').last : '';
    final allowed = {'jpg', 'jpeg', 'png', 'gif', 'webp'};

    String inferredExt = ext;
    if (!allowed.contains(inferredExt)) {
      inferredExt = _inferImageExtensionFromBytes(bytes);
    }
    if (inferredExt == 'jpeg') inferredExt = 'jpg';

    final safeName = (allowed.contains(ext) && hasDot) ? originalName : 'profile.$inferredExt';

    final contentType = switch (inferredExt) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    return (fileName: safeName, contentType: contentType);
  }

  static String _inferImageExtensionFromBytes(List<int> bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'gif';
    }
    // WEBP: "RIFF" .... "WEBP"
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }
    return 'jpg';
  }

  // ========== UPLOAD RÉSULTATS D'ANALYSE ==========
  static Future<Map<String, dynamic>> uploadAnalysisResult({
    required String patientName,
    required String patientEmail,
    required String analysisType,
    required DateTime analysisDate,
    required List<int> fileBytes,
    required String fileName,
    String? analysisTypeOther,
    String? notes,
  }) async {
    final token = await getAccessToken();
    
    debugPrint('🔵 API Service: Upload résultat d\'analyse...');
    debugPrint('🔵 API Service: Patient: $patientName ($patientEmail)');
    debugPrint('🔵 API Service: Type: $analysisType');
    debugPrint('🔵 API Service: Date: $analysisDate');
    debugPrint('🔵 API Service: Fichier: $fileName (${fileBytes.length} bytes)');
    
    String contentType = 'application/pdf';
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        contentType = 'application/pdf';
        break;
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'doc':
      case 'docx':
        contentType = 'application/msword';
        break;
    }
    
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/lab/results'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['patientName'] = patientName;
      request.fields['patientEmail'] = patientEmail;
      request.fields['analysisType'] = analysisType;
      request.fields['analysisDate'] = analysisDate.toIso8601String();
      if (analysisTypeOther != null && analysisTypeOther.isNotEmpty) {
        request.fields['analysisTypeOther'] = analysisTypeOther;
      }
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ API Service: Résultat uploadé avec succès');
        return data;
      } else if (response.statusCode == 401) {
        await refreshToken();
        return uploadAnalysisResult(
          patientName: patientName,
          patientEmail: patientEmail,
          analysisType: analysisType,
          analysisDate: analysisDate,
          fileBytes: fileBytes,
          fileName: fileName,
          analysisTypeOther: analysisTypeOther,
          notes: notes,
        );
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['message'] ?? 'Erreur lors de l\'upload du résultat';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ API Service: Exception lors de l\'upload: $e');
      throw Exception('Erreur lors de l\'upload du résultat: $e');
    }
  }

  // ========== ML OCR (proxy backend → Flask) ==========
  /// Envoie une image ou un PDF vers /ml/ocr-analyze et retourne la réponse JSON du modèle.
  /// Le champ multipart attendu est 'file'.
  static Future<Map<String, dynamic>> mlOcrAnalyze({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final token = await getAccessToken();

    // Déterminer le content-type
    String contentType = 'application/octet-stream';
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) contentType = 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) contentType = 'image/jpeg';
    if (lower.endsWith('.png')) contentType = 'image/png';
    if (lower.endsWith('.webp')) contentType = 'image/webp';

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ml/ocr-analyze'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          // Normaliser si { message, data } est renvoyé
          if (data.containsKey('data') && data['data'] is Map) {
            return Map<String, dynamic>.from(data['data'] as Map);
          }
          return data;
        }
        return {'data': data};
      } else if (response.statusCode == 401) {
        await refreshToken();
        return mlOcrAnalyze(fileBytes: fileBytes, fileName: fileName);
      } else {
        String msg = 'Erreur OCR (${response.statusCode})';
        try {
          final err = jsonDecode(response.body);
          msg = (err['message'] ??
                  err['detail'] ??
                  err['error'] ??
                  msg)
              .toString();
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('❌ API Service: OCR exception: $e');
      throw Exception('Erreur OCR: $e');
    }
  }

  /// Sauvegarder un résultat OCR (après analyse) pour le patient connecté
  /// Backend attendu: POST /patient/ocr/save
  /// Body flexible: { filename, data } ou { filename, result } selon implémentation
  static Future<bool> saveOcrResult({
    required String fileName,
    required Map<String, dynamic> result,
    String? mimeType,
    String? sourceType,
  }) async {
    final token = await getAccessToken();
    final url = '$baseUrl/patient/ocr/save';
    final body = <String, dynamic>{ 'filename': fileName, 'data': result };
    if (mimeType != null) body['mimeType'] = mimeType;
    if (sourceType != null) body['sourceType'] = sourceType;
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    if (response.statusCode == 401) {
      await refreshToken();
      return saveOcrResult(fileName: fileName, result: result);
    }
    return false;
  }

  // ========== OCR Documents (stockés côté backend) ==========
  /// Liste des documents OCR du patient connecté.
  static Future<List<Map<String, dynamic>>> getOcrDocuments() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/patient/ocr/documents'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      if (data is Map && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      if (data is Map && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
      return [];
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getOcrDocuments();
    } else {
      throw Exception('Erreur chargement documents OCR');
    }
  }

  /// Détail d’un document OCR par ID
  static Future<Map<String, dynamic>> getOcrDocumentById(String id) async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/patient/ocr/documents/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return {'data': data};
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getOcrDocumentById(id);
    } else {
      throw Exception('Erreur chargement document OCR');
    }
  }

  // ========== ACCEPTER/REFUSER RENDEZ-VOUS ==========
  static Future<void> acceptAppointment(String appointmentId) async {
    final token = await getAccessToken();
    
    final response = await http.put(
      Uri.parse('$baseUrl/lab-appointments/lab/$appointmentId/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return acceptAppointment(appointmentId);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur d\'acceptation du rendez-vous';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) {
          rethrow;
        }
        throw Exception('Erreur d\'acceptation du rendez-vous: ${response.statusCode}');
      }
    }
  }

  static Future<void> rejectAppointment(String appointmentId, {String? reason}) async {
    final token = await getAccessToken();
    
    final response = await http.put(
      Uri.parse('$baseUrl/lab-appointments/lab/$appointmentId/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: reason != null ? jsonEncode({'reason': reason}) : null,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return rejectAppointment(appointmentId, reason: reason);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur de refus du rendez-vous';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) {
          rethrow;
        }
        throw Exception('Erreur de refus du rendez-vous: ${response.statusCode}');
      }
    }
  }

  // ========== GESTION DES CATÉGORIES LABORATOIRE ==========
  static Future<List<String>> getLabCategories() async {
    final token = await getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/lab/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<String>.from(data);
      } else if (data['categories'] != null) {
        return List<String>.from(data['categories']);
      }
      return [];
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getLabCategories();
    } else {
      throw Exception('Erreur de récupération des catégories');
    }
  }

  static Future<void> addLabCategories(List<String> categories) async {
    final token = await getAccessToken();
    
    if (token == null) {
      throw Exception('Non authentifié');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/lab/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'categories': categories}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return addLabCategories(categories);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur d\'ajout des catégories';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception) {
          rethrow;
        }
        throw Exception('Erreur d\'ajout des catégories: ${response.statusCode}');
      }
    }
  }

  static Future<void> removeLabCategories(List<String> categories) async {
    final token = await getAccessToken();
    
    if (token == null) {
      throw Exception('Non authentifié');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/lab/categories/remove'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'categories': categories}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return removeLabCategories(categories);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur de suppression des catégories';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception) {
          rethrow;
        }
        throw Exception('Erreur de suppression des catégories: ${response.statusCode}');
      }
    }
  }

  // ========== LISTE DES CLINIQUES ==========
  static Future<List<Map<String, dynamic>>> getClinicsList() async {
    final response = await http.get(
      Uri.parse('$baseUrl/clinic-management/clinics'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint('🔍 GET /clinic-management/clinics - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } else {
      throw Exception('Erreur de chargement des cliniques: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getClinicById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/clinic-management/clinic/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint('🔍 GET /clinic-management/clinic/$id - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Impossible de charger les détails de la clinique.');
    }
  }

  static Future<void> bookClinicAppointmentMobile(String clinicId, Map<String, dynamic> data) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/book-appointment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    debugPrint('🔍 POST /clinic-management/clinic/$clinicId/book-appointment - Status: ${response.statusCode}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de la réservation.');
    }
  }

  // ========== LISTE DES CENTRES D'ANALYSE ==========
  static Future<List<Map<String, dynamic>>> getCentersList() async {
    final response = await http.get(
      Uri.parse('$baseUrl/lab'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    debugPrint('🔍 GET /lab - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        if (data['labs'] != null) {
          return List<Map<String, dynamic>>.from(data['labs']);
        } else if (data['centers'] != null) {
          return List<Map<String, dynamic>>.from(data['centers']);
        } else if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } else {
      throw Exception('Erreur de récupération des centres');
    }
  }

  // ========== RÉCUPÉRER UN LABORATOIRE PAR ID ==========
  static Future<Map<String, dynamic>> getLabById(String labId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/lab/$labId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur de récupération du laboratoire';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) {
          rethrow;
        }
        throw Exception('Erreur de récupération du laboratoire: ${response.statusCode}');
      }
    }
  }

  /// Mes ordonnances (patient = reçues, médecin = émises)
  static Future<List<Map<String, dynamic>>> getMyPrescriptions() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/prescriptions/my-prescriptions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? List<Map<String, dynamic>>.from(data.map((e) => e as Map<String, dynamic>)) : [];
    }
    if (response.statusCode == 401) {
      await refreshToken();
      return getMyPrescriptions();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createPrescription({
    required String patientId,
    required List<Map<String, dynamic>> medications,
    String? notes,
  }) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/prescriptions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'patientId': patientId,
        'medications': medications,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création de l\'ordonnance');
      } catch (_) {
        throw Exception('Erreur de création d\'ordonnance: ${response.statusCode}');
      }
    }
  }

  // ==========================================
  //         CLINIC ONLINE APPOINTMENTS
  // ==========================================
  
  /// Récupérer les rendez-vous pris depuis le mobile (source=mobile)
  static Future<List<dynamic>> getOnlineAppointments() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/clinic-management/my/appointments?source=mobile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await refreshToken();
      return getOnlineAppointments();
    }
    return [];
  }

  /// Mettre à jour le statut d'un rendez-vous (confirmer/annuler)
  static Future<bool> updateAppointmentStatus(String appointmentId, String status) async {
    final token = await getAccessToken();
    final response = await http.put(
      Uri.parse('$baseUrl/clinic-management/appointments/$appointmentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return updateAppointmentStatus(appointmentId, status);
    }
    return false;
  }
}
