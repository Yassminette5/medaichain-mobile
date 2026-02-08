class TestResultModel {
  final String id;
  final String testName;
  final String status; // 'FINALIZED', 'PROCESSING', 'ARCHIVED'
  final DateTime date;
  final String provider;
  final String doctor;
  final String? observation;
  final bool hasWarning;
  final String testType; // 'Blood', 'Radiology', 'Urine'

  TestResultModel({
    required this.id,
    required this.testName,
    required this.status,
    required this.date,
    required this.provider,
    required this.doctor,
    this.observation,
    this.hasWarning = false,
    required this.testType,
  });
}
