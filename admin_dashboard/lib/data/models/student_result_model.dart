/// Student Results Model
/// Holds calculated results for a student

import 'grading_config_model.dart';

/// Individual grade entry
class GradeEntry {
  final String id;
  final String subjectOfferingId;
  final String componentId;
  final GradeComponentType componentType;
  final double? value;
  final String status; // 'graded', 'pending', 'absent', 'exempt'
  final DateTime? gradedAt;

  const GradeEntry({
    required this.id,
    required this.subjectOfferingId,
    required this.componentId,
    required this.componentType,
    this.value,
    this.status = 'pending',
    this.gradedAt,
  });

  bool get isGraded => status == 'graded' && value != null;
  bool get isAbsent => status == 'absent';
  bool get isExempt => status == 'exempt';

  GradeEntry copyWith({
    String? id,
    String? subjectOfferingId,
    String? componentId,
    GradeComponentType? componentType,
    double? value,
    String? status,
    DateTime? gradedAt,
  }) {
    return GradeEntry(
      id: id ?? this.id,
      subjectOfferingId: subjectOfferingId ?? this.subjectOfferingId,
      componentId: componentId ?? this.componentId,
      componentType: componentType ?? this.componentType,
      value: value ?? this.value,
      status: status ?? this.status,
      gradedAt: gradedAt ?? this.gradedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject_offering_id': subjectOfferingId,
    'component_id': componentId,
    'component_type': componentType.name,
    'grade_value': value,
    'status': status,
    'graded_at': gradedAt?.toIso8601String(),
  };

  factory GradeEntry.fromJson(Map<String, dynamic> json) {
    return GradeEntry(
      id: json['id'] ?? '',
      subjectOfferingId: json['subject_offering_id'] ?? '',
      componentId: json['component_id'] ?? '',
      componentType: _parseComponentType(
        json['component_type'] ?? json['component_name'] ?? 'oral',
      ),
      value: json['grade_value'] != null
          ? (json['grade_value'] as num).toDouble()
          : null,
      status: json['status'] ?? 'pending',
      gradedAt: json['graded_at'] != null
          ? DateTime.parse(json['graded_at'])
          : null,
    );
  }

  static GradeComponentType _parseComponentType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('ds') || lowerName.contains('synth')) {
      return GradeComponentType.ds;
    } else if (lowerName.contains('dc') || lowerName.contains('contr')) {
      return GradeComponentType.dc;
    } else if (lowerName.contains('tp')) {
      return GradeComponentType.tp;
    } else if (lowerName.contains('prat') || lowerName.contains('practical')) {
      return GradeComponentType.practical;
    } else if (lowerName.contains('proj')) {
      return GradeComponentType.project;
    }
    return GradeComponentType.oral;
  }
}

/// Subject result with all grades and calculated average
class SubjectResult {
  final String subjectId;
  final String subjectOfferingId;
  final String subjectName;
  final String subjectCode;
  final double coefficient;
  final List<GradeEntry> grades;
  final GradingFormula formula;

  const SubjectResult({
    required this.subjectId,
    required this.subjectOfferingId,
    required this.subjectName,
    required this.subjectCode,
    required this.coefficient,
    required this.grades,
    required this.formula,
  });

  /// Calculate subject average using the formula
  double? get average {
    final gradeMap = <GradeComponentType, double?>{};
    for (final grade in grades) {
      if (grade.isGraded) {
        gradeMap[grade.componentType] = grade.value;
      }
    }
    if (gradeMap.isEmpty) return null;
    return formula.calculate(gradeMap);
  }

  /// Weighted contribution to general average
  double? get weightedValue {
    final avg = average;
    if (avg == null) return null;
    return avg * coefficient;
  }

  /// Check if all required grades are filled
  bool get isComplete {
    for (final componentType in formula.weights.keys) {
      final hasGrade = grades.any(
        (g) => g.componentType == componentType && g.isGraded,
      );
      if (!hasGrade) return false;
    }
    return true;
  }

