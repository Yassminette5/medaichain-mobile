import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pharmacy_stock.dart';
import '../models/pharmacy_statistics.dart';
import '../models/pharmacy_dashboard.dart';
import 'api_service.dart';

class PharmacyService {
  static const String baseUrl = ApiService.baseUrl;

  // ============ DASHBOARD ============
  static Future<PharmacyDashboard> getDashboard(String pharmacyId) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/dashboard'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PharmacyDashboard.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getDashboard(pharmacyId);
    } else {
      throw Exception('Failed to load dashboard');
    }
  }

  // ============ STOCK MANAGEMENT ============
  static Future<PharmacyStock> getStock(String pharmacyId) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/stock'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PharmacyStock.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getStock(pharmacyId);
    } else {
      throw Exception('Failed to load stock');
    }
  }

  static Future<MedicationStock> createStock(
    String pharmacyId,
    Map<String, dynamic> stockData,
  ) async {
    final token = await ApiService.getAccessToken();
    
    print('📦 Creating stock for pharmacy: $pharmacyId');
    print('📦 Stock data: $stockData');
    
    final response = await http.post(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/stock'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(stockData),
    );

    print('📦 Response status: ${response.statusCode}');
    print('📦 Response body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MedicationStock.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return createStock(pharmacyId, stockData);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create stock');
    }
  }

  static Future<MedicationStock> updateStock(
    String pharmacyId,
    String stockId,
    Map<String, dynamic> updates,
  ) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.put(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/stock/$stockId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MedicationStock.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return updateStock(pharmacyId, stockId, updates);
    } else if (response.statusCode == 404) {
      throw Exception('Médicament non trouvé');
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw Exception('Erreur de validation: ${errorData['message'] ?? 'Données invalides'}');
    } else {
      throw Exception('Erreur lors de la mise à jour du stock (${response.statusCode}): ${response.body}');
    }
  }

  static Future<void> deleteStock(String pharmacyId, String stockId) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.delete(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/stock/$stockId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return deleteStock(pharmacyId, stockId);
    } else {
      throw Exception('Failed to delete stock');
    }
  }

  static Future<StockSettings> getStockSettings(String pharmacyId) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/stock/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return StockSettings.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getStockSettings(pharmacyId);
    } else {
      throw Exception('Failed to load settings');
    }
  }

  static Future<StockSettings> updateStockSettings(
    String pharmacyId,
    Map<String, dynamic> settings,
  ) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.put(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/stock/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(settings),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return StockSettings.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return updateStockSettings(pharmacyId, settings);
    } else {
      throw Exception('Failed to update settings');
    }
  }

  // ============ STATISTICS ============
  static Future<PharmacyStatistics> getStatistics(String pharmacyId) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/statistics'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PharmacyStatistics.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getStatistics(pharmacyId);
    } else {
      throw Exception('Failed to load statistics');
    }
  }

  // ============ MEDICATION REQUESTS ============
  static Future<List<MedicationRequest>> getRequests(
    String pharmacyId, {
    RequestStatus? status,
  }) async {
    final token = await ApiService.getAccessToken();
    
    String url = '$baseUrl/pharmacy/$pharmacyId/requests';
    if (status != null && status != RequestStatus.tout) {
      url += '?status=${status.name}';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => MedicationRequest.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getRequests(pharmacyId, status: status);
    } else {
      throw Exception('Failed to load requests');
    }
  }

  static Future<MedicationRequest> createRequest(
    String pharmacyId,
    Map<String, dynamic> requestData,
  ) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
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

  // ============ PUBLIC ENDPOINTS FOR PATIENTS ============
  static Future<List<dynamic>> getAllPharmacies() async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/pharmacy/list/all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getAllPharmacies();
    } else {
      throw Exception('Failed to load pharmacies');
    }
  }

  static Future<List<dynamic>> getAvailableMedications(String pharmacyId) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/available-medications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getAvailableMedications(pharmacyId);
    } else {
      throw Exception('Failed to load medications');
    }
  }

  static Future<MedicationRequest> updateRequest(
    String pharmacyId,
    String requestId,
    Map<String, dynamic> updates,
  ) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.put(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/requests/$requestId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MedicationRequest.fromJson(data);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return updateRequest(pharmacyId, requestId, updates);
    } else {
      throw Exception('Failed to update request');
    }
  }

  static Future<void> deleteRequest(String pharmacyId, String requestId) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.delete(
      Uri.parse('$baseUrl/pharmacy/$pharmacyId/requests/$requestId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return deleteRequest(pharmacyId, requestId);
    } else {
      throw Exception('Failed to delete request');
    }
  }

  // ============ PHARMACY SETTINGS ============
  static Future<Map<String, dynamic>> getPharmacyProfile() async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/profiles/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getPharmacyProfile();
    } else {
      throw Exception('Failed to get pharmacy profile');
    }
  }

  static Future<void> updatePharmacySettings(
    String pharmacyId,
    Map<String, dynamic> settings,
  ) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.put(
      Uri.parse('$baseUrl/profiles/pharmacy'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
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

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await ApiService.getAccessToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      final errorBody = jsonDecode(response.body);
      if (errorBody['message']?.contains('refresh') == true) {
        await ApiService.refreshToken();
        return changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
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
