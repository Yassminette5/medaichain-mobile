class PharmacyModel {
  final String id;
  final String pharmacyName;
  final String ownerName;
  final String licenseNumber;
  final String address;
  final String city;
  final String wilaya;
  final String postalCode;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final List<String> workingDays;
  final String openingTime;
  final String closingTime;
  final bool is24Hours;
  final bool hasDelivery;
  final double deliveryRadius;
  final double deliveryFee;
  final List<String> services;
  final String? profilePhoto;
  final bool isVerified;
  final DateTime? verifiedAt;
  final bool hasNotifications;

  PharmacyModel({
    required this.id,
    required this.pharmacyName,
    required this.ownerName,
    required this.licenseNumber,
    required this.address,
    required this.city,
    required this.wilaya,
    required this.postalCode,
    this.gpsLatitude,
    this.gpsLongitude,
    required this.workingDays,
    required this.openingTime,
    required this.closingTime,
    required this.is24Hours,
    required this.hasDelivery,
    required this.deliveryRadius,
    required this.deliveryFee,
    required this.services,
    this.profilePhoto,
    required this.isVerified,
    this.verifiedAt,
    required this.hasNotifications,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: (json['pharmacyId'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      pharmacyName: (json['pharmacyName'] ?? json['name'] ?? json['pharmacy_name'] ?? 'Pharmacy').toString(),
      ownerName: (json['ownerName'] ?? json['pharmacistName'] ?? json['owner'] ?? 'Unknown').toString(),
      licenseNumber: (json['licenseNumber'] ?? json['licenceNumber'] ?? '').toString(),
      address: (json['address'] ?? json['location'] ?? '').toString(),
      city: (json['city'] ?? json['commune'] ?? '').toString(),
      wilaya: (json['wilaya'] ?? json['wilayaName'] ?? json['state'] ?? '').toString(),
      postalCode: (json['postalCode'] ?? json['zip'] ?? '').toString(),
      gpsLatitude: ((json['gpsLatitude'] ?? json['latitude'] ?? json['lat']) as num?)?.toDouble(),
      gpsLongitude: ((json['gpsLongitude'] ?? json['longitude'] ?? json['lng']) as num?)?.toDouble(),
      workingDays: List<String>.from((json['workingDays'] ?? json['working_days'] ?? []) as Iterable),
      openingTime: json['openingTime'] ?? '08:00',
      closingTime: json['closingTime'] ?? '20:00',
      is24Hours: json['is24Hours'] ?? false,
      hasDelivery: json['hasDelivery'] ?? false,
      deliveryRadius: (json['deliveryRadius'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      services: List<String>.from((json['services'] ?? []) as Iterable),
      profilePhoto: json['profilePhoto'] ?? json['logo'],
      isVerified: json['isVerified'] ?? false,
      verifiedAt:
          json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
      hasNotifications: json['hasNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'pharmacyName': pharmacyName,
        'ownerName': ownerName,
        'licenseNumber': licenseNumber,
        'address': address,
        'city': city,
        'wilaya': wilaya,
        'postalCode': postalCode,
        'gpsLatitude': gpsLatitude,
        'gpsLongitude': gpsLongitude,
        'workingDays': workingDays,
        'openingTime': openingTime,
        'closingTime': closingTime,
        'is24Hours': is24Hours,
        'hasDelivery': hasDelivery,
        'deliveryRadius': deliveryRadius,
        'deliveryFee': deliveryFee,
        'services': services,
        'profilePhoto': profilePhoto,
        'isVerified': isVerified,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'hasNotifications': hasNotifications,
      };

  bool get isOpen {
    if (is24Hours) return true;
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final opening = _parseTime(openingTime);
    final closing = _parseTime(closingTime);

    return currentTime.hour >= opening.hour &&
        currentTime.minute >= opening.minute &&
        (currentTime.hour < closing.hour ||
            (currentTime.hour == closing.hour &&
                currentTime.minute < closing.minute));
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}
