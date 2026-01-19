/// Tunisian Grading System Configuration
/// 
/// Formula: Subject Average = (Oral + DC + 2×DS) / 4
/// General Average = Σ(Subject Average × Coefficient) / Σ(Coefficients)

/// Grade component types matching Tunisian system
enum GradeComponentType {
  oral,    // Participation, homework, projects, oral tests, TP
  dc,      // Contrôle - mid-term test
  ds,      // Synthèse - end-term exam (double weight)
  tp,      // Travaux Pratiques
  project, // Project work
  practical, // Practical exam (for Sport, Arts, etc.)
}

extension GradeComponentTypeExtension on GradeComponentType {
  String get label {
    switch (this) {
      case GradeComponentType.oral:
        return 'Oral';
      case GradeComponentType.dc:
        return 'Contrôle (DC)';
      case GradeComponentType.ds:
        return 'Synthèse (DS)';
      case GradeComponentType.tp:
        return 'TP';
      case GradeComponentType.project:
        return 'Projet';
      case GradeComponentType.practical:
        return 'Pratique';
    }
  }

  String get shortLabel {
    switch (this) {
      case GradeComponentType.oral:
        return 'Oral';
      case GradeComponentType.dc:
        return 'DC';
      case GradeComponentType.ds:
        return 'DS';
      case GradeComponentType.tp:
        return 'TP';
      case GradeComponentType.project:
        return 'Proj';
      case GradeComponentType.practical:
        return 'Prat';
    }
  }

  /// Default weight in the formula
  double get defaultWeight {
    switch (this) {
      case GradeComponentType.oral:
        return 1.0;
      case GradeComponentType.dc:
        return 1.0;
      case GradeComponentType.ds:
        return 2.0; // Double weight
      case GradeComponentType.tp:
        return 1.0;
      case GradeComponentType.project:
        return 1.0;
      case GradeComponentType.practical:
        return 2.0;
    }
  }
}

/// Education levels in Tunisia
enum EducationLevel {
  college7,    // 7ème
  college8,    // 8ème
  college9,    // 9ème
  lycee1,      // 1ère Année Secondaire
  lycee2,      // 2ème Année Secondaire
  lycee3,      // 3ème Année Secondaire
  lycee4,      // 4ème Année (Baccalauréat)
}

extension EducationLevelExtension on EducationLevel {
  String get label {
    switch (this) {
      case EducationLevel.college7:
        return '7ème Année';
      case EducationLevel.college8:
        return '8ème Année';
      case EducationLevel.college9:
        return '9ème Année';
      case EducationLevel.lycee1:
        return '1ère Année Secondaire';
      case EducationLevel.lycee2:
        return '2ème Année Secondaire';
      case EducationLevel.lycee3:
        return '3ème Année Secondaire';
      case EducationLevel.lycee4:
        return '4ème Année (Bac)';
    }
  }

  String get shortLabel {
    switch (this) {
      case EducationLevel.college7:
        return '7ème';
      case EducationLevel.college8:
        return '8ème';
      case EducationLevel.college9:
        return '9ème';
      case EducationLevel.lycee1:
        return '1ère';
      case EducationLevel.lycee2:
        return '2ème';
      case EducationLevel.lycee3:
        return '3ème';
      case EducationLevel.lycee4:
        return '4ème';
    }
  }

  bool get isCollege => this == EducationLevel.college7 || 
                         this == EducationLevel.college8 || 
                         this == EducationLevel.college9;
  
  bool get isLycee => !isCollege;
}

/// Academic sections for 2ème, 3ème, 4ème years
enum AcademicSection {
  troncCommun,          // 1ère année only
  math,                 // Mathématiques
  sciences,             // Sciences Expérimentales
  technique,            // Sciences Techniques
  economie,             // Économie-Gestion
  lettres,              // Lettres
  informatique,         // Sciences de l'Informatique (4ème only)
}

extension AcademicSectionExtension on AcademicSection {
  String get label {
    switch (this) {
      case AcademicSection.troncCommun:
        return 'Tronc Commun';
      case AcademicSection.math:
        return 'Mathématiques';
      case AcademicSection.sciences:
        return 'Sciences Expérimentales';
      case AcademicSection.technique:
        return 'Sciences Techniques';
      case AcademicSection.economie:
        return 'Économie-Gestion';
      case AcademicSection.lettres:
        return 'Lettres';
      case AcademicSection.informatique:
        return 'Sciences Informatiques';
    }
  }

  String get shortLabel {
    switch (this) {
      case AcademicSection.troncCommun:
        return 'TC';
      case AcademicSection.math:
        return 'Math';
      case AcademicSection.sciences:
        return 'Sc. Exp';
      case AcademicSection.technique:
        return 'Tech';
      case AcademicSection.economie:
        return 'Éco';
      case AcademicSection.lettres:
        return 'Lettres';
      case AcademicSection.informatique:
        return 'Info';
    }
  }
}

/// Subject coefficient configuration
class SubjectCoefficient {
  final String subjectName;
  final String subjectCode;
  final double coefficient;
  final List<GradeComponentType> components;
  final bool hasPractical;

  const SubjectCoefficient({
    required this.subjectName,
    required this.subjectCode,
    required this.coefficient,
    this.components = const [
      GradeComponentType.oral,
      GradeComponentType.dc,
      GradeComponentType.ds,
    ],
    this.hasPractical = false,
  });

  SubjectCoefficient copyWith({
    String? subjectName,
    String? subjectCode,
    double? coefficient,
    List<GradeComponentType>? components,
    bool? hasPractical,
  }) {
    return SubjectCoefficient(
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      coefficient: coefficient ?? this.coefficient,
      components: components ?? this.components,
      hasPractical: hasPractical ?? this.hasPractical,
    );
  }

