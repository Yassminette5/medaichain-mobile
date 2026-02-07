class AnalysisModel {
  final String id;
  final String name;
  final String category;
  final String code;
  final String icon;
  final bool isFavorite;
  final bool isUrgent;

  AnalysisModel({
    required this.id,
    required this.name,
    required this.category,
    required this.code,
    required this.icon,
    this.isFavorite = false,
    this.isUrgent = false,
  });
}
