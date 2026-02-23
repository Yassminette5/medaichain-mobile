import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  
  // Utilisons les informations que nous venons de générer
  static const String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2OTlhNDE2YjlhY2UzMjk1MGIzMWQ1MzMiLCJlbWFpbCI6ImNsaW5pcXVlMkB0ZXN0LmNvbSIsInJvbGUiOiJjbGluaXF1ZSIsImlhdCI6MTc3MTcxNjk3MSwiZXhwIjoxNzcyMzIxNzcxfQ.svdw-UI4-q6m2Vq9ADKMxvaQbWuP5-QPZS4y9-yol6A';
  static const String clinicId = '699a41759ace32950b31d537';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ================= DASHBOARD =================
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/dashboard'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }

  // ================= CLINIC =================
  static Future<Map<String, dynamic>> getClinicProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load clinic');
    }
  }

  static Future<void> updateClinicProfile(Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId'), headers: headers, body: json.encode(data));
    if (response.statusCode != 200) throw Exception('Failed to update clinic');
  }

  // ================= DOCTORS =================
  static Future<List<dynamic>> getAvailableDoctors() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/doctors/available'), headers: headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load available doctors');
  }

  static Future<List<dynamic>> getDoctorsByClinic() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/doctors'), headers: headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load doctors');
  }

  static Future<void> addDoctor(String doctorId, String fullName, String email, String speciality) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/doctors'),
      headers: headers,
      body: json.encode({
        'doctorId': doctorId,
        'fullName': fullName,
        'email': email,
        'speciality': speciality
      }),
    );
    if (response.statusCode != 201) throw Exception(json.decode(response.body)['message'] ?? 'Failed to add doctor');
  }

  static Future<void> changeDoctorStatus(String clinicDoctorId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/clinic-management/doctors/$clinicDoctorId'),
      headers: headers,
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update doctor');
  }

  static Future<void> removeDoctor(String clinicDoctorId) async {
    final response = await http.delete(Uri.parse('$baseUrl/clinic-management/doctors/$clinicDoctorId'), headers: headers);
    if (response.statusCode != 200) throw Exception('Failed to remove doctor');
  }

  // ================= ADMISSIONS =================
  static Future<List<dynamic>> getAdmissions() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/admissions'), headers: headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load admissions');
  }

  /// Génère un ObjectId compatible MongoDB (24 caractères hex)
  static String _generateObjectId() {
    final now = DateTime.now();
    final timestamp = (now.millisecondsSinceEpoch ~/ 1000).toRadixString(16).padLeft(8, '0');
    final random = List.generate(16, (_) => (DateTime.now().microsecond % 16).toRadixString(16)).join();
    return (timestamp + random).substring(0, 24);
  }

  static Future<void> createAdmission({
    required String patientName,
    required String reason,
    String? patientPhone,
    String? doctorId,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'patientId': _generateObjectId(),
      'patientName': patientName,
      'reason': reason,
    };
    if (patientPhone != null && patientPhone.isNotEmpty) body['patientPhone'] = patientPhone;
    if (doctorId != null && doctorId.isNotEmpty) body['doctorId'] = doctorId;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await http.post(
      Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/admissions'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode != 201) throw Exception('Failed to create admission');
  }

  static Future<void> updateAdmission({
    required String admissionId,
    String? patientName,
    String? patientPhone,
    String? reason,
    String? status,
    String? doctorId,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (patientName != null) body['patientName'] = patientName;
    if (patientPhone != null) body['patientPhone'] = patientPhone;
    if (reason != null) body['reason'] = reason;
    if (status != null) body['status'] = status;
    if (doctorId != null) body['doctorId'] = doctorId;
    if (notes != null) body['notes'] = notes;

    final response = await http.put(
      Uri.parse('$baseUrl/clinic-management/admissions/$admissionId'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode != 200) throw Exception('Failed to update admission');
  }

  static Future<void> deleteAdmission(String admissionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/clinic-management/admissions/$admissionId'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to delete admission');
  }

  // ================= APPOINTMENTS =================
  static Future<List<dynamic>> getAppointments() async {
    final response = await http.get(Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/appointments'), headers: headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load appointments');
  }

  static Future<void> createAppointment({
    required String doctorId,
    required String date,
    required String timeSlot,
    String? reason,
    String? patientName,
    String? doctorName,
  }) async {
    final body = <String, dynamic>{
      'doctorId': doctorId,
      'patientId': _generateObjectId(),
      'date': date,
      'timeSlot': timeSlot,
    };
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    if (patientName != null && patientName.isNotEmpty) body['patientName'] = patientName;
    if (doctorName != null && doctorName.isNotEmpty) body['doctorName'] = doctorName;

    final response = await http.post(
      Uri.parse('$baseUrl/clinic-management/clinic/$clinicId/appointments'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode != 201) throw Exception('Failed to create appointment');
  }

  static Future<void> updateAppointment({
    required String appointmentId,
    String? status,
    String? date,
    String? timeSlot,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (date != null) body['date'] = date;
    if (timeSlot != null) body['timeSlot'] = timeSlot;
    if (notes != null) body['notes'] = notes;

    final response = await http.put(
      Uri.parse('$baseUrl/clinic-management/appointments/$appointmentId'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode != 200) throw Exception('Failed to update appointment');
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/clinic-management/appointments/$appointmentId'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to delete appointment');
  }
}
