class GroupModel {
  final String id;
  final String classId;
  final String name;
  final DateTime? createdAt;
  final int? studentsCount;

  GroupModel({required this.id, required this.classId, required this.name, this.createdAt, this.studentsCount});

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
    id: json['id'],
    classId: json['class_id'],
    name: json['name'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    studentsCount: json['students_count'],
  );

  Map<String, dynamic> toJson() => {'class_id': classId, 'name': name};
}

class SemesterModel {
  final String id;
  final String schoolId;
  final String? academicYearId;
  final String name;
  final int number;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;

  SemesterModel({required this.id, required this.schoolId, this.academicYearId, required this.name, required this.number, this.startDate, this.endDate, this.createdAt});

  factory SemesterModel.fromJson(Map<String, dynamic> json) => SemesterModel(
    id: json['id'],
    schoolId: json['school_id'],
    academicYearId: json['academic_year_id'],
    name: json['name'],
    number: json['number'],
    startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
    endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
  );

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'academic_year_id': academicYearId,
    'name': name,
    'number': number,
    'start_date': startDate?.toIso8601String().split('T')[0],
    'end_date': endDate?.toIso8601String().split('T')[0],
  };
}

class SubjectModel {
  final String id;
  final String schoolId;
  final String name;
  final String? code;
  final String? description;
  final DateTime? createdAt;

  SubjectModel({required this.id, required this.schoolId, required this.name, this.code, this.description, this.createdAt});

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
    id: json['id'],
    schoolId: json['school_id'],
    name: json['name'],
    code: json['code'],
    description: json['description'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
  );

  Map<String, dynamic> toJson() => {'school_id': schoolId, 'name': name, 'code': code, 'description': description};
}

class EnrollmentModel {
  final String id;
  final String userId;
  final String classId;
  final String? groupId;
  final String academicYearId;
  final DateTime? createdAt;
  final String? studentName;
  final String? className;
  final String? groupName;

  EnrollmentModel({required this.id, required this.userId, required this.classId, this.groupId, required this.academicYearId, this.createdAt, this.studentName, this.className, this.groupName});

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) => EnrollmentModel(
    id: json['id'],
    userId: json['user_id'],
    classId: json['class_id'],
    groupId: json['group_id'],
    academicYearId: json['academic_year_id'],
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    studentName: json['users']?['full_name'],
    className: json['classes']?['name'],
    groupName: json['groups']?['name'],
  );

  Map<String, dynamic> toJson() => {'user_id': userId, 'class_id': classId, 'group_id': groupId, 'academic_year_id': academicYearId};
}
