import 'package:flutter/material.dart';
import '../models/medical_document_model.dart';
import '../services/api_service.dart';

class DocumentsProvider extends ChangeNotifier {
  Map<String, List<MedicalDocument>> _documentsByCategory = {};
  bool _isLoading = false;

  Map<String, List<MedicalDocument>> get documentsByCategory => _documentsByCategory;
  bool get isLoading => _isLoading;

  List<MedicalDocument> getDocuments(String category) {
    return _documentsByCategory[category] ?? [];
  }

  Future<void> fetchDocuments(String category) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await ApiService.getMedicalDocuments(category: category);
      _documentsByCategory[category] = data.map((item) => MedicalDocument.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching documents for $category: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadDocument({
    required List<int> fileBytes,
    required String fileName,
    required String category,
    required String title,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.uploadMedicalDocument(
        fileBytes: fileBytes,
        fileName: fileName,
        category: category,
        title: title,
      );
      
      final newDoc = MedicalDocument.fromJson(data);
      
      if (_documentsByCategory[category] == null) {
        _documentsByCategory[category] = [];
      }
      _documentsByCategory[category]!.insert(0, newDoc);
      
      return true;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDocument(String category, String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.deleteMedicalDocument(id);
      
      if (_documentsByCategory[category] != null) {
        _documentsByCategory[category]!.removeWhere((doc) => doc.id == id);
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
