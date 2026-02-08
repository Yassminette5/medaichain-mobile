class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final String type; // 'accepted', 'pending', 'date_unavailable'
  final bool isRead;
  final String? requestNumber;
  final List<String>? alternativeDates;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
    this.requestNumber,
    this.alternativeDates,
  });
}