  Map<String, dynamic> toJson() => {
    'subjectName': subjectName,
    'subjectCode': subjectCode,
    'coefficient': coefficient,
    'components': components.map((c) => c.name).toList(),
    'hasPractical': hasPractical,
  };

  factory SubjectCoefficient.fromJson(Map<String, dynamic> json) {
    return SubjectCoefficient(
      subjectName: json['subjectName'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      coefficient: (json['coefficient'] ?? 1.0).toDouble(),
      components: (json['components'] as List<dynamic>?)
          ?.map((c) => GradeComponentType.values.firstWhere(
                (e) => e.name == c,
                orElse: () => GradeComponentType.oral,
              ))
          .toList() ?? [GradeComponentType.oral, GradeComponentType.dc, GradeComponentType.ds],
      hasPractical: json['hasPractical'] ?? false,
    );
  }
}

/// Grading formula configuration
class GradingFormula {
  final String name;
  final String description;
  final Map<GradeComponentType, double> weights;
  final double divisor;

  const GradingFormula({
    required this.name,
    required this.description,
    required this.weights,
    required this.divisor,
  });

  /// Default Tunisian formula: (Oral + DC + 2×DS) / 4
  static const standard = GradingFormula(
    name: 'Standard',
    description: '(Oral + DC + 2×DS) / 4',
    weights: {
      GradeComponentType.oral: 1.0,
      GradeComponentType.dc: 1.0,
      GradeComponentType.ds: 2.0,
    },
    divisor: 4.0,
  );

  /// Sport formula: (Performance + 2×Practical) / 3
  static const sport = GradingFormula(
    name: 'Sport',
    description: '(Performance + 2×Pratique) / 3',
    weights: {
      GradeComponentType.oral: 1.0, // Performance continue
      GradeComponentType.practical: 2.0,
    },
    divisor: 3.0,
  );

  /// Practical subjects: Same as standard but with TP
  static const practical = GradingFormula(
    name: 'Pratique',
    description: '(Oral/TP + DC + 2×DS) / 4',
    weights: {
      GradeComponentType.tp: 1.0,
      GradeComponentType.dc: 1.0,
      GradeComponentType.ds: 2.0,
    },
    divisor: 4.0,
  );

  double calculate(Map<GradeComponentType, double?> grades) {
    double sum = 0;
    double totalWeight = 0;

    for (final entry in weights.entries) {
      final grade = grades[entry.key];
      if (grade != null) {
        sum += grade * entry.value;
        totalWeight += entry.value;
      }
    }

    if (totalWeight == 0) return 0;
    return sum / divisor;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'weights': weights.map((k, v) => MapEntry(k.name, v)),
    'divisor': divisor,
  };

  factory GradingFormula.fromJson(Map<String, dynamic> json) {
    return GradingFormula(
      name: json['name'] ?? 'Custom',
      description: json['description'] ?? '',
      weights: (json['weights'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(
          GradeComponentType.values.firstWhere((e) => e.name == k),
          (v as num).toDouble(),
        ),
      ) ?? {},
      divisor: (json['divisor'] ?? 4.0).toDouble(),
    );
  }
}

/// Complete grading configuration for a level/section
class GradingConfiguration {
  final String id;
  final EducationLevel level;
  final AcademicSection? section;
  final List<SubjectCoefficient> subjects;
  final GradingFormula defaultFormula;
  final Map<String, GradingFormula> subjectFormulas; // Subject-specific formulas
  final bool isEditable;
  final DateTime? updatedAt;

  const GradingConfiguration({
    required this.id,
    required this.level,
    this.section,
    required this.subjects,
    this.defaultFormula = GradingFormula.standard,
    this.subjectFormulas = const {},
    this.isEditable = true,
    this.updatedAt,
  });

  double get totalCoefficients => 
      subjects.fold(0, (sum, s) => sum + s.coefficient);

  GradingFormula getFormulaForSubject(String subjectCode) {
    return subjectFormulas[subjectCode] ?? defaultFormula;
  }

  GradingConfiguration copyWith({
    String? id,
    EducationLevel? level,
    AcademicSection? section,
    List<SubjectCoefficient>? subjects,
    GradingFormula? defaultFormula,
    Map<String, GradingFormula>? subjectFormulas,
    bool? isEditable,
    DateTime? updatedAt,
  }) {
    return GradingConfiguration(
      id: id ?? this.id,
      level: level ?? this.level,
      section: section ?? this.section,
      subjects: subjects ?? this.subjects,
      defaultFormula: defaultFormula ?? this.defaultFormula,
      subjectFormulas: subjectFormulas ?? this.subjectFormulas,
      isEditable: isEditable ?? this.isEditable,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level.name,
    'section': section?.name,
    'subjects': subjects.map((s) => s.toJson()).toList(),
    'defaultFormula': defaultFormula.toJson(),
    'subjectFormulas': subjectFormulas.map((k, v) => MapEntry(k, v.toJson())),
    'isEditable': isEditable,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory GradingConfiguration.fromJson(Map<String, dynamic> json) {
    return GradingConfiguration(
      id: json['id'] ?? '',
      level: EducationLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => EducationLevel.lycee1,
      ),
      section: json['section'] != null
          ? AcademicSection.values.firstWhere(
              (e) => e.name == json['section'],
              orElse: () => AcademicSection.troncCommun,
            )
          : null,
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((s) => SubjectCoefficient.fromJson(s))
          .toList() ?? [],
      defaultFormula: json['defaultFormula'] != null
          ? GradingFormula.fromJson(json['defaultFormula'])
          : GradingFormula.standard,
      subjectFormulas: (json['subjectFormulas'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, GradingFormula.fromJson(v)),
      ) ?? {},
      isEditable: json['isEditable'] ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}
