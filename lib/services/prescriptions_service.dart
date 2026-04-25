import 'dart:convert';

import 'package:http/http.dart' as http;

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
	}) async {
		final headers = await _authHeaders();
		final response = await http.post(
			Uri.parse('$baseUrl/prescriptions'),
			headers: headers,
			body: jsonEncode({
				'patientId': patientId,
				'medications': medications,
				if (notes != null && notes.isNotEmpty) 'notes': notes,
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
}
