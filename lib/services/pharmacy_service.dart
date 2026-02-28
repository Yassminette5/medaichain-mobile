// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pharmacy_dashboard.dart';
import '../models/pharmacy_statistics.dart';
import '../models/pharmacy_stock.dart';
import 'api_service.dart';

/// Pharmacy module API client.
///
/// preprod1 backend exposes:
/// - profile: GET/PUT `/pharmacy/profile`, GET `/pharmacy/profile/raw`
/// - "my" endpoints (pharmacyId resolved from JWT): `/pharmacy/my/...`
/// - patient/public endpoints keep using `/pharmacy/:pharmacyId/...`
class PharmacyService {
  static String get baseUrl => ApiService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await ApiService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Non connectÃ©');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ================= DASHBOARD (MY) =================
  static Future<PharmacyDashboard> getMyDashboard() async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/pharmacy/my/dashboard'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PharmacyDashboard.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getMyDashboard();
    } else {
      throw Exception('Failed to load dashboard');
    }
  }

  // Legacy wrapper (fedibenman code expects a pharmacyId)
  static Future<PharmacyDashboard> getDashboard(String pharmacyId) async => getMyDashboard();

  // ================= STOCK (MY) =================
  static Future<PharmacyStock> getMyStock() async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/pharmacy/my/stock'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PharmacyStock.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getMyStock();
    } else {
      throw Exception('Failed to load stock');
    }
  }

  static Future<PharmacyStock> getStock(String pharmacyId) async => getMyStock();

  static Future<MedicationStock> createMyStock(Map<String, dynamic> stockData) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/pharmacy/my/stock'),
      headers: headers,
      body: jsonEncode(stockData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MedicationStock.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return createMyStock(stockData);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create stock');
    }
  }

  static Future<MedicationStock> createStock(String pharmacyId, Map<String, dynamic> stockData) async => createMyStock(stockData);

  static Future<MedicationStock> updateMyStock(String stockId, Map<String, dynamic> updates) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$baseUrl/pharmacy/my/stock/$stockId'),
      headers: headers,
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MedicationStock.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return updateMyStock(stockId, updates);
    } else if (response.statusCode == 404) {
      throw Exception('MÃ©dicament non trouvÃ©');
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception('Erreur de validation: ${errorData['message'] ?? 'DonnÃ©es invalides'}');
    } else {
      throw Exception('Erreur lors de la mise Ã  jour du stock (${response.statusCode}): ${response.body}');
    }
  }

  static Future<MedicationStock> updateStock(String pharmacyId, String stockId, Map<String, dynamic> updates) async => updateMyStock(stockId, updates);

  static Future<void> deleteMyStock(String stockId) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('$baseUrl/pharmacy/my/stock/$stockId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return deleteMyStock(stockId);
    } else {
      throw Exception('Failed to delete stock');
    }
  }

  static Future<void> deleteStock(String pharmacyId, String stockId) async => deleteMyStock(stockId);

  static Future<StockSettings> getMyStockSettings() async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/pharmacy/my/stock/settings'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return StockSettings.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getMyStockSettings();
    } else {
      throw Exception('Failed to load settings');
    }
  }

  static Future<StockSettings> getStockSettings(String pharmacyId) async => getMyStockSettings();

  static Future<StockSettings> updateMyStockSettings(Map<String, dynamic> settings) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$baseUrl/pharmacy/my/stock/settings'),
      headers: headers,
      body: jsonEncode(settings),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return StockSettings.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return updateMyStockSettings(settings);
    } else {
      throw Exception('Failed to update settings');
    }
  }

  static Future<StockSettings> updateStockSettings(String pharmacyId, Map<String, dynamic> settings) async => updateMyStockSettings(settings);

  // ================= STATISTICS (MY) =================
  static Future<PharmacyStatistics> getMyStatistics() async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/pharmacy/my/statistics'), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PharmacyStatistics.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getMyStatistics();
    } else {
      throw Exception('Failed to load statistics');
    }
  }

  static Future<PharmacyStatistics> getStatistics(String pharmacyId) async => getMyStatistics();

  // ================= REQUESTS (MY) =================
  static Future<List<MedicationRequest>> getMyRequests({RequestStatus? status}) async {
    final headers = await _headers();
    String url = '$baseUrl/pharmacy/my/requests';
    if (status != null && status != RequestStatus.tout) {
      url += '?status=${status.name}';
    }

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => MedicationRequest.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getMyRequests(status: status);
    } else {
      throw Exception('Failed to load requests');
    }
  }

  static Future<List<MedicationRequest>> getRequests(String pharmacyId, {RequestStatus? status}) async => getMyRequests(status: status);

  static Future<MedicationRequest> updateMyRequest(String requestId, Map<String, dynamic> updates) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$baseUrl/pharmacy/my/requests/$requestId'),
      headers: headers,
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MedicationRequest.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return updateMyRequest(requestId, updates);
    } else {
      throw Exception('Failed to update request');
    }
  }

  static Future<MedicationRequest> updateRequest(String pharmacyId, String requestId, Map<String, dynamic> updates) async => updateMyRequest(requestId, updates);

  static Future<void> deleteMyRequest(String requestId) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('$baseUrl/pharmacy/my/requests/$requestId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return deleteMyRequest(requestId);
    } else {
      throw Exception('Failed to delete request');
    }
  }

  static Future<void> deleteRequest(String pharmacyId, String requestId) async => deleteMyRequest(requestId);

  // ================= AVAILABLE MEDICATIONS =================
  static Future<List<dynamic>> getMyAvailableMedications() async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/pharmacy/my/available-medications'), headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getMyAvailableMedications();
    } else {
      throw Exception('Failed to load medications');
    }
  }

  /// Public endpoint for patients: GET /pharmacy/:pharmacyId/available-medications
  static Future<List<dynamic>> getAvailableMedications(String pharmacyId) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/available-medications'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getAvailableMedications(pharmacyId);
    } else {
      throw Exception('Failed to load medications');
    }
  }

  // ================= PATIENT/PUBLIC =================
  static Future<List<dynamic>> getAllPharmacies() async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/pharmacy/list/all'), headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getAllPharmacies();
    } else {
      throw Exception('Failed to load pharmacies');
    }
  }

  /// Patient -> Pharmacie: POST /pharmacy/:pharmacyId/requests
  static Future<MedicationRequest> createRequest(String pharmacyId, Map<String, dynamic> requestData) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/requests'),
      headers: headers,
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MedicationRequest.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return createRequest(pharmacyId, requestData);
    } else {
      throw Exception('Failed to create request');
    }
  }

  // ================= PROFILE =================
  static Future<Map<String, dynamic>> getPharmacyProfile() async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/pharmacy/profile'), headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getPharmacyProfile();
    } else {
      throw Exception('Failed to get pharmacy profile');
    }
  }

  static Future<Map<String, dynamic>> getPharmacyProfileRaw() async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$baseUrl/pharmacy/profile/raw'), headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getPharmacyProfileRaw();
    } else {
      throw Exception('Failed to get pharmacy profile (raw)');
    }
  }

  // Legacy signature used by imported UI (pharmacyId is ignored on preprod1; resolved from JWT).
  static Future<void> updatePharmacySettings(String pharmacyId, Map<String, dynamic> settings) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$baseUrl/pharmacy/profile'),
      headers: headers,
      body: jsonEncode(settings),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return updatePharmacySettings(pharmacyId, settings);
    } else {
      final errorBody = response.body;
      print('Error updating pharmacy settings: $errorBody');
      throw Exception('Failed to update pharmacy settings: $errorBody');
    }
  }

  // ================= PASSWORD =================
  static Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: headers,
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      final errorBody = jsonDecode(response.body);
      if (errorBody['message']?.contains('refresh') == true) {
        await ApiService.refreshToken();
        return changePassword(currentPassword: currentPassword, newPassword: newPassword);
      } else {
        throw Exception('Mot de passe actuel incorrect');
      }
    } else {
      final errorBody = response.body;
      print('Error changing password: $errorBody');
      throw Exception('Erreur lors du changement de mot de passe');
    }
  }
}