  /// Get grade by component type
  GradeEntry? getGrade(GradeComponentType type) {
    try {
      return grades.firstWhere((g) => g.componentType == type);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'subjectId': subjectId,
    'subjectOfferingId': subjectOfferingId,
    'subjectName': subjectName,
    'subjectCode': subjectCode,
    'coefficient': coefficient,
    'grades': grades.map((g) => g.toJson()).toList(),
    'average': average,
    'weightedValue': weightedValue,
    'isComplete': isComplete,
  };
}

/// Semester result for a student
class SemesterResult {
  final String semesterId;
  final String semesterName;
  final int semesterNumber;
  final List<SubjectResult> subjects;

  const SemesterResult({
    required this.semesterId,
    required this.semesterName,
    required this.semesterNumber,
    required this.subjects,
  });

  /// Calculate semester average
  double? get average {
    double totalWeighted = 0;
    double totalCoef = 0;

    for (final subject in subjects) {
      final weighted = subject.weightedValue;
      if (weighted != null) {
        totalWeighted += weighted;
        totalCoef += subject.coefficient;
      }
    }

    if (totalCoef == 0) return null;
    return totalWeighted / totalCoef;
  }

  /// Total coefficients
  double get totalCoefficients =>
      subjects.fold(0, (sum, s) => sum + s.coefficient);

  /// Check if all subjects are complete
  bool get isComplete => subjects.every((s) => s.isComplete);

  /// Get completion percentage
  double get completionPercentage {
    if (subjects.isEmpty) return 0;
    final completed = subjects.where((s) => s.isComplete).length;
    return completed / subjects.length * 100;
  }

  Map<String, dynamic> toJson() => {
    'semesterId': semesterId,
    'semesterName': semesterName,
    'semesterNumber': semesterNumber,
    'subjects': subjects.map((s) => s.toJson()).toList(),
    'average': average,
    'totalCoefficients': totalCoefficients,
    'isComplete': isComplete,
    'completionPercentage': completionPercentage,
  };
}

/// Complete student result for an academic year
class StudentResult {
  final String studentId;
  final String enrollmentId;
  final String studentName;
  final String studentCode;
  final String? photoUrl;
  final String className;
  final String? groupName;
  final String academicYearId;
  final String academicYearName;
  final List<SemesterResult> semesters;
  final int rank;
  final int totalStudents;

  const StudentResult({
    required this.studentId,
    required this.enrollmentId,
    required this.studentName,
    required this.studentCode,
    this.photoUrl,
    required this.className,
    this.groupName,
    required this.academicYearId,
    required this.academicYearName,
    required this.semesters,
    this.rank = 0,
    this.totalStudents = 0,
  });

  /// Calculate annual average
  double? get annualAverage {
    if (semesters.isEmpty) return null;

    double total = 0;
    int count = 0;

    for (final semester in semesters) {
      final avg = semester.average;
      if (avg != null) {
        total += avg;
        count++;
      }
    }

    if (count == 0) return null;
    return total / count;
  }

  /// Get first semester average
  double? get semester1Average {
    try {
      return semesters.firstWhere((s) => s.semesterNumber == 1).average;
    } catch (_) {
      return null;
    }
  }

  /// Get second semester average
  double? get semester2Average {
    try {
      return semesters.firstWhere((s) => s.semesterNumber == 2).average;
    } catch (_) {
      return null;
    }
  }

  /// Get third semester average (Trimester 3)
  double? get semester3Average {
    try {
      return semesters.firstWhere((s) => s.semesterNumber == 3).average;
    } catch (_) {
      return null;
    }
  }

  /// Check if all semesters are complete
  bool get isComplete => semesters.every((s) => s.isComplete);

  /// Get overall completion percentage
  double get completionPercentage {
    if (semesters.isEmpty) return 0;
    return semesters.fold(0.0, (sum, s) => sum + s.completionPercentage) /
        semesters.length;
  }

  /// Get performance status
  String get performanceStatus {
    final avg = annualAverage;
    if (avg == null) return 'En cours';
    if (avg >= 16) return 'Excellent';
    if (avg >= 14) return 'Très Bien';
    if (avg >= 12) return 'Bien';
    if (avg >= 10) return 'Passable';
    return 'Insuffisant';
  }

