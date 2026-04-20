class Patient {
  final String id;
  /// ID du compte User (pour appel vidéo, canal, etc.). Peut être null si l'API ne le renvoie pas.
  final String? userId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final String? emergencyContact;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final String? phone;
  final String? email;
  final int? height;
  final int? weight;
  final String? city;
  final String? wilaya;

  Patient({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.emergencyContact,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.phone,
    this.email,
    this.height,
    this.weight,
    this.city,
    this.wilaya,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    // Si userInfo / userId est peuplé (ce qui est le cas de /profiles/patients)
    final userMap = json['userId'] as Map<String, dynamic>? ?? {};
    final fullName = userMap['fullName'] ?? json['fullName'] ?? '';
    
    // Fallback: extraction de firstName / lastName si fullName existe
    String fn = json['firstName'] ?? '';
    String ln = json['lastName'] ?? '';
    if (fn.isEmpty && ln.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      fn = parts.first;
      ln = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    final userIdObj = json['userId'];
    final userId = userIdObj is Map ? userIdObj['_id']?.toString() : userIdObj?.toString();

    return Patient(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userId,
      firstName: fn,
      lastName: ln,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      gender: json['gender'] ?? userMap['gender'],
      bloodType: json['bloodType'],
      emergencyContact: json['emergencyContact'],
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : [],
      chronicDiseases: json['chronicDiseases'] != null
          ? List<String>.from(json['chronicDiseases'])
          : [],
      phone: json['userId']?['phone'] ?? json['phone'],
      email: json['userId']?['email'] ?? json['email'],
      height: json['height'],
      weight: json['weight'],
      city: json['city'],
      wilaya: json['wilaya'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'bloodType': bloodType,
      'emergencyContact': emergencyContact,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'phone': phone,
      'email': email,
      'height': height,
      'weight': weight,
      'city': city,
      'wilaya': wilaya,
    };
  }
}
