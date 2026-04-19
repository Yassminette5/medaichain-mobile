class Medicine {
  final String id;
  final String name;
  final String type;
  final String dosage;
  final List<String> schedule;
  final String duration;
  final String frequency;
  final String? instructions;
  final String? cause;
  final String? capSize;
  final String? description;
  final DateTime startDate;
  final bool isActive;

  Medicine({
    required this.id,
    required this.name,
    required this.type,
    required this.dosage,
    required this.schedule,
    required this.duration,
    required this.frequency,
    this.instructions,
    this.cause,
    this.capSize,
    this.description,
    required this.startDate,
    required this.isActive,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'pill',
      dosage: json['dosage'] ?? '',
      schedule: List<String>.from(json['schedule'] ?? []),
      duration: json['duration'] ?? '',
      frequency: json['frequency'] ?? '',
      instructions: json['instructions'],
      cause: json['cause'],
      capSize: json['capSize'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'dosage': dosage,
      'schedule': schedule,
      'duration': duration,
      'frequency': frequency,
      'instructions': instructions,
      'cause': cause,
      'capSize': capSize,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}