  /// Get rank suffix
  String get rankSuffix {
    if (rank == 1) return 'er';
    return 'ème';
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'enrollmentId': enrollmentId,
    'studentName': studentName,
    'studentCode': studentCode,
    'photoUrl': photoUrl,
    'className': className,
    'groupName': groupName,
    'academicYearId': academicYearId,
    'academicYearName': academicYearName,
    'semesters': semesters.map((s) => s.toJson()).toList(),
    'annualAverage': annualAverage,
    'semester1Average': semester1Average,
    'semester2Average': semester2Average,
    'rank': rank,
    'totalStudents': totalStudents,
    'performanceStatus': performanceStatus,
  };
}

/// Class/Group aggregate results
class ClassResult {
  final String classId;
  final String className;
  final String? groupId;
  final String? groupName;
  final String academicYearId;
  final String academicYearName;
  final List<StudentResult> students;

  const ClassResult({
    required this.classId,
    required this.className,
    this.groupId,
    this.groupName,
    required this.academicYearId,
    required this.academicYearName,
    required this.students,
  });

  /// Total number of students
  int get totalStudents => students.length;

  /// Passed count (average >= 10)
  int get passedCount =>
      students.where((s) => (s.annualAverage ?? 0) >= 10).length;

  /// Failed count (average < 10)
  int get failedCount =>
      students.where((s) => (s.annualAverage ?? 0) < 10).length;

  /// Get top student
  StudentResult? get topStudent {
    if (students.isEmpty) return null;
    final sorted = List<StudentResult>.from(students);
    sorted.sort((a, b) {
      final avgA = a.annualAverage ?? 0;
      final avgB = b.annualAverage ?? 0;
      return avgB.compareTo(avgA);
    });
    return sorted.first;
  }

  /// Class average
  double? get classAverage {
    final averages = students
        .map((s) => s.annualAverage)
        .whereType<double>()
        .toList();
    if (averages.isEmpty) return null;
    return averages.reduce((a, b) => a + b) / averages.length;
  }

  /// Highest average
  double? get highestAverage {
    final averages = students
        .map((s) => s.annualAverage)
        .whereType<double>()
        .toList();
    if (averages.isEmpty) return null;
    return averages.reduce((a, b) => a > b ? a : b);
  }

  /// Lowest average
  double? get lowestAverage {
    final averages = students
        .map((s) => s.annualAverage)
        .whereType<double>()
        .toList();
    if (averages.isEmpty) return null;
    return averages.reduce((a, b) => a < b ? a : b);
  }

  /// Success rate (average >= 10)
  double get successRate {
    if (students.isEmpty) return 0;
    final passed = students.where((s) => (s.annualAverage ?? 0) >= 10).length;
    return passed / students.length * 100;
  }

  /// Get students sorted by rank
  List<StudentResult> get rankedStudents {
    final sorted = List<StudentResult>.from(students);
    sorted.sort((a, b) {
      final avgA = a.annualAverage ?? 0;
      final avgB = b.annualAverage ?? 0;
      return avgB.compareTo(avgA);
    });

    // Assign ranks
    return sorted.asMap().entries.map((entry) {
      return StudentResult(
        studentId: entry.value.studentId,
        enrollmentId: entry.value.enrollmentId,
        studentName: entry.value.studentName,
        studentCode: entry.value.studentCode,
        photoUrl: entry.value.photoUrl,
        className: entry.value.className,
        groupName: entry.value.groupName,
        academicYearId: entry.value.academicYearId,
        academicYearName: entry.value.academicYearName,
        semesters: entry.value.semesters,
        rank: entry.key + 1,
        totalStudents: sorted.length,
      );
    }).toList();
  }

  Map<String, dynamic> toJson() => {
    'classId': classId,
    'className': className,
    'groupId': groupId,
    'groupName': groupName,
    'academicYearId': academicYearId,
    'academicYearName': academicYearName,
    'students': students.map((s) => s.toJson()).toList(),
    'classAverage': classAverage,
    'highestAverage': highestAverage,
    'lowestAverage': lowestAverage,
    'successRate': successRate,
  };
}
