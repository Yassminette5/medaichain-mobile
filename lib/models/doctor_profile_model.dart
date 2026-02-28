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
    String pickString(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    Map<String, dynamic>? pickMap(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is Map<String, dynamic>) return v;
      }
      return null;
    }

    final location = pickMap(['location', 'adresse', 'addressObj', 'clinicLocation']);

    final fullName = pickString(['fullName', 'name', 'doctorName']);
    String firstName = pickString(['firstName', 'prenom', 'first_name']);
    String lastName = pickString(['lastName', 'nom', 'last_name', 'familyName']);
    if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(RegExp(r'\s+')).where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) {
        firstName = parts.first;
        if (parts.length > 1) lastName = parts.sublist(1).join(' ');
      }
    }

    final speciality = pickString(['speciality', 'specialty', 'specialite', 'specialité']);

    return DoctorProfile(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      userId: json['userId']?.toString(),
      firstName: firstName,
      lastName: lastName,
      speciality: speciality,
      subSpeciality: json['subSpeciality'],
      licenseNumber: (json['licenseNumber'] ?? json['licenceNumber'] ?? json['license'] ?? json['numeroLicence'])?.toString(),
      hospital: (json['hospital'] ?? json['clinicName'] ?? json['hopital'])?.toString(),
      clinicAddress: (json['clinicAddress'] ?? json['address'] ?? json['adresse'] ?? location?['address'] ?? location?['adresse'])?.toString(),
      city: (json['city'] ?? location?['city'] ?? location?['ville'])?.toString(),
      wilaya: (json['wilaya'] ?? location?['wilaya'] ?? location?['gouvernorat'])?.toString(),
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
      workingHoursStart: (json['workingHoursStart'] ?? json['openingTime'] ?? json['startTime'])?.toString(),
      workingHoursEnd: (json['workingHoursEnd'] ?? json['closingTime'] ?? json['endTime'])?.toString(),
      bio: json['bio'],
      profilePhoto: json['profilePhoto'],
      isVerified: (json['isVerified'] ?? json['verified'] ?? false) == true,
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString())
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

