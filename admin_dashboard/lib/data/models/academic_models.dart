/// Academic structure models for grade levels, sections, subjects, and exam types

// ==================== GRADE LEVEL MODEL ====================
class GradeLevelModel {
  final String id;
  final String? schoolId;
  final String name;
  final String code;
  final String levelType; // 'college' or 'secondaire'
  final int orderIndex;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final List<SectionModel> sections;
  final List<ClassSummary> classes;
  final int classCount;
  final int studentCount;

  GradeLevelModel({
    required this.id,
    this.schoolId,
    required this.name,
    required this.code,
    required this.levelType,
    this.orderIndex = 0,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.sections = const [],
    this.classes = const [],
    this.classCount = 0,
    this.studentCount = 0,
  });

  factory GradeLevelModel.fromJson(Map<String, dynamic> json) {
    List<SectionModel> sections = [];
    // Support both old 'grade_sections' and new 'niveau_sections' formats
    final sectionsData = json['niveau_sections'] ?? json['grade_sections'];
    if (sectionsData != null) {
      sections = (sectionsData as List)
          .where((gs) => gs['sections'] != null)
          .map((gs) => SectionModel.fromJson(gs['sections']))
          .toList();
    }

    List<ClassSummary> classes = [];
    if (json['classes'] != null) {
      classes = (json['classes'] as List)
          .map((c) => ClassSummary.fromJson(c))
          .toList();
    }

    // Map 'base' cycle to 'college' for UI compatibility
    String cycle = json['cycle'] ?? json['level_type'] ?? 'base';
    if (cycle == 'base') cycle = 'college';

    return GradeLevelModel(
      id: json['id'] ?? '',
      schoolId: json['school_id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      levelType: cycle,
      orderIndex: json['display_order'] ?? json['order_index'] ?? 0,
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      sections: sections,
      classes: classes,
      classCount: json['class_count'] ?? classes.length,
      studentCount: json['student_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    'code': code,
    'cycle': levelType == 'college' ? 'base' : levelType, // Map back to DB format
    'display_order': orderIndex,
    'description': description,
    'is_active': isActive,
  };

  GradeLevelModel copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? code,
    String? levelType,
    int? orderIndex,
    String? description,
    bool? isActive,
    List<SectionModel>? sections,
    List<ClassSummary>? classes,
  }) {
    return GradeLevelModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      code: code ?? this.code,
      levelType: levelType ?? this.levelType,
      orderIndex: orderIndex ?? this.orderIndex,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      sections: sections ?? this.sections,
      classes: classes ?? this.classes,
    );
  }

  String get levelTypeLabel =>
      levelType == 'college' ? 'Collège' : 'Secondaire';
}

