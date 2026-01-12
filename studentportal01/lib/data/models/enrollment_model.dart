class EnrollmentModel {
  final String id;
  final String userId;
  final String classId;
  final String? groupId;
  final String academicYearId;
  final DateTime createdAt;
  
  // Joined data
  final ClassModel? classInfo;
  final GroupModel? groupInfo;
  final AcademicYearModel? academicYear;

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.classId,
    this.groupId,
    required this.academicYearId,
    required this.createdAt,
    this.classInfo,
    this.groupInfo,
    this.academicYear,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      classId: json['class_id'] as String,
      groupId: json['group_id'] as String?,
      academicYearId: json['academic_year_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      classInfo: json['classes'] != null 
          ? ClassModel.fromJson(json['classes'] as Map<String, dynamic>)
          : null,
      groupInfo: json['groups'] != null 
          ? GroupModel.fromJson(json['groups'] as Map<String, dynamic>)
          : null,
      academicYear: json['academic_years'] != null 
          ? AcademicYearModel.fromJson(json['academic_years'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'class_id': classId,
      'group_id': groupId,
      'academic_year_id': academicYearId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ClassModel {
  final String id;
  final String schoolId;
  final String name;
  final String? level;
  final int? year;
  final String? section;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.level,
    this.year,
    this.section,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String,
      level: json['level'] as String?,
      year: json['year'] as int?,
      section: json['section'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'level': level,
      'year': year,
      'section': section,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class GroupModel {
  final String id;
  final String classId;
  final String name;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.classId,
    required this.name,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AcademicYearModel {
  final String id;
  final String schoolId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final DateTime createdAt;

  AcademicYearModel({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.createdAt,
  });

  factory AcademicYearModel.fromJson(Map<String, dynamic> json) {
    return AcademicYearModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isCurrent: json['is_current'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_current': isCurrent,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
