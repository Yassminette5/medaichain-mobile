class PatientModel {
  final String id;
  final String name;
  final String patientId;
  final int recordCount;
  final String avatarUrl;

  PatientModel({
    required this.id,
    required this.name,
    required this.patientId,
    required this.recordCount,
    this.avatarUrl = '',
  });
}
