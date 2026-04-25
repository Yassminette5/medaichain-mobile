import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_service.dart';

class PharmacyPrescriptionsService {
  static String get baseUrl => ApiService.baseUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await ApiService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Non connecte');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static MediaType _guessImageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  static Future<String> uploadPrescriptionImage(
    List<int> bytes,
    String filename,
  ) async {
    final token = await ApiService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Non connecte');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/pharmacy/upload/prescription'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'prescription',
        bytes,
        filename: filename,
        contentType: _guessImageContentType(filename),
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      final data = jsonDecode(body);
      if (data is Map && data['url'] != null) {
        return data['url'].toString();
      }
      throw Exception("Reponse inattendue lors de l'upload");
    }

    if (streamed.statusCode == 401) {
      await ApiService.refreshToken();
      return uploadPrescriptionImage(bytes, filename);
    }

    try {
      final error = jsonDecode(body);
      throw Exception(error['message'] ?? "Erreur lors de l'upload");
    } catch (_) {
      throw Exception("Erreur lors de l'upload (${streamed.statusCode})");
    }
  }

  static Future<Map<String, dynamic>> sendMedicationRequest({
    required String pharmacyId,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required List<Map<String, dynamic>> medications,
    String? prescriptionImageUrl,
    String? doctorName,
    bool isUrgent = false,
    bool requestsDelivery = false,
  }) async {
    final headers = await _authHeaders();
    final payload = <String, dynamic>{
      'pharmacyId': pharmacyId,
      'patient': {
        'id': patientId,
        'name': patientName,
        'phoneNumber': patientPhone,
      },
      'medications': medications,
      'isUrgent': isUrgent,
      'requestsDelivery': requestsDelivery,
    };
    if (prescriptionImageUrl != null) {
      payload['prescriptionImageUrl'] = prescriptionImageUrl;
    }
    if (doctorName != null) {
      payload['doctorName'] = doctorName;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/pharmacy/medication-request'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return sendMedicationRequest(
        pharmacyId: pharmacyId,
        patientId: patientId,
        patientName: patientName,
        patientPhone: patientPhone,
        medications: medications,
        prescriptionImageUrl: prescriptionImageUrl,
        doctorName: doctorName,
        isUrgent: isUrgent,
        requestsDelivery: requestsDelivery,
      );
    }

    try {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? "Erreur lors de l'envoi de la demande");
    } catch (_) {
      throw Exception(
        "Erreur lors de l'envoi de la demande (${response.statusCode})",
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getSharedPrescriptionsForPharmacy() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/prescriptions/shared'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List
          ? List<Map<String, dynamic>>.from(
              data.map((e) => e as Map<String, dynamic>),
            )
          : [];
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getSharedPrescriptionsForPharmacy();
    }

    throw Exception('Erreur lors du chargement des ordonnances partagees');
  }

  static Future<Map<String, dynamic>> getSharedPrescriptionForPharmacy(
    String prescriptionId,
  ) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/prescriptions/shared/$prescriptionId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getSharedPrescriptionForPharmacy(prescriptionId);
    }

    try {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? "Acces refuse a l'ordonnance partagee",
      );
    } catch (_) {
      throw Exception("Acces refuse a l'ordonnance partagee");
    }
  }

  static Future<void> sharePrescriptionWithPharmacy({
    required String prescriptionId,
    required String pharmacyId,
    String? expiresAtIso,
  }) async {
    final headers = await _authHeaders();
    final payload = <String, dynamic>{
      'pharmacyId': pharmacyId,
    };
    if (expiresAtIso != null && expiresAtIso.isNotEmpty) {
      payload['expiresAt'] = expiresAtIso;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/prescriptions/$prescriptionId/share'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return sharePrescriptionWithPharmacy(
        prescriptionId: prescriptionId,
        pharmacyId: pharmacyId,
        expiresAtIso: expiresAtIso,
      );
    }

    try {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? "Erreur lors du partage de l'ordonnance",
      );
    } catch (_) {
      throw Exception(
        "Erreur lors du partage de l'ordonnance (${response.statusCode})",
      );
    }
  }
}
