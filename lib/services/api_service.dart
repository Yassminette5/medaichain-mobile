import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/doctor_profile_model.dart';

class ApiService {
  // Changez cette URL pour votre backend
  // static const String baseUrl = 'http://10.0.2.2:3000'; // Pour émulateur Android
  static const String baseUrl = 'http://127.0.0.1:3000'; // Pour iOS/Web

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

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
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
      await _saveUser(authResponse.user);
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
      await _saveUser(updatedUser);
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



  // ================= CLINIQUE FIXES (DASHBOARD) =================
  static const String staticToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2OTlhNDE2YjlhY2UzMjk1MGIzMWQ1MzMiLCJlbWFpbCI6ImNsaW5pcXVlMkB0ZXN0LmNvbSIsInJvbGUiOiJjbGluaXF1ZSIsImlhdCI6MTc3MTcxNjk3MSwiZXhwIjoxNzcyMzIxNzcxfQ.svdw-UI4-q6m2Vq9ADKMxvaQbWuP5-QPZS4y9-yol6A';
  static const String clinicId = '699a41759ace32950b31d537';

  static Map<String, String> get clinicHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $staticToken',
  };

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/dashboard'), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load dashboard stats');
  }

  static Future<Map<String, dynamic>> getClinicProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId'), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load clinic');
  }

  static Future<void> updateClinicProfile(Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId'), headers: clinicHeaders, body: json.encode(data));
    if (response.statusCode != 200) throw Exception('Failed to update clinic');
  }

  static Future<List<dynamic>> getAvailableDoctors() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/doctors/available'), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load available doctors');
  }

  static Future<List<dynamic>> getDoctorsByClinic() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/doctors'), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load doctors');
  }

  static Future<void> addDoctor(String doctorId, String fullName, String email, String speciality) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/doctors'),
      headers: clinicHeaders,
      body: json.encode({'doctorId': doctorId, 'fullName': fullName, 'email': email, 'speciality': speciality}),
    );
    if (response.statusCode != 201) throw Exception(json.decode(response.body)['message'] ?? 'Failed to add doctor');
  }

  static Future<void> changeDoctorStatus(String clinicDoctorId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/clinic-management/doctors/$clinicDoctorId'),
      headers: clinicHeaders,
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update doctor');
  }

  static Future<void> removeDoctor(String clinicDoctorId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clinic-management/doctors/$clinicDoctorId'), headers: clinicHeaders);
    if (response.statusCode != 200) throw Exception('Failed to remove doctor');
  }

  static Future<List<dynamic>> getAdmissions() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/admissions'), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load admissions');
  }

  static String _generateObjectId() {
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
    final body = <String, dynamic>{'patientId': _generateObjectId(), 'patientName': patientName, 'reason': reason};
    if (patientPhone != null && patientPhone.isNotEmpty) body['patientPhone'] = patientPhone;
    if (doctorId != null && doctorId.isNotEmpty) body['doctorId'] = doctorId;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await http.post(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/admissions'), headers: clinicHeaders, body: json.encode(body));
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

    final response = await http.put(Uri.parse('$baseUrl/clinic-management/admissions/$admissionId'), headers: clinicHeaders, body: json.encode(body));
    if (response.statusCode != 200) throw Exception('Failed to update admission');
  }

  static Future<void> deleteAdmission(String admissionId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clinic-management/admissions/$admissionId'), headers: clinicHeaders);
    if (response.statusCode != 200) throw Exception('Failed to delete admission');
  }

  static Future<List<dynamic>> getAppointments() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/appointments'), headers: clinicHeaders);
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
    final body = <String, dynamic>{'doctorId': doctorId, 'patientId': _generateObjectId(), 'date': date, 'timeSlot': timeSlot};
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    if (patientName != null && patientName.isNotEmpty) body['patientName'] = patientName;
    if (doctorName != null && doctorName.isNotEmpty) body['doctorName'] = doctorName;

    final response = await http.post(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/appointments'), headers: clinicHeaders, body: json.encode(body));
    if (response.statusCode != 201) throw Exception('Failed to create appointment');
  }

  // Version pour centres d'analyse (Map)
  static Future<void> createLabAppointment(Map<String, dynamic> appointmentData) async {
    final token = await getAccessToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(appointmentData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return createLabAppointment(appointmentData);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur de création du rendez-vous';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) {
          rethrow;
        }
        throw Exception('Erreur de création du rendez-vous: ${response.statusCode}');
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

    final response = await http.put(Uri.parse('$baseUrl/clinic-management/appointments/$appointmentId'), headers: clinicHeaders, body: json.encode(body));
    if (response.statusCode != 200) throw Exception('Failed to update appointment');
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clinic-management/appointments/$appointmentId'), headers: clinicHeaders);
    if (response.statusCode != 200) throw Exception('Failed to delete appointment');
  }



  // ========== ADMISSIONS FILTRÉES ==========
  static Future<List<dynamic>> getAdmissionsByDate(String date) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/admissions?date=$date'), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load admissions');
  }

  static Future<List<dynamic>> getAdmissionsByStatus(String status) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/admissions?status=$status'), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load admissions');
  }

  // ========== APPOINTMENTS FILTRÉS ==========
  static Future<List<dynamic>> getAppointmentsByDate(String date) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/appointments?date=$date'), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load appointments');
  }

  static Future<List<dynamic>> getAppointmentsByDoctor(String doctorId) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/appointments?doctorId=$doctorId'), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load appointments');
  }

  // ========== FACTURATION (INVOICES) ==========
  static Future<List<dynamic>> getInvoices({String? paymentStatus, String? patientId}) async {
    String url = '$baseUrl/clinic-management/clinic/$clinicId/invoices';
    final params = <String>[];
    if (paymentStatus != null) params.add('paymentStatus=$paymentStatus');
    if (patientId != null) params.add('patientId=$patientId');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    final response = await http.get(Uri.parse(url), headers: clinicHeaders);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load invoices');
  }

  static Future<Map<String, dynamic>> getInvoiceById(String invoiceId) async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/invoices/$invoiceId'), headers: clinicHeaders);
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
    double subtotal = 0;
    for (var item in items) {
      item['total'] = (item['quantity'] ?? 1) * (item['unitPrice'] ?? 0);
      subtotal += item['total'];
    }
    double discountAmount = discount > 0 ? discount : (subtotal * discountPercentage / 100);
    double totalAmount = subtotal - discountAmount;

    final body = <String, dynamic>{
      'patientId': patientId,
      'patientName': patientName,
      'date': DateTime.now().toIso8601String(),
      'items': items,
      'subtotal': subtotal,
      'discount': discountAmount,
      'discountPercentage': discountPercentage,
      'totalAmount': totalAmount,
      'amountDue': totalAmount,
    };
    if (doctorId != null) body['doctorId'] = doctorId;
    if (doctorName != null) body['doctorName'] = doctorName;
    if (appointmentId != null) body['appointmentId'] = appointmentId;
    if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
    if (notes != null) body['notes'] = notes;

    final response = await http.post(
      Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/invoices'),
      headers: clinicHeaders,
      body: json.encode(body),
    );
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Failed to create invoice: ${response.body}');
  }

  static Future<void> updateInvoice(String invoiceId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/clinic-management/invoices/$invoiceId'),
      headers: clinicHeaders,
      body: json.encode(data),
    );
    if (response.statusCode != 200) throw Exception('Failed to update invoice');
  }

  static Future<void> deleteInvoice(String invoiceId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clinic-management/invoices/$invoiceId'), headers: clinicHeaders);
    if (response.statusCode != 200) throw Exception('Failed to delete invoice');
  }

  // ========== PROFIL LABORATOIRE ==========
  static Future<Map<String, dynamic>> getLabProfile() async {
    final token = await getAccessToken();
    
    debugPrint('🔵 API Service: Récupération du profil lab...');
    debugPrint('🔵 API Service: URL: $baseUrl/lab/profile');
    debugPrint('🔵 API Service: Token présent: ${token != null && token.isNotEmpty}');
    
    final response = await http.get(
      Uri.parse('$baseUrl/lab/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('🔵 API Service: Réponse status: ${response.statusCode}');
    debugPrint('🔵 API Service: Réponse body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ API Service: Profil récupéré avec succès');
      
      // Si le backend retourne un message indiquant que le profil doit être initialisé
      if (data['needsInit'] == true) {
        debugPrint('⚠️ API Service: Profil nécessite une initialisation');
        return await _initLabProfile();
      }
      
      // Vérifier si les données sont valides
      if (data.isEmpty || (data['centreName'] == null && data['name'] == null && data['centre_name'] == null)) {
        debugPrint('⚠️ API Service: Profil vide ou incomplet, tentative d\'initialisation');
        return await _initLabProfile();
      }
      
      return data;
    } else if (response.statusCode == 404) {
      debugPrint('⚠️ API Service: Profil non trouvé (404), tentative d\'initialisation');
      return await _initLabProfile();
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
          return await _initLabProfile();
        }
        
        throw Exception(errorMessage);
      } catch (e) {
        debugPrint('❌ API Service: Erreur lors du parsing de la réponse: $e');
        debugPrint('⚠️ API Service: Tentative d\'initialisation du profil...');
        return await _initLabProfile();
      }
    }
  }

  // Initialiser le profil lab s'il n'existe pas
  static Future<Map<String, dynamic>> _initLabProfile() async {
    final token = await getAccessToken();
    
    debugPrint('🔵 API Service: Tentative d\'initialisation du profil...');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lab/profile/init'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

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
    
    final response = await http.put(
      Uri.parse('$baseUrl/lab/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

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
      Uri.parse('$baseUrl/appointments/lab/my-appointments'),
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
    
    String contentType = 'image/jpeg';
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'gif':
        contentType = 'image/gif';
        break;
      case 'webp':
        contentType = 'image/webp';
        break;
    }
    
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/lab/profile/photo'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: fileName,
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final imageUrl = data['photoUrl'] ?? data['photo'] ?? data['url'] ?? '';
        final fullImageUrl = imageUrl.startsWith('http') 
            ? imageUrl 
            : '$baseUrl/$imageUrl'.replaceAll('//', '/').replaceAll(':/', '://');
        debugPrint('✅ API Service: Photo uploadée avec succès: $fullImageUrl');
        return fullImageUrl;
      } else if (response.statusCode == 401) {
        await refreshToken();
        return uploadLabProfilePhoto(imageBytes, fileName);
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['message'] ?? 'Erreur lors de l\'upload de la photo';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ API Service: Exception lors de l\'upload: $e');
      throw Exception('Erreur lors de l\'upload de la photo: $e');
    }
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

  // ========== ACCEPTER/REFUSER RENDEZ-VOUS ==========
  static Future<void> acceptAppointment(String appointmentId) async {
    final token = await getAccessToken();
    
    final response = await http.put(
      Uri.parse('$baseUrl/appointments/lab/$appointmentId/accept'),
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
      Uri.parse('$baseUrl/appointments/lab/$appointmentId/reject'),
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
}
