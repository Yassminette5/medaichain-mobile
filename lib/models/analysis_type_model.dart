class AnalysisTypeModel {
  final String id;
  final String name;
  final String category;
  final String subtitle;
  final String icon;
  bool isActive;

  AnalysisTypeModel({
    required this.id,
    required this.name,
    required this.category,
    required this.subtitle,
    required this.icon,
    this.isActive = true,
  });
}
