import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class PharmacyPrescriptionsService {
  static String get baseUrl => ApiService.baseUrl;

  /// Share selected documents/prescriptions with selected pharmacies
  static Future<bool> shareDocuments({
    required List<String> pharmacyIds,
    required List<String> documentIds,
    required List<String> prescriptionIds,
    String? note,
  }) async {
    try {
      final token = await ApiService.getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/pharmacy/share-documents'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pharmacyIds': pharmacyIds,
          'documentIds': documentIds,
          'prescriptionIds': prescriptionIds,
          if (note != null && note.isNotEmpty) 'note': note,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return shareDocuments(
          pharmacyIds: pharmacyIds,
          documentIds: documentIds,
          prescriptionIds: prescriptionIds,
          note: note,
        );
      }
      debugPrint('Failed to share documents: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error sharing documents: $e');
      return false;
    }
  }

  /// Get Token Balance for Pharmacy Rewards
  static Future<Map<String, dynamic>> getTokenBalance() async {
    try {
      final token = await ApiService.getAccessToken();
      final response = await http.get(
        Uri.parse('$baseUrl/blockchain/balance'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return getTokenBalance();
      }
      throw Exception('Failed to get token balance');
    } catch (e) {
      debugPrint('Error getting token balance: $e');
      rethrow;
    }
  }

  /// Mint tokens (e.g., when a patient successfully buys from a pharmacy)
  static Future<bool> mintTokens(double amount, String reason) async {
    try {
      final token = await ApiService.getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/blockchain/mint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return mintTokens(amount, reason);
      }
      return false;
    } catch (e) {
      debugPrint('Error minting tokens: $e');
      return false;
    }
  }
}
