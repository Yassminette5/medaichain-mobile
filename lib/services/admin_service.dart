import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AdminService {
  // Réutiliser la même baseUrl que l'app (web=localhost, android emulator=10.0.2.2)
  static String get baseUrl => ApiService.baseUrl;

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['accessToken'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', token);
        return null; // No error
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return errorData['message'] ?? 'Email ou mot de passe incorrect';
        } catch (e) {
          return 'Email ou mot de passe incorrect';
        }
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<Map<String, dynamic>?> getStats() async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching stats: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getUsers() async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching users: $e');
    }
    return null;
  }

  Future<String?> inviteUser(String email, String role) async {
    final token = await _getToken();
    if (token == null) return 'Not authenticated';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/invite'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email, 'role': role}),
      );

      if (response.statusCode == 201) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Invitation failed';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Créer un utilisateur directement par l'admin
  Future<String?> createUserByAdmin({
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
    String? phone,
    String? speciality,
    String? centreName,
    String? categorie,
    String? localisation,
    String? pharmacyName,
    String? gouvernorat,
    String? delegation,
    String? address,
  }) async {
    final token = await _getToken();
    if (token == null) return 'Not authenticated';

    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'role': role,
      };

      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (phone != null) body['phone'] = phone;
      if (speciality != null) body['speciality'] = speciality;
      if (centreName != null) body['centreName'] = centreName;
      if (categorie != null) body['categorie'] = categorie;
      if (localisation != null) body['localisation'] = localisation;
      if (pharmacyName != null) body['pharmacyName'] = pharmacyName;
      if (gouvernorat != null) body['gouvernorat'] = gouvernorat;
      if (delegation != null) body['delegation'] = delegation;
      if (address != null) body['address'] = address;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/create-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Création utilisateur échouée';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> deleteUser(String id) async {
    final token = await _getToken();
    if (token == null) return 'Not authenticated';

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null; // Success
      } else {
        try {
          final data = jsonDecode(response.body);
          return data['message'] ?? 'Suppression échouée';
        } catch (_) {
          return 'Suppression échouée';
        }
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // 1) Token dédié admin (flow AdminLoginScreen)
    final adminToken = prefs.getString('admin_token');
    if (adminToken != null && adminToken.isNotEmpty) return adminToken;

    // 2) Fallback: token "normal" (flow AuthProvider/Login classique)
    final accessToken = await ApiService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) return accessToken;

    return null;
  }

  Future<bool> hasToken() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
  }
}
