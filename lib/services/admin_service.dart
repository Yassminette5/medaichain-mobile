import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  // Use 10.0.2.2 for Android emulator, localhost for Web/iOS
  // But since we are targeting WEB, we must use localhost:3000
  static const String baseUrl = 'http://localhost:3000';

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
        return 'Login failed: ${response.body}';
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

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
  }
}
