import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../services/api_service.dart';

class PatientsProvider with ChangeNotifier {
  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _error;

  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getAllPatients();
      _patients = data.map((json) => Patient.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _patients = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Patient> searchPatients(String query) {
    if (query.isEmpty) return _patients;
    
    final lowerQuery = query.toLowerCase();
    return _patients.where((patient) {
      return patient.fullName.toLowerCase().contains(lowerQuery) ||
          patient.firstName.toLowerCase().contains(lowerQuery) ||
          patient.lastName.toLowerCase().contains(lowerQuery) ||
          (patient.phone?.contains(query) ?? false) ||
          (patient.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
