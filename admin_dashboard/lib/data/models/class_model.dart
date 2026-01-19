class ClassModel {
  final String id;
  final String schoolId;
  final String name;
  final String? groupId;
  final String? groupName;
  final String? gradeLevelId;
  final String? gradeLevelName;
  final String? sectionId;
  final String? sectionName;
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
    this.gradeLevelId,
    this.gradeLevelName,
    this.sectionId,
    this.sectionName,
    this.room,
    this.capacity,
    this.level,
    this.year,
    this.section,
    this.createdAt,
    this.studentCount = 0,
  });

  // Helper to extract name from related object (handles null, Map, or List)
  static String? _extractName(dynamic data) {
    if (data == null) return null;
    if (data is Map) return data['name']?.toString();
    if (data is List && data.isNotEmpty) return data[0]['name']?.toString();
    return null;
  }

  // Helper to safely parse int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
    id: json['id']?.toString() ?? '',
    schoolId: json['school_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    groupId: json['group_id']?.toString(),
    groupName: _extractName(json['groups']),
    gradeLevelId:
        json['niveau_id']?.toString() ?? json['grade_level_id']?.toString(),
    gradeLevelName:
        _extractName(json['niveaux']) ?? _extractName(json['grade_levels']),
    sectionId: json['section_id']?.toString(),
    sectionName: _extractName(json['sections']),
    room: json['room']?.toString(),
    capacity: _parseInt(json['capacity']),
    level: json['level']?.toString(),
    year: _parseInt(json['year']),
    section: json['section']?.toString(),
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    studentCount:
        _parseInt(json['students_count']) ??
        _parseInt(json['student_count']) ??
        0,
  );

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    'niveau_id': gradeLevelId,
    'section_id': sectionId,
    'room': room,
    'capacity': capacity,
    'level': level,
    'year': year,
    'section': section,
  };
}
