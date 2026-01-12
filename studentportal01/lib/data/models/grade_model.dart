class GradeModel {
  final String id;
  final String enrollmentId;
  final String subjectOfferingId;
  final String componentId;
  final double? gradeValue;
  final String status; // OK, ND, NP
  final DateTime? gradedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GradeModel({
    required this.id,
    required this.enrollmentId,
    required this.subjectOfferingId,
    required this.componentId,
    this.gradeValue,
    required this.status,
    this.gradedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'] as String,
      enrollmentId: json['enrollment_id'] as String,
      subjectOfferingId: json['subject_offering_id'] as String,
      componentId: json['component_id'] as String,
      gradeValue: (json['grade_value'] as num?)?.toDouble(),
      status: json['status'] as String,
      gradedAt: json['graded_at'] != null 
          ? DateTime.parse(json['graded_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enrollment_id': enrollmentId,
      'subject_offering_id': subjectOfferingId,
      'component_id': componentId,
      'grade_value': gradeValue,
      'status': status,
      'graded_at': gradedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayValue {
    if (status == 'ND') return 'ND';
    if (status == 'NP') return 'NP';
    if (gradeValue == null) return 'ND';
    return gradeValue!.toStringAsFixed(2);
  }

  bool get isGraded => status == 'OK' && gradeValue != null;
}

class SubjectGradesSummary {
  final String subjectOfferingId;
  final String subjectName;
  final String? subjectCode;
  final double coefficient;
  final List<ComponentGrade> components;
  final double? average;
  final String weightsDisplay; // e.g., "CC:40% | Examen:60%"

  SubjectGradesSummary({
    required this.subjectOfferingId,
    required this.subjectName,
    this.subjectCode,
    required this.coefficient,
    required this.components,
    this.average,
    required this.weightsDisplay,
  });
}

class ComponentGrade {
  final String componentId;
  final String componentName;
  final double weightPercent;
  final double? grade;
  final String status;

  ComponentGrade({
    required this.componentId,
    required this.componentName,
    required this.weightPercent,
    this.grade,
    required this.status,
  });

  String get displayGrade {
    if (status == 'ND') return 'ND';
    if (status == 'NP') return 'NP';
    if (grade == null) return 'ND';
    return grade!.toStringAsFixed(2);
  }
}
