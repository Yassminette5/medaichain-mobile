import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http_client;
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class PrescriptionsService {
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

	/// Mes ordonnances (patient = recues, medecin = emises)
	static Future<List<Map<String, dynamic>>> getMyPrescriptions() async {
		final headers = await _authHeaders();
		final response = await http.get(
			Uri.parse('$baseUrl/prescriptions/my-prescriptions'),
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
			return getMyPrescriptions();
		}
		return [];
	}

	static Future<Map<String, dynamic>> createPrescription({
		required String patientId,
		required List<Map<String, dynamic>> medications,
		String? notes,
		String? prescriptionImageUrl,
	}) async {
		final headers = await _authHeaders();
		final response = await http.post(
			Uri.parse('$baseUrl/prescriptions'),
			headers: headers,
			body: jsonEncode({
				'patientId': patientId,
				'medications': medications,
				if (notes != null && notes.isNotEmpty) 'notes': notes,
				if (prescriptionImageUrl != null && prescriptionImageUrl.isNotEmpty) 'prescriptionImageUrl': prescriptionImageUrl,
			}),
		);

		if (response.statusCode == 201 || response.statusCode == 200) {
			return jsonDecode(response.body);
		}

		if (response.statusCode == 401) {
			await ApiService.refreshToken();
			return createPrescription(
				patientId: patientId,
				medications: medications,
				notes: notes,
			);
		}

		try {
			final errorData = jsonDecode(response.body);
			throw Exception(
				errorData['message'] ?? "Erreur lors de la creation de l'ordonnance",
			);
		} catch (_) {
			throw Exception(
				"Erreur de creation d'ordonnance: ${response.statusCode}",
			);
		}
	}

	static Future<String> uploadPrescriptionImage(XFile file) async {
		final token = await ApiService.getAccessToken();
		if (token == null || token.isEmpty) throw Exception('Non connecte');

		final uri = Uri.parse('$baseUrl/pharmacy/upload/prescription');
		final request = http_client.MultipartRequest('POST', uri);
		request.headers['Authorization'] = 'Bearer $token';
		request.files.add(http_client.MultipartFile(
			'prescription',
			file.readAsBytes().asStream(),
			await file.length(),
			filename: file.name,
		));

		final streamed = await request.send();
		final resp = await http_client.Response.fromStream(streamed);

		if (resp.statusCode == 200 || resp.statusCode == 201) {
			final data = jsonDecode(resp.body);
			return data['url'] as String;
		}

		if (resp.statusCode == 401) {
			await ApiService.refreshToken();
			return uploadPrescriptionImage(file);
		}

		throw Exception('Upload failed: ${resp.statusCode}');
	}

	static Future<Map<String, dynamic>> transferToPatient({
		required String prescriptionId,
	}) async {
		final headers = await _authHeaders();
		final response = await http.post(
			Uri.parse('$baseUrl/prescriptions/$prescriptionId/transfer-to-patient'),
			headers: headers,
		);

		if (response.statusCode == 200 || response.statusCode == 201) {
			return jsonDecode(response.body);
		}

		if (response.statusCode == 401) {
			await ApiService.refreshToken();
			return transferToPatient(prescriptionId: prescriptionId);
		}

		try {
			final error = jsonDecode(response.body);
			throw Exception(error['message'] ?? "Erreur lors du transfert");
		} catch (_) {
			throw Exception("Erreur lors du transfert (${response.statusCode})");
		}
	}
}
