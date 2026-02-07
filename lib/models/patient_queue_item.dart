class PatientQueueItem {
  final String id;
  final String name;
  final String symptom;
  final int severityScore; // 1-10, 10 is highest emergency
  final DateTime arrivalTime;
  final int estimatedWaitMinutes;

  PatientQueueItem({
    required this.id,
    required this.name,
    required this.symptom,
    required this.severityScore,
    required this.arrivalTime,
    required this.estimatedWaitMinutes,
  });

  // Helper for priority color
  String get priorityLevel {
    if (severityScore >= 8) return 'Haute';
    if (severityScore >= 5) return 'Moyenne';
    return 'Stable';
  }
}
