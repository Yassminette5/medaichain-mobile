/// Modèle du profil médecin (depuis le backend)
class DoctorProfile {
  final String? id;
  final String? userId;
  final String firstName;
  final String lastName;
  final String speciality;
  final String? subSpeciality;
  final String? licenseNumber;
  final String? hospital;
  final String? clinicAddress;
  final String? city;
  final String? wilaya;
  final int? yearsOfExperience;
  final double? consultationFee;
  final List<String> languages;
  final List<String> workingDays;
  final String? workingHoursStart;
  final String? workingHoursEnd;
  final String? bio;
  final String? profilePhoto;
  final bool isVerified;
  final DateTime? createdAt;

  DoctorProfile({
    this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.speciality,
    this.subSpeciality,
    this.licenseNumber,
    this.hospital,
    this.clinicAddress,
    this.city,
    this.wilaya,
    this.yearsOfExperience,
    this.consultationFee,
    this.languages = const [],
    this.workingDays = const [],
    this.workingHoursStart,
    this.workingHoursEnd,
    this.bio,
    this.profilePhoto,
    this.isVerified = false,
    this.createdAt,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      userId: json['userId']?.toString(),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      speciality: json['speciality'] ?? '',
      subSpeciality: json['subSpeciality'],
      licenseNumber: json['licenseNumber'],
      hospital: json['hospital'],
      clinicAddress: json['clinicAddress'],
      city: json['city'],
      wilaya: json['wilaya'],
      yearsOfExperience: json['yearsOfExperience'] != null
          ? (json['yearsOfExperience'] as num).toInt()
          : null,
      consultationFee: json['consultationFee'] != null
          ? (json['consultationFee'] as num).toDouble()
          : null,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : [],
      workingDays: json['workingDays'] != null
          ? List<String>.from(json['workingDays'])
          : [],
      workingHoursStart: json['workingHoursStart'],
      workingHoursEnd: json['workingHoursEnd'],
      bio: json['bio'],
      profilePhoto: json['profilePhoto'],
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  /// Nom complet du médecin
  String get fullName => 'Dr. $firstName $lastName';

  /// Alias pour fullName (pour compatibilité)
  String get displayName => fullName;

  /// Initiales pour l'avatar
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }
}
