import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class ApiService {
  // Détecter automatiquement la bonne URL selon la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      // Sur le web, utiliser localhost
      return 'http://localhost:3000';
    } else {
      // Sur mobile (Android), utiliser 10.0.2.2 pour l'émulateur
      return 'http://10.0.2.2:3000';
    }
  }

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
    final url = '$baseUrl/auth/login';
    debugPrint('🔵 URL de connexion: $url');
    debugPrint('🔵 Email: $email');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    debugPrint('🔵 Status code: ${response.statusCode}');
    debugPrint('🔵 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('🔵 Data reçue: $data');
      final authResponse = AuthResponse.fromJson(data);
      debugPrint('🔵 User parsé: ${authResponse.user.email} - ${authResponse.user.role}');
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
      await _saveUser(authResponse.user);
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      final errorMessage = error['message'] ?? 'Email ou mot de passe incorrect';
      debugPrint('❌ Erreur de connexion: $errorMessage');
      throw Exception(errorMessage);
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
      debugPrint('✅ API Service: Données: $data');
      
      // Si le backend retourne un message indiquant que le profil doit être initialisé
      if (data['needsInit'] == true) {
        debugPrint('⚠️ API Service: Profil nécessite une initialisation');
        // Essayer d'initialiser le profil
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
      // Profil non trouvé, essayer de l'initialiser
      return await _initLabProfile();
    } else if (response.statusCode == 401) {
      debugPrint('⚠️ API Service: Token expiré (401), rafraîchissement...');
      // Token expiré, essayer de rafraîchir
      await refreshToken();
      return getLabProfile();
    } else {
      // Essayer de parser l'erreur
      try {
        final error = jsonDecode(response.body);
        final errorMessage = error['message'] ?? 'Erreur de récupération du profil laboratoire';
        debugPrint('❌ API Service: Erreur du backend: $errorMessage');
        
        // Si le backend dit "profil non trouvé" mais qu'on a un token valide,
        // essayer quand même d'initialiser le profil
        if (errorMessage.toLowerCase().contains('profil') && 
            errorMessage.toLowerCase().contains('trouvé')) {
          debugPrint('⚠️ API Service: Message "profil non trouvé" détecté, tentative d\'initialisation');
          return await _initLabProfile();
        }
        
        throw Exception(errorMessage);
      } catch (e) {
        debugPrint('❌ API Service: Erreur lors du parsing de la réponse: $e');
        // Si on ne peut pas parser l'erreur, essayer quand même d'initialiser
        debugPrint('⚠️ API Service: Tentative d\'initialisation du profil...');
        return await _initLabProfile();
      }
    }
  }

  // Initialiser le profil lab s'il n'existe pas
  static Future<Map<String, dynamic>> _initLabProfile() async {
    final token = await getAccessToken();
    
    debugPrint('🔵 API Service: Tentative d\'initialisation du profil...');
    
    // Essayer d'appeler l'endpoint d'initialisation s'il existe
    final response = await http.post(
      Uri.parse('$baseUrl/lab/profile/init'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('🔵 API Service: Init response status: ${response.statusCode}');
    debugPrint('🔵 API Service: Init response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      debugPrint('✅ API Service: Profil initialisé avec succès');
      return data;
    } else {
      // Si l'endpoint n'existe pas, récupérer les données de l'utilisateur
      debugPrint('⚠️ API Service: Endpoint init non disponible, récupération des données utilisateur...');
      try {
        final user = await getProfile();
        debugPrint('✅ API Service: Données utilisateur récupérées: ${user.email}, ${user.centreName}');
        
        // Retourner un profil avec les données de l'utilisateur
        final defaultProfile = {
          'name': user.centreName ?? 'Centre d\'Analyses',
          'centreName': user.centreName ?? 'Centre d\'Analyses',
          'centre_name': user.centreName ?? 'Centre d\'Analyses',
          'email': user.email,
          'phone': user.phone,
          'localisation': '',
          'categorie': [],
          'onlineBooking': true,
          'isActive': true,
          'needsInit': true,
        };
        debugPrint('✅ API Service: Profil par défaut créé: $defaultProfile');
        return defaultProfile;
      } catch (e) {
        debugPrint('❌ API Service: Erreur lors de la récupération du profil utilisateur: $e');
        // Retourner un profil minimal
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

  // ========== UPLOAD PHOTO PROFIL LABORATOIRE ==========
  static Future<String> uploadLabProfilePhoto(List<int> imageBytes, String fileName) async {
    final token = await getAccessToken();
    
    debugPrint('🔵 API Service: Upload de la photo du profil lab...');
    debugPrint('🔵 API Service: Nom du fichier: $fileName');
    debugPrint('🔵 API Service: Taille: ${imageBytes.length} bytes');
    
    // Déterminer le Content-Type basé sur l'extension du fichier
    String contentType = 'image/jpeg'; // Par défaut
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
    
    debugPrint('🔵 API Service: Content-Type: $contentType');
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/lab/profile/photo'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    
    // Créer le MultipartFile avec le Content-Type correct
    final multipartFile = http.MultipartFile(
      'image',
      http.ByteStream.fromBytes(imageBytes),
      imageBytes.length,
      filename: fileName,
      contentType: http.MediaType.parse(contentType),
    );
    
    request.files.add(multipartFile);
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('🔵 API Service: Upload response status: ${response.statusCode}');
      debugPrint('🔵 API Service: Upload response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Le backend retourne 'profilePhoto' dans la réponse
        final imageUrl = data['profilePhoto'] ?? 
                         data['photoUrl'] ?? 
                         data['photo'] ?? 
                         data['imageUrl'] ?? 
                         data['image'] ?? 
                         '';
        
        // Construire l'URL complète si c'est un chemin relatif
        final fullImageUrl = imageUrl.isNotEmpty && !imageUrl.startsWith('http')
            ? '$baseUrl$imageUrl'
            : imageUrl;
        
        debugPrint('✅ API Service: Photo uploadée avec succès: $fullImageUrl');
        debugPrint('✅ API Service: Données complètes: $data');
        return fullImageUrl;
      } else if (response.statusCode == 401) {
        // Token expiré, essayer de rafraîchir
        debugPrint('⚠️ API Service: Token expiré, rafraîchissement...');
        await refreshToken();
        return uploadLabProfilePhoto(imageBytes, fileName);
      } else {
        final error = jsonDecode(response.body);
        final errorMessage = error['message'] ?? 'Erreur lors de l\'upload de la photo';
        debugPrint('❌ API Service: Erreur upload: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ API Service: Exception lors de l\'upload: $e');
      throw Exception('Erreur lors de l\'upload de la photo: $e');
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
