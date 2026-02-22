import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/doctor_profile_model.dart';

class ApiService {
  // Changez cette URL pour votre backend
  // static const String baseUrl = 'http://10.0.2.2:3000'; // Pour émulateur Android
  static const String baseUrl = 'http://localhost:3000'; // Pour iOS/Web

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

  // ========== MÉDICAMENTS ==========
  static Future<List<dynamic>> getAllMedicines() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/medicines'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des médicaments');
    }
  }

  static Future<dynamic> createMedicine(Map<String, dynamic> data) async {
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/medicines'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la création du médicament');
    }
  }

  static Future<void> deleteMedicine(String id) async {
    final token = await getAccessToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/medicines/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression du médicament');
    }
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
}
