
class MedicalDocument {
  final String id;
  final String title;
  final String category;
  final String fileUrl;
  final String fileType; // 'PDF' or 'IMAGE'
  final DateTime date;
  final String size;

  MedicalDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.fileUrl,
    required this.fileType,
    required this.date,
    required this.size,
  });

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Sans titre',
      category: json['category'] ?? 'Autre',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? 'PDF',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      size: json['size'] ?? '0 KB',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'date': date.toIso8601String(),
      'size': size,
    };
  }
}
