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
  final String? centreName;

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
    this.centreName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
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
      centreName: json['centreName'] ?? json['centre_name'],
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
