import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

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
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'phone': phone,
      'role': role.value,
    };

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
    if (gouvernorat != null) body['gouvernorat'] = gouvernorat;
    if (delegation != null) body['delegation'] = delegation;
    if (address != null) body['address'] = address;

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

  // ========== PROFIL LABORATOIRE ==========
  static Future<Map<String, dynamic>> getLabProfile() async {
    final token = await getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/lab/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Token expiré, essayer de rafraîchir
      await refreshToken();
      return getLabProfile();
    } else {
      throw Exception('Erreur de récupération du profil laboratoire');
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
      // Token expiré, essayer de rafraîchir
      await refreshToken();
      return updateLabProfile(data);
    } else {
      throw Exception('Erreur de mise à jour du profil laboratoire');
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
    
    // Le backend accepte string | string[], donc on envoie le tableau directement
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
      // Essayer de récupérer le message d'erreur du backend
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
        throw Exception('Erreur d\'ajout des catégories: ${response.statusCode} - ${response.body}');
      }
    }
  }

  static Future<void> removeLabCategories(List<String> categories) async {
    final token = await getAccessToken();
    
    if (token == null) {
      throw Exception('Non authentifié');
    }
    
    // Le backend accepte string | string[], donc on envoie le tableau directement
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
      // Essayer de récupérer le message d'erreur du backend
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
        throw Exception('Erreur de suppression des catégories: ${response.statusCode} - ${response.body}');
      }
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

  // ========== LISTE DES CENTRES D'ANALYSE ==========
  static Future<List<Map<String, dynamic>>> getCentersList() async {
    // Endpoint public GET /lab pour récupérer tous les laboratoires vérifiés
    final response = await http.get(
      Uri.parse('$baseUrl/lab'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // Debug: afficher la réponse
    debugPrint('🔍 GET /lab - Status: ${response.statusCode}');
    debugPrint('🔍 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('🔍 Parsed data type: ${data.runtimeType}');
      
      if (data is List) {
        debugPrint('🔍 Data is List, length: ${data.length}');
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        debugPrint('🔍 Data is Map, keys: ${data.keys}');
        if (data['labs'] != null) {
          final labs = data['labs'];
          debugPrint('🔍 Found labs key, type: ${labs.runtimeType}, length: ${labs is List ? labs.length : 'N/A'}');
          return List<Map<String, dynamic>>.from(labs);
        } else if (data['centers'] != null) {
          final centers = data['centers'];
          debugPrint('🔍 Found centers key, type: ${centers.runtimeType}, length: ${centers is List ? centers.length : 'N/A'}');
          return List<Map<String, dynamic>>.from(centers);
        } else if (data['data'] != null) {
          final dataList = data['data'];
          debugPrint('🔍 Found data key, type: ${dataList.runtimeType}, length: ${dataList is List ? dataList.length : 'N/A'}');
          return List<Map<String, dynamic>>.from(dataList);
        }
        debugPrint('⚠️ No valid key found in response, returning empty list');
        return [];
      }
      debugPrint('⚠️ Unexpected data type: ${data.runtimeType}');
      return [];
    } else {
      // Essayer de récupérer le message d'erreur du backend
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur de récupération des centres d\'analyse';
        debugPrint('❌ Error: $errorMessage');
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) {
          rethrow;
        }
        debugPrint('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Erreur de récupération des centres d\'analyse: ${response.statusCode}');
      }
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

  // ========== RECHERCHER DES LABORATOIRES ==========
  static Future<List<Map<String, dynamic>>> searchLabs({
    String? localisation,
    String? categorie,
  }) async {
    final queryParams = <String, String>{};
    if (localisation != null && localisation.isNotEmpty) {
      queryParams['localisation'] = localisation;
    }
    if (categorie != null && categorie.isNotEmpty) {
      queryParams['categorie'] = categorie;
    }

    final uri = Uri.parse('$baseUrl/lab/search').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data['labs'] != null) {
        return List<Map<String, dynamic>>.from(data['labs']);
      } else if (data['centers'] != null) {
        return List<Map<String, dynamic>>.from(data['centers']);
      } else if (data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur de recherche des laboratoires';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) {
          rethrow;
        }
        throw Exception('Erreur de recherche des laboratoires: ${response.statusCode}');
      }
    }
  }

  // ========== RENDEZ-VOUS ==========
  static Future<void> createAppointment(Map<String, dynamic> appointmentData) async {
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
      return createAppointment(appointmentData);
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

  // Récupérer les rendez-vous du laboratoire
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

  // Accepter un rendez-vous
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

  // Refuser un rendez-vous
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

  // Remettre un rendez-vous en attente
  static Future<void> setPendingAppointment(String appointmentId) async {
    final token = await getAccessToken();
    
    final response = await http.put(
      Uri.parse('$baseUrl/appointments/lab/$appointmentId/pending'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 401) {
      await refreshToken();
      return setPendingAppointment(appointmentId);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 
                            errorData['error'] ?? 
                            errorData['statusMessage'] ??
                            'Erreur de remise en attente du rendez-vous';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception && e.toString().contains('Erreur')) {
          rethrow;
        }
        throw Exception('Erreur de remise en attente du rendez-vous: ${response.statusCode}');
      }
    }
  }
}
