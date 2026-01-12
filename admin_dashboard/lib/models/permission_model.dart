import 'package:equatable/equatable.dart';

class Permission extends Equatable {
  final String code;
  final String label;
  final String groupName;

  const Permission({
    required this.code,
    required this.label,
    required this.groupName,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      code: json['code'] as String,
      label: json['label'] as String,
      groupName: json['group_name'] as String,
    );
  }

  @override
  List<Object?> get props => [code];
}

class ManagerPermission extends Equatable {
  final String id;
  final String managerId;
  final String permissionCode;
  final DateTime createdAt;

  const ManagerPermission({
    required this.id,
    required this.managerId,
    required this.permissionCode,
    required this.createdAt,
  });

  factory ManagerPermission.fromJson(Map<String, dynamic> json) {
    return ManagerPermission(
      id: json['id'] as String,
      managerId: json['manager_id'] as String,
      permissionCode: json['permission_code'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, managerId, permissionCode];
}

/// Permission codes as constants for type-safe usage
class PermissionCodes {
  static const announcementsRead = 'announcements.read';
  static const announcementsCreate = 'announcements.create';
  static const announcementsEdit = 'announcements.edit';
  static const announcementsDelete = 'announcements.delete';
  
  static const studentsRead = 'students.read';
  static const studentsCreate = 'students.create';
  static const studentsEdit = 'students.edit';
  static const studentsDelete = 'students.delete';
  
  static const classesRead = 'classes.read';
  static const classesCreate = 'classes.create';
  static const classesEdit = 'classes.edit';
  static const classesDelete = 'classes.delete';
  
  static const teachersRead = 'teachers.read';
  static const teachersCreate = 'teachers.create';
  static const teachersEdit = 'teachers.edit';
  static const teachersDelete = 'teachers.delete';
  
  static const settingsRead = 'settings.read';
  static const settingsEdit = 'settings.edit';
  
  static const managersRead = 'managers.read';
  static const managersCreate = 'managers.create';
  static const managersEdit = 'managers.edit';
  static const managersDelete = 'managers.delete';
}
