/// Model for Tunisian educational levels (Niveaux)
class NiveauModel {
  final String id;
  final String code;
  final String name;
  final String? nameAr;
  final String cycle; // 'college' or 'lycee'
  final int orderIndex;
  final bool hasSections;

  NiveauModel({
    required this.id,
    required this.code,
    required this.name,
    this.nameAr,
    required this.cycle,
    required this.orderIndex,
    this.hasSections = false,
  });

  factory NiveauModel.fromJson(Map<String, dynamic> json) {
    return NiveauModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      cycle: json['cycle'] ?? 'base',
      orderIndex: json['display_order'] ?? json['order_index'] ?? 0,
      hasSections: json['has_sections'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'name_ar': nameAr,
    'cycle': cycle,
    'order_index': orderIndex,
    'has_sections': hasSections,
  };

  String get shortName {
    switch (code) {
      case '7B':
        return '7ème';
      case '8B':
        return '8ème';
      case '9B':
        return '9ème';
      case '1S':
        return '1ère';
      case '2S':
        return '2ème';
      case '3S':
        return '3ème';
      case '4S':
        return 'Bac';
      default:
        return name;
    }
  }

  bool get isCollege => cycle == 'base';
  bool get isLycee => cycle == 'secondaire';
}

/// Model for Lycée sections
class SectionModel {
  final String id;
  final String code;
  final String name;
  final String? nameAr;
  final String shortName;
  final String? color;

  SectionModel({
    required this.id,
    required this.code,
    required this.name,
    this.nameAr,
    required this.shortName,
    this.color,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      shortName: json['short_name'] ?? json['name'] ?? '',
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'name_ar': nameAr,
    'short_name': shortName,
    'color': color,
  };
}

/// Model for school subjects (Matières)
class SubjectModel {
  final String id;
  final String code;
  final String name;
  final String? nameAr;
  final String? category;
  final String? icon;
  final String? color;

  SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    this.nameAr,
    this.category,
    this.icon,
    this.color,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      category: json['category'],
      icon: json['icon'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'name_ar': nameAr,
    'category': category,
    'icon': icon,
    'color': color,
  };
}

/// Model for curriculum entries (links niveau/section to subjects with coefficients)
class CurriculumModel {
  final String id;
  final String niveauCode;
  final String? sectionCode;
  final String subjectCode;
  final double coefficient;
  final List<String>? examTypes;
  final double? hoursPerWeek;
  final bool isOptional;

  // Joined data
  final SubjectModel? subject;

  CurriculumModel({
    required this.id,
    required this.niveauCode,
    this.sectionCode,
    required this.subjectCode,
    required this.coefficient,
    this.examTypes,
    this.hoursPerWeek,
    this.isOptional = false,
    this.subject,
  });

  factory CurriculumModel.fromJson(Map<String, dynamic> json) {
    return CurriculumModel(
      id: json['id'] ?? '',
      niveauCode: json['niveau_code'] ?? '',
      sectionCode: json['section_code'],
      subjectCode: json['subject_code'] ?? '',
      coefficient: (json['coefficient'] ?? 1).toDouble(),
      examTypes: json['exam_types'] != null
          ? List<String>.from(json['exam_types'])
          : null,
      hoursPerWeek: json['hours_per_week']?.toDouble(),
      isOptional: json['is_optional'] ?? false,
      subject: json['subjects'] != null
          ? SubjectModel.fromJson(json['subjects'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'niveau_code': niveauCode,
    'section_code': sectionCode,
    'subject_code': subjectCode,
    'coefficient': coefficient,
    'exam_types': examTypes,
    'hours_per_week': hoursPerWeek,
    'is_optional': isOptional,
  };
}
