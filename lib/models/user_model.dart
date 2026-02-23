/// Modèles utilisateur pour l'API
enum UserRole {
  patient,
  medecin,
  pharmacie,
  centreAnalyse,
  clinique,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.patient:
        return 'patient';
      case UserRole.medecin:
        return 'medecin';
      case UserRole.pharmacie:
        return 'pharmacie';
      case UserRole.centreAnalyse:
        return 'centre_analyse';
      case UserRole.clinique:
        return 'clinique';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'patient':
        return UserRole.patient;
      case 'medecin':
        return UserRole.medecin;
      case 'pharmacie':
        return UserRole.pharmacie;
      case 'centre_analyse':
        return UserRole.centreAnalyse;
      case 'clinique':
        return UserRole.clinique;
      default:
        return UserRole.patient;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.medecin:
        return 'Médecin';
      case UserRole.pharmacie:
        return 'Pharmacie';
      case UserRole.centreAnalyse:
        return 'Centre d\'analyse';
      case UserRole.clinique:
        return 'Clinique';
    }
  }
}

class User {
  final String id;
  final String email;
  final String phone;
  final UserRole role;
  final bool isEmailVerified;
  final bool isProfileCompleted;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final int? age;
  final int? height;
  final int? weight;
  final String? gender;
  final List<String>? allergies;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.role,
    required this.isEmailVerified,
    required this.isProfileCompleted,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
    this.fullName,
    this.firstName,
    this.lastName,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.allergies,
  });

  /// Returns the full name, or falls back to computed name or email prefix.
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    if (parts.isNotEmpty) return parts.join(' ');
    return email.split('@').first;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Calculate age from dateOfBirth if available
    int? age;
    if (json['age'] != null) {
      age = json['age'];
    } else if (json['dateOfBirth'] != null) {
      final dob = DateTime.tryParse(json['dateOfBirth']);
      if (dob != null) {
        age = DateTime.now().year - dob.year;
      }
    }

    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRoleExtension.fromString(json['role'] ?? 'patient'),
      isEmailVerified: json['isEmailVerified'] ?? false,
      isProfileCompleted: json['isProfileCompleted'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      fullName: json['fullName'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      age: age,
      height: json['height'],
      weight: json['weight'],
      gender: json['gender'],
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : null,
    );
  }
}

class AuthResponse {
  final String message;
  final User user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.message,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] ?? '',
      user: User.fromJson(json['user']),
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }
}
