import 'package:equatable/equatable.dart';

enum AnnouncementScope { global, classScope }

enum AnnouncementType { general, teacherAbsent, roomChange, reminder, exam, closure }

enum SenderType { administration, teacher }

/// Type alias for backward compatibility
typedef Attachment = AnnouncementAttachment;

class Announcement extends Equatable {
  final String id;
  final AnnouncementScope scope;
  final String? schoolId;
  final String? classId;
  final String? groupId;
  final String title;
  final String body;
  final bool isImportant;
  final bool isPinned;
  final AnnouncementType announcementType;
  final SenderType senderType;
  final String? senderLabel;
  final String? senderAvatarText;
  final DateTime? publishedAt;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? createdBy;
  final DateTime createdAt;
  final List<AnnouncementAttachment> attachments;
  final Map<String, dynamic> payload; // Type-specific structured fields

  const Announcement({
    required this.id,
    required this.scope,
    this.schoolId,
    this.classId,
    this.groupId,
    required this.title,
    required this.body,
    this.isImportant = false,
    this.isPinned = false,
    this.announcementType = AnnouncementType.general,
    this.senderType = SenderType.administration,
    this.senderLabel,
    this.senderAvatarText,
    this.publishedAt,
    this.attachmentUrl,
    this.attachmentName,
    this.createdBy,
    required this.createdAt,
    this.attachments = const [],
    this.payload = const {},
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      scope: json['scope'] == 'global' 
          ? AnnouncementScope.global 
          : AnnouncementScope.classScope,
      schoolId: json['school_id'] as String?,
      classId: json['class_id'] as String?,
      groupId: json['group_id'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isImportant: json['is_important'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      announcementType: _parseAnnouncementType(json['announcement_type']),
      senderType: json['sender_type'] == 'teacher' 
          ? SenderType.teacher 
          : SenderType.administration,
      senderLabel: json['sender_label'] as String?,
      senderAvatarText: json['sender_avatar_text'] as String?,
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at']) 
          : null,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJsonForGlobal() {
    return {
      'school_id': schoolId,
      'title': title,
      'body': body,
      'is_important': isImportant,
      'is_pinned': isPinned,
      'announcement_type': announcementType.toValue(),
      'sender_type': senderType.toValue(),
      'sender_label': senderLabel,
      'sender_avatar_text': senderAvatarText,
      'published_at': publishedAt?.toIso8601String(),
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'created_by': createdBy,
      'payload': payload,
    };
  }

  Map<String, dynamic> toJsonForClass() {
    return {
      'class_id': classId,
      'group_id': groupId,
      'title': title,
      'body': body,
      'is_important': isImportant,
      'is_pinned': isPinned,
      'announcement_type': announcementType.toValue(),
      'sender_type': senderType.toValue(),
      'sender_label': senderLabel,
      'sender_avatar_text': senderAvatarText,
      'published_at': publishedAt?.toIso8601String(),
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'created_by': createdBy,
      'payload': payload,
    };
  }

  Announcement copyWith({
    String? id,
    AnnouncementScope? scope,
    String? schoolId,
    String? classId,
    String? groupId,
    String? title,
    String? body,
    bool? isImportant,
    bool? isPinned,
    AnnouncementType? announcementType,
    SenderType? senderType,
    String? senderLabel,
    String? senderAvatarText,
    DateTime? publishedAt,
    String? attachmentUrl,
    String? attachmentName,
    String? createdBy,
    DateTime? createdAt,
    List<AnnouncementAttachment>? attachments,
    Map<String, dynamic>? payload,
  }) {
    return Announcement(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      body: body ?? this.body,
      isImportant: isImportant ?? this.isImportant,
      isPinned: isPinned ?? this.isPinned,
      announcementType: announcementType ?? this.announcementType,
      senderType: senderType ?? this.senderType,
      senderLabel: senderLabel ?? this.senderLabel,
      senderAvatarText: senderAvatarText ?? this.senderAvatarText,
      publishedAt: publishedAt ?? this.publishedAt,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      payload: payload ?? this.payload,
    );
  }

  static AnnouncementType _parseAnnouncementType(String? value) {
    switch (value) {
      case 'teacher_absent': return AnnouncementType.teacherAbsent;
      case 'room_change': return AnnouncementType.roomChange;
      case 'reminder': return AnnouncementType.reminder;
      case 'exam': return AnnouncementType.exam;
      case 'closure': return AnnouncementType.closure;
      default: return AnnouncementType.general;
    }
  }

  @override
  List<Object?> get props => [id, scope, title, body, isImportant, isPinned, createdAt];
}

class AnnouncementAttachment extends Equatable {
  final String id;
  final String scope;
  final String announcementId;
  final String fileUrl;
  final String fileName;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime createdAt;

  const AnnouncementAttachment({
    required this.id,
    required this.scope,
    required this.announcementId,
    required this.fileUrl,
    required this.fileName,
    this.mimeType,
    this.sizeBytes,
    required this.createdAt,
  });

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) {
    return AnnouncementAttachment(
      id: json['id'] as String,
      scope: json['scope'] as String,
      announcementId: json['announcement_id'] as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String?,
      sizeBytes: json['size_bytes'] as int?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scope': scope,
      'announcement_id': announcementId,
      'file_url': fileUrl,
      'file_name': fileName,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
    };
  }

  @override
  List<Object?> get props => [id, announcementId, fileUrl];
}

extension AnnouncementTypeExtension on AnnouncementType {
  String toValue() {
    switch (this) {
      case AnnouncementType.teacherAbsent: return 'teacher_absent';
      case AnnouncementType.roomChange: return 'room_change';
      case AnnouncementType.reminder: return 'reminder';
      case AnnouncementType.exam: return 'exam';
      case AnnouncementType.closure: return 'closure';
      default: return 'general';
    }
  }

  String get label {
    switch (this) {
      case AnnouncementType.teacherAbsent: return 'Absence enseignant';
      case AnnouncementType.roomChange: return 'Changement de salle';
      case AnnouncementType.reminder: return 'Rappel';
      case AnnouncementType.exam: return 'Examen';
      case AnnouncementType.closure: return 'Fermeture';
      default: return 'Général';
    }
  }
}

extension SenderTypeExtension on SenderType {
  String toValue() => this == SenderType.teacher ? 'teacher' : 'administration';
  String get label => this == SenderType.teacher ? 'Enseignant' : 'Administration';
}
