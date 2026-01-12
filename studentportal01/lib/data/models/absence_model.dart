class AbsenceRecordModel {
  final String id;
  final String enrollmentId;
  final String subjectOfferingId;
  final DateTime date;
  final double hoursAbsent;
  final String? sessionType;
  final String? reason;
  final bool justified;
  final DateTime createdAt;

  AbsenceRecordModel({
    required this.id,
    required this.enrollmentId,
    required this.subjectOfferingId,
    required this.date,
    required this.hoursAbsent,
    this.sessionType,
    this.reason,
    required this.justified,
    required this.createdAt,
  });

  factory AbsenceRecordModel.fromJson(Map<String, dynamic> json) {
    return AbsenceRecordModel(
      id: json['id'] as String,
      enrollmentId: json['enrollment_id'] as String,
      subjectOfferingId: json['subject_offering_id'] as String,
      date: DateTime.parse(json['date'] as String),
      hoursAbsent: (json['hours_absent'] as num).toDouble(),
      sessionType: json['session_type'] as String?,
      reason: json['reason'] as String?,
      justified: json['justified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enrollment_id': enrollmentId,
      'subject_offering_id': subjectOfferingId,
      'date': date.toIso8601String().split('T')[0],
      'hours_absent': hoursAbsent,
      'session_type': sessionType,
      'reason': reason,
      'justified': justified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AbsenceThresholdModel {
  final String id;
  final String schoolId;
  final double warningPercent;
  final double criticalPercent;
  final double eliminationPercent;
  final String warningMessage;
  final String criticalMessage;
  final String eliminationMessage;
  final DateTime createdAt;

  AbsenceThresholdModel({
    required this.id,
    required this.schoolId,
    required this.warningPercent,
    required this.criticalPercent,
    required this.eliminationPercent,
    required this.warningMessage,
    required this.criticalMessage,
    required this.eliminationMessage,
    required this.createdAt,
  });

  factory AbsenceThresholdModel.fromJson(Map<String, dynamic> json) {
    return AbsenceThresholdModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      warningPercent: (json['warning_percent'] as num).toDouble(),
      criticalPercent: (json['critical_percent'] as num).toDouble(),
      eliminationPercent: (json['elimination_percent'] as num).toDouble(),
      warningMessage: json['warning_message'] as String,
      criticalMessage: json['critical_message'] as String,
      eliminationMessage: json['elimination_message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'warning_percent': warningPercent,
      'critical_percent': criticalPercent,
      'elimination_percent': eliminationPercent,
      'warning_message': warningMessage,
      'critical_message': criticalMessage,
      'elimination_message': eliminationMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SubjectAbsenceSummary {
  final String subjectOfferingId;
  final String subjectName;
  final String? subjectCode;
  final double totalHours;
  final double weeklyCiHours;
  final double weeklyTpHours;
  final int weeks;
  final double totalAbsentHours;
  final double absencePercent;
  final AbsenceLevel level;
  final String? warningMessage;

  SubjectAbsenceSummary({
    required this.subjectOfferingId,
    required this.subjectName,
    this.subjectCode,
    required this.totalHours,
    required this.weeklyCiHours,
    required this.weeklyTpHours,
    required this.weeks,
    required this.totalAbsentHours,
    required this.absencePercent,
    required this.level,
    this.warningMessage,
  });
}

enum AbsenceLevel {
  normal,
  warning,
  critical,
  eliminated,
}
