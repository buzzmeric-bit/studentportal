class DashboardKpis {
  final int totalStudents;
  final int totalTeachers;
  final int totalStaff;
  final int totalClasses;
  final int openSuggestions;
  final double totalPaymentsDue;
  final double totalPaymentsCollected;
  final double attendanceRate;
  final int studentsAtRisk;
  final double avgSemesterGrade;

  DashboardKpis({
    this.totalStudents = 0,
    this.totalTeachers = 0,
    this.totalStaff = 0,
    this.totalClasses = 0,
    this.openSuggestions = 0,
    this.totalPaymentsDue = 0,
    this.totalPaymentsCollected = 0,
    this.attendanceRate = 100,
    this.studentsAtRisk = 0,
    this.avgSemesterGrade = 0,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) => DashboardKpis(
    totalStudents: json['total_students'] ?? 0,
    totalTeachers: json['total_teachers'] ?? 0,
    totalStaff: json['total_staff'] ?? 0,
    totalClasses: json['total_classes'] ?? 0,
    openSuggestions: json['open_suggestions'] ?? 0,
    totalPaymentsDue: (json['total_payments_due'] ?? 0).toDouble(),
    totalPaymentsCollected: (json['total_payments_collected'] ?? 0).toDouble(),
    attendanceRate: (json['attendance_rate'] ?? 100).toDouble(),
    studentsAtRisk: json['students_at_risk'] ?? 0,
    avgSemesterGrade: (json['avg_semester_grade'] ?? 0).toDouble(),
  );

  double get paymentProgress => totalPaymentsDue > 0 ? (totalPaymentsCollected / totalPaymentsDue * 100) : 0;
  double get outstandingPayments => totalPaymentsDue - totalPaymentsCollected;
}

class AtRiskStudent {
  final String studentName;
  final String? studentCode;
  final String className;
  final String subjectName;
  final double absencePercent;
  final String status;

  AtRiskStudent({required this.studentName, this.studentCode, required this.className, required this.subjectName, required this.absencePercent, required this.status});

  factory AtRiskStudent.fromJson(Map<String, dynamic> json) => AtRiskStudent(
    studentName: json['student_name'] ?? '',
    studentCode: json['student_code'],
    className: json['class_name'] ?? '',
    subjectName: json['subject_name'] ?? '',
    absencePercent: (json['absence_percent'] ?? 0).toDouble(),
    status: json['status'] ?? 'ok',
  );
}

class AbsenceTrend {
  final DateTime date;
  final String className;
  final String subjectName;
  final double totalHoursAbsent;
  final int studentsAbsent;

  AbsenceTrend({required this.date, required this.className, required this.subjectName, required this.totalHoursAbsent, required this.studentsAbsent});

  factory AbsenceTrend.fromJson(Map<String, dynamic> json) => AbsenceTrend(
    date: DateTime.parse(json['date']),
    className: json['class_name'] ?? '',
    subjectName: json['subject_name'] ?? '',
    totalHoursAbsent: (json['total_hours_absent'] ?? 0).toDouble(),
    studentsAbsent: json['students_absent'] ?? 0,
  );
}

class GradeDistribution {
  final String semesterName;
  final String className;
  final String subjectName;
  final String gradeRange;
  final int studentCount;

  GradeDistribution({required this.semesterName, required this.className, required this.subjectName, required this.gradeRange, required this.studentCount});

  factory GradeDistribution.fromJson(Map<String, dynamic> json) => GradeDistribution(
    semesterName: json['semester_name'] ?? '',
    className: json['class_name'] ?? '',
    subjectName: json['subject_name'] ?? '',
    gradeRange: json['grade_range'] ?? '',
    studentCount: json['student_count'] ?? 0,
  );
}

class PaymentSummary {
  final String studentName;
  final String? studentCode;
  final String className;
  final String planType;
  final double amountTotal;
  final double amountPaid;
  final double amountRemaining;
  final String currency;

  PaymentSummary({required this.studentName, this.studentCode, required this.className, required this.planType, required this.amountTotal, required this.amountPaid, required this.amountRemaining, required this.currency});

  factory PaymentSummary.fromJson(Map<String, dynamic> json) => PaymentSummary(
    studentName: json['student_name'] ?? '',
    studentCode: json['student_code'],
    className: json['class_name'] ?? '',
    planType: json['plan_type'] ?? '',
    amountTotal: (json['amount_total'] ?? 0).toDouble(),
    amountPaid: (json['amount_paid'] ?? 0).toDouble(),
    amountRemaining: (json['amount_remaining'] ?? 0).toDouble(),
    currency: json['currency'] ?? 'DZD',
  );
}
