import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../services/api_service.dart';

class MedicinesProvider extends ChangeNotifier {
  List<Medicine> _medicines = [];
  bool _isLoading = false;

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;

  Future<void> fetchMedicines() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await ApiService.getAllMedicines();
      _medicines = data.map((item) => Medicine.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching medicines: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMedicine(Medicine medicine) async {
    try {
      final data = await ApiService.createMedicine(medicine.toJson());
      final newMed = Medicine.fromJson(data);
      _medicines.insert(0, newMed);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding medicine: $e');
      return false;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    try {
      await ApiService.deleteMedicine(id);
      _medicines.removeWhere((med) => med.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      return false;
    }
  }
}
