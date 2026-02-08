import '../models/analysis_type_model.dart';
import '../models/analysis_model.dart';

class AnalysisService {
  static final AnalysisService _instance = AnalysisService._internal();
  factory AnalysisService() => _instance;
  AnalysisService._internal();

  List<AnalysisTypeModel> _centerAnalyses = [
    AnalysisTypeModel(
      id: '1',
      name: 'Blood Sugar (Glucose)',
      category: 'Biochemistry',
      subtitle: 'Biochemistry • Fasting / PP',
      icon: 'drop',
      isActive: true,
    ),
    AnalysisTypeModel(
      id: '2',
      name: 'Full Blood Count (FBC)',
      category: 'Hematology',
      subtitle: 'Hematology • Automated cell count',
      icon: 'microscope',
      isActive: true,
    ),
    AnalysisTypeModel(
      id: '3',
      name: 'Lipid Profile',
      category: 'Biochemistry',
      subtitle: 'Biochemistry • Cholesterol/TG',
      icon: 'heart',
      isActive: false,
    ),
    AnalysisTypeModel(
      id: '4',
      name: 'HbA1c',
      category: 'Endocrinology',
      subtitle: 'Endocrinology • Glycated Hemoglobin',
      icon: 'flask',
      isActive: true,
    ),
    AnalysisTypeModel(
      id: '5',
      name: 'Urinalysis',
      category: 'Microbiology',
      subtitle: 'Microbiology • Physical/Chemical',
      icon: 'molecule',
      isActive: true,
    ),
    AnalysisTypeModel(
      id: '6',
      name: 'TSH (Thyroid Stimulating)',
      category: 'Endocrinology',
      subtitle: 'Endocrinology • Hormone Level',
      icon: 'shield',
      isActive: true,
    ),
    AnalysisTypeModel(
      id: '7',
      name: 'Vitamin B12',
      category: 'Biochemistry',
      subtitle: 'Biochemistry • Serum B12',
      icon: 'syringe',
      isActive: false,
    ),
  ];

  List<AnalysisTypeModel> get centerAnalyses => _centerAnalyses;

  void addAnalysis(AnalysisTypeModel analysis) {
    _centerAnalyses.add(analysis);
  }

  void updateAnalysis(String id, bool isActive) {
    final index = _centerAnalyses.indexWhere((a) => a.id == id);
    if (index != -1) {
      _centerAnalyses[index].isActive = isActive;
    }
  }

  // Convertir les analyses du centre en analyses pour les patients
  List<AnalysisModel> getPatientAnalyses() {
    return _centerAnalyses
        .where((a) => a.isActive)
        .map((a) {
          // Mapper les catégories
          String category = _translateCategory(a.category);
          String codePrefix = _getCategoryCode(a.category);

          return AnalysisModel(
            id: a.id,
            name: a.name,
            category: category,
            code: '$codePrefix-${a.id.padLeft(3, '0')}',
            icon: a.icon,
            isFavorite: false,
          );
        })
        .toList();
  }

  String _translateCategory(String category) {
    switch (category) {
      case 'Biochemistry':
        return 'Biochimie';
      case 'Hematology':
        return 'Hématologie';
      case 'Endocrinology':
        return 'Endocrinologie';
      case 'Microbiology':
        return 'Microbiologie';
      case 'Virology':
        return 'Virologie';
      case 'Genetics':
        return 'Génétique';
      default:
        return category;
    }
  }

  String _getCategoryCode(String category) {
    switch (category) {
      case 'Biochemistry':
        return 'BIO';
      case 'Hematology':
        return 'HEM';
      case 'Endocrinology':
        return 'END';
      case 'Microbiology':
        return 'MIC';
      case 'Virology':
        return 'VIR';
      case 'Genetics':
        return 'GEN';
      default:
        return category.substring(0, 3).toUpperCase();
    }
  }
}
