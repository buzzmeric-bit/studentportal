class SubjectOfferingModel {
  final String id;
  final String semesterId;
  final String classId;
  final String subjectId;
  final double coefficient;
  final double totalHours;
  final double weeklyCiHours;
  final double weeklyTpHours;
  final int weeks;
  final String? teacherId;
  final DateTime createdAt;
  
  // Joined data
  final SubjectModel? subject;
  final SemesterModel? semester;
  final List<GradeComponentModel>? gradeComponents;

  SubjectOfferingModel({
    required this.id,
    required this.semesterId,
    required this.classId,
    required this.subjectId,
    required this.coefficient,
    required this.totalHours,
    required this.weeklyCiHours,
    required this.weeklyTpHours,
    required this.weeks,
    this.teacherId,
    required this.createdAt,
    this.subject,
    this.semester,
    this.gradeComponents,
  });

  factory SubjectOfferingModel.fromJson(Map<String, dynamic> json) {
    return SubjectOfferingModel(
      id: json['id'] as String,
      semesterId: json['semester_id'] as String,
      classId: json['class_id'] as String,
      subjectId: json['subject_id'] as String,
      coefficient: (json['coefficient'] as num).toDouble(),
      totalHours: (json['total_hours'] as num).toDouble(),
      weeklyCiHours: (json['weekly_ci_hours'] as num?)?.toDouble() ?? 0,
      weeklyTpHours: (json['weekly_tp_hours'] as num?)?.toDouble() ?? 0,
      weeks: json['weeks'] as int? ?? 14,
      teacherId: json['teacher_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      subject: json['subjects'] != null 
          ? SubjectModel.fromJson(json['subjects'] as Map<String, dynamic>)
          : null,
      semester: json['semesters'] != null 
          ? SemesterModel.fromJson(json['semesters'] as Map<String, dynamic>)
          : null,
      gradeComponents: json['grade_components'] != null
          ? (json['grade_components'] as List)
              .map((e) => GradeComponentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semester_id': semesterId,
      'class_id': classId,
      'subject_id': subjectId,
      'coefficient': coefficient,
      'total_hours': totalHours,
      'weekly_ci_hours': weeklyCiHours,
      'weekly_tp_hours': weeklyTpHours,
      'weeks': weeks,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SubjectModel {
  final String id;
  final String schoolId;
  final String name;
  final String? code;
  final String? description;
  final DateTime createdAt;

  SubjectModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.code,
    this.description,
    required this.createdAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'code': code,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SemesterModel {
  final String id;
  final String schoolId;
  final String academicYearId;
  final String name;
  final int number;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  SemesterModel({
    required this.id,
    required this.schoolId,
    required this.academicYearId,
    required this.name,
    required this.number,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      name: json['name'] as String,
      number: json['number'] as int,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'academic_year_id': academicYearId,
      'name': name,
      'number': number,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class GradeComponentModel {
  final String id;
  final String subjectOfferingId;
  final String name; // CC, ORALE, SYNTHESE, TP, EXAMEN
  final double weightPercent;
  final DateTime createdAt;

  GradeComponentModel({
    required this.id,
    required this.subjectOfferingId,
    required this.name,
    required this.weightPercent,
    required this.createdAt,
  });

  factory GradeComponentModel.fromJson(Map<String, dynamic> json) {
    return GradeComponentModel(
      id: json['id'] as String,
      subjectOfferingId: json['subject_offering_id'] as String,
      name: json['name'] as String,
      weightPercent: (json['weight_percent'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_offering_id': subjectOfferingId,
      'name': name,
      'weight_percent': weightPercent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayName {
    switch (name) {
      case 'CC':
        return 'Contrôle';
      case 'ORALE':
        return 'Orale';
      case 'SYNTHESE':
        return 'Synthèse';
      case 'TP':
        return 'TP';
      case 'EXAMEN':
        return 'Examen';
      default:
        return name;
    }
  }
}
