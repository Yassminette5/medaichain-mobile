import 'package:flutter/foundation.dart';

/// Shared ViewModel for all 5 patient information steps.
class UserInfoViewModel extends ChangeNotifier {
  // --- Name (Initial Step) ---
  String _fullName = '';
  String get fullName => _fullName;

  void setFullName(String value) {
    _fullName = value;
    notifyListeners();
  }

  // --- Gender (Step 1) ---
  String _gender = '';
  String get gender => _gender;

  void setGender(String value) {
    _gender = value;
    notifyListeners();
  }

  // --- Date of Birth (Step 2) ---
  DateTime? _dateOfBirth;
  DateTime? get dateOfBirth => _dateOfBirth;

  void setDateOfBirth(DateTime date) {
    _dateOfBirth = date;
    notifyListeners();
  }

  /// Calculated age (not stored in DB)
  int? get age {
    if (_dateOfBirth == null) return null;

    final today = DateTime.now();
    int years = today.year - _dateOfBirth!.year;

    if (today.month < _dateOfBirth!.month ||
        (today.month == _dateOfBirth!.month &&
            today.day < _dateOfBirth!.day)) {
      years--;
    }

    return years;
  }

  // --- Height (Step 3) ---
  int _currentHeight = 170;
  int get currentHeight => _currentHeight;

  void setCurrentHeight(int value) {
    _currentHeight = value;
    notifyListeners();
  }

  // --- Weight (Step 4) ---
  int _currentWeight = 60;
  int get currentWeight => _currentWeight;

  void setCurrentWeight(int value) {
    _currentWeight = value;
    notifyListeners();
  }

  // --- Allergies (Step 5) ---
  List<String> _allergies = [];
  List<String> get allergies => List.unmodifiable(_allergies);

  void addAllergy(String allergy) {
    if (!_allergies.contains(allergy)) {
      _allergies.add(allergy);
      notifyListeners();
    }
  }

  void removeAllergy(String allergy) {
    _allergies.remove(allergy);
    notifyListeners();
  }

  void setAllergies(List<String> value) {
    _allergies = List.from(value);
    notifyListeners();
  }
}
