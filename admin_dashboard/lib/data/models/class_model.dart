class ClassModel {
  final String id;
  final String schoolId;
  final String name;
  final String? groupId;
  final String? groupName;
  final String? room;
  final int? capacity;
  final String? level;
  final int? year;
  final String? section;
  final DateTime? createdAt;
  final int studentCount;

  ClassModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.groupId,
    this.groupName,
    this.room,
    this.capacity,
    this.level,
    this.year,
    this.section,
    this.createdAt,
    this.studentCount = 0,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
    id: json['id']?.toString() ?? '',
    schoolId: json['school_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    groupId: json['group_id']?.toString(),
    groupName: json['groups']?['name']?.toString(),
    room: json['room']?.toString(),
    capacity: json['capacity'] is int ? json['capacity'] : int.tryParse(json['capacity']?.toString() ?? ''),
    level: json['level']?.toString(),
    year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? ''),
    section: json['section']?.toString(),
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    studentCount: json['students_count'] is int ? json['students_count'] : (json['student_count'] is int ? json['student_count'] : 0),
  );

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    'group_id': groupId,
    'room': room,
    'capacity': capacity,
    'level': level,
    'year': year,
    'section': section,
  };
}