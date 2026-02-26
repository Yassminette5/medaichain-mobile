class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodType;
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
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
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
    return Patient(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      gender: json['gender'],
      bloodType: json['bloodType'],
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