// ==================== SECTION MODEL ====================
class SectionModel {
  final String id;
  final String? schoolId;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  SectionModel({
    required this.id,
    this.schoolId,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) => SectionModel(
    id: json['id'] ?? '',
    schoolId: json['school_id'],
    name: json['name'] ?? '',
    code: json['code'] ?? '',
    description: json['description'],
    isActive: json['is_active'] ?? true,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    'code': code,
    'description': description,
    'is_active': isActive,
  };
}

// ==================== EXAM TYPE MODEL ====================
class ExamTypeModel {
  final String id;
  final String? schoolId;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  ExamTypeModel({
    required this.id,
    this.schoolId,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  factory ExamTypeModel.fromJson(Map<String, dynamic> json) => ExamTypeModel(
    id: json['id'] ?? '',
    schoolId: json['school_id'],
    name: json['name'] ?? '',
    code: json['code'] ?? '',
    description: json['description'],
    isActive: json['is_active'] ?? true,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    'code': code,
    'description': description,
    'is_active': isActive,
  };
}

// ==================== SUBJECT ASSIGNMENT MODEL ====================
class SubjectAssignmentModel {
  final String id;
  final String subjectId;
  final String gradeLevelId;
  final String? sectionId;
  final String? semesterId;
  final double coefficient;
  final double weeklyHours;
  final bool isMainSubject;
  final bool isActive;
  final DateTime? createdAt;
  // Joined data
  final String? subjectName;
  final String? subjectCode;
  final String? gradeLevelName;
  final String? sectionName;
  final String? semesterName;
  final List<SubjectExamConfig> examConfigs;

  SubjectAssignmentModel({
    required this.id,
    required this.subjectId,
    required this.gradeLevelId,
    this.sectionId,
    this.semesterId,
    this.coefficient = 1.0,
    this.weeklyHours = 0,
    this.isMainSubject = false,
    this.isActive = true,
    this.createdAt,
    this.subjectName,
    this.subjectCode,
    this.gradeLevelName,
    this.sectionName,
    this.semesterName,
    this.examConfigs = const [],
  });

  factory SubjectAssignmentModel.fromJson(Map<String, dynamic> json) {
    List<SubjectExamConfig> configs = [];
    if (json['subject_exam_config'] != null) {
      configs = (json['subject_exam_config'] as List)
          .map((c) => SubjectExamConfig.fromJson(c))
          .toList();
    }

    return SubjectAssignmentModel(
      id: json['id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      gradeLevelId: json['grade_level_id'] ?? json['niveau_id'] ?? '',
      sectionId: json['section_id'],
      semesterId: json['semester_id'],
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      weeklyHours: (json['weekly_hours'] as num?)?.toDouble() ?? 0,
      isMainSubject: json['is_main_subject'] ?? json['is_mandatory'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      subjectName: json['subjects']?['name'],
      subjectCode: json['subjects']?['code'],
      gradeLevelName: json['grade_levels']?['name'] ?? json['niveaux']?['name'],
      sectionName: json['sections']?['name'],
      semesterName: json['semesters']?['name'],
      examConfigs: configs,
    );
  }

  /// Factory for parsing curriculum table JSON (different column names)
  factory SubjectAssignmentModel.fromCurriculumJson(Map<String, dynamic> json) {
    return SubjectAssignmentModel(
      id: json['id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      gradeLevelId: json['niveau_id'] ?? '',
      sectionId: json['section_id'],
      semesterId: null,
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      weeklyHours: 0,
      isMainSubject: json['is_mandatory'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      subjectName: json['subjects']?['name'],
      subjectCode: json['subjects']?['code'],
      gradeLevelName: json['niveaux']?['name'],
      sectionName: json['sections']?['name'],
      semesterName: null,
      examConfigs: [],
    );
  }

  Map<String, dynamic> toJson() => {
    'subject_id': subjectId,
    'grade_level_id': gradeLevelId,
    'section_id': sectionId,
    'semester_id': semesterId,
    'coefficient': coefficient,
    'weekly_hours': weeklyHours,
    'is_main_subject': isMainSubject,
    'is_active': isActive,
  };

  /// Convert to curriculum table format
  Map<String, dynamic> toCurriculumJson() => {
    'subject_id': subjectId,
    'niveau_id': gradeLevelId,
    'section_id': sectionId,
    'coefficient': coefficient,
    'is_mandatory': isMainSubject,
    'is_active': isActive,
  };
}

// ==================== SUBJECT EXAM CONFIG ====================
class SubjectExamConfig {
  final String id;
  final String subjectAssignmentId;
  final String examTypeId;
  final int countPerSemester;
  final double weight;
  final bool isRequired;
  final String? examTypeName;
  final String? examTypeCode;

  SubjectExamConfig({
    required this.id,
    required this.subjectAssignmentId,
    required this.examTypeId,
    this.countPerSemester = 1,
    this.weight = 1.0,
    this.isRequired = true,
    this.examTypeName,
    this.examTypeCode,
  });

  factory SubjectExamConfig.fromJson(Map<String, dynamic> json) =>
      SubjectExamConfig(
        id: json['id'] ?? '',
        subjectAssignmentId: json['subject_assignment_id'] ?? '',
        examTypeId: json['exam_type_id'] ?? '',
        countPerSemester: json['count_per_semester'] ?? 1,
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
        isRequired: json['is_required'] ?? true,
        examTypeName: json['exam_types']?['name'],
        examTypeCode: json['exam_types']?['code'],
      );

  Map<String, dynamic> toJson() => {
    'subject_assignment_id': subjectAssignmentId,
    'exam_type_id': examTypeId,
    'count_per_semester': countPerSemester,
    'weight': weight,
    'is_required': isRequired,
  };
}

// ==================== CLASS SUMMARY (for nested display) ====================
class ClassSummary {
  final String id;
  final String name;
  final String? sectionName;
  final int studentCount;

  ClassSummary({
    required this.id,
    required this.name,
    this.sectionName,
    this.studentCount = 0,
  });

  factory ClassSummary.fromJson(Map<String, dynamic> json) => ClassSummary(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    sectionName: json['sections']?['name'],
    studentCount: json['student_count'] ?? 0,
  );
}

// ==================== AVERAGE FORMULA MODEL ====================
class AverageFormulaModel {
  final String id;
  final String? schoolId;
  final String? gradeLevelId;
  final String? sectionId;
  final String name;
  final String formulaType; // 'weighted', 'simple', 'custom'
  final String? formulaExpression;
  final String? description;
  final bool isDefault;
  final bool isActive;

  AverageFormulaModel({
    required this.id,
    this.schoolId,
    this.gradeLevelId,
    this.sectionId,
    required this.name,
    this.formulaType = 'weighted',
    this.formulaExpression,
    this.description,
    this.isDefault = false,
    this.isActive = true,
  });

  factory AverageFormulaModel.fromJson(Map<String, dynamic> json) =>
      AverageFormulaModel(
        id: json['id'] ?? '',
        schoolId: json['school_id'],
        gradeLevelId: json['grade_level_id'],
        sectionId: json['section_id'],
        name: json['name'] ?? '',
        formulaType: json['formula_type'] ?? 'weighted',
        formulaExpression: json['formula_expression'],
        description: json['description'],
        isDefault: json['is_default'] ?? false,
        isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'grade_level_id': gradeLevelId,
    'section_id': sectionId,
    'name': name,
    'formula_type': formulaType,
    'formula_expression': formulaExpression,
    'description': description,
    'is_default': isDefault,
    'is_active': isActive,
  };

  String get formulaTypeLabel {
    switch (formulaType) {
      case 'weighted':
        return 'Moyenne pondérée';
      case 'simple':
        return 'Moyenne simple';
      case 'custom':
        return 'Formule personnalisée';
      default:
        return formulaType;
    }
  }
}
