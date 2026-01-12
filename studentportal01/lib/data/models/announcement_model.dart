/// Attachment model for announcement attachments
class AnnouncementAttachment {
  final String id;
  final String announcementId;
  final String scope;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? fileSize;
  final DateTime createdAt;

  AnnouncementAttachment({
    required this.id,
    required this.announcementId,
    required this.scope,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.fileSize,
    required this.createdAt,
  });

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) {
    return AnnouncementAttachment(
      id: json['id'] as String,
      announcementId: json['announcement_id'] as String,
      scope: json['scope'] as String? ?? 'global',
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isImage => fileType?.startsWith('image/') ?? false;
}

class AnnouncementGlobalModel {
  final String id;
  final String schoolId;
  final String title;
  final String body;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool isImportant;
  final bool isPinned;
  final bool hasAttachment;
  final DateTime publishedAt;
  final String? createdBy;
  final String? announcementType;
  final String? senderType;
  final String? senderLabel;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final List<AnnouncementAttachment> attachments;

  AnnouncementGlobalModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.body,
    this.attachmentUrl,
    this.attachmentName,
    required this.isImportant,
    this.isPinned = false,
    this.hasAttachment = false,
    required this.publishedAt,
    this.createdBy,
    this.announcementType,
    this.senderType,
    this.senderLabel,
    this.payload,
    required this.createdAt,
    this.deletedAt,
    this.attachments = const [],
  });

  /// Get image attachments for inline display
  List<AnnouncementAttachment> get imageAttachments => 
      attachments.where((a) => a.isImage).toList();

  /// Get non-image attachments for download links
  List<AnnouncementAttachment> get fileAttachments => 
      attachments.where((a) => !a.isImage).toList();

  factory AnnouncementGlobalModel.fromJson(Map<String, dynamic> json, {List<AnnouncementAttachment>? attachments}) {
    return AnnouncementGlobalModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      isImportant: json['is_important'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      hasAttachment: json['has_attachment'] as bool? ?? false,
      publishedAt: DateTime.parse(json['published_at'] as String),
      createdBy: json['created_by'] as String?,
      announcementType: json['announcement_type'] as String?,
      senderType: json['sender_type'] as String?,
      senderLabel: json['sender_label'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      attachments: attachments ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'title': title,
      'body': body,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'is_important': isImportant,
      'is_pinned': isPinned,
      'published_at': publishedAt.toIso8601String(),
      'created_by': createdBy,
      'announcement_type': announcementType,
      'sender_type': senderType,
      'sender_label': senderLabel,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

class AnnouncementClassModel {
  final String id;
  final String classId;
  final String? groupId;
  final String title;
  final String body;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool isImportant;
  final bool isPinned;
  final bool hasAttachment;
  final DateTime publishedAt;
  final String? createdBy;
  final String? authorId;
  final String? authorName;
  final String? senderType;
  final String? senderLabel;
  final String? senderAvatarText;
  final String? announcementType;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final List<AnnouncementAttachment> attachments;

  AnnouncementClassModel({
    required this.id,
    required this.classId,
    this.groupId,
    required this.title,
    required this.body,
    this.attachmentUrl,
    this.attachmentName,
    required this.isImportant,
    this.isPinned = false,
    this.hasAttachment = false,
    required this.publishedAt,
    this.createdBy,
    this.authorId,
    this.authorName,
    this.senderType,
    this.senderLabel,
    this.senderAvatarText,
    this.announcementType,
    this.payload,
    required this.createdAt,
    this.deletedAt,
    this.attachments = const [],
  });

  /// Get display name for sender (use senderLabel if available, fallback to authorName)
  String get displaySenderName => senderLabel ?? authorName ?? 'Administration';
  
  /// Get avatar text
  String get avatarText => senderAvatarText ?? (displaySenderName.isNotEmpty ? displaySenderName[0].toUpperCase() : 'A');

  /// Get image attachments for inline display
  List<AnnouncementAttachment> get imageAttachments => 
      attachments.where((a) => a.isImage).toList();

  /// Get non-image attachments for download links
  List<AnnouncementAttachment> get fileAttachments => 
      attachments.where((a) => !a.isImage).toList();

  factory AnnouncementClassModel.fromJson(Map<String, dynamic> json, {List<AnnouncementAttachment>? attachments}) {
    return AnnouncementClassModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      groupId: json['group_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      isImportant: json['is_important'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      hasAttachment: json['has_attachment'] as bool? ?? false,
      publishedAt: DateTime.parse(json['published_at'] as String),
      createdBy: json['created_by'] as String?,
      authorId: json['author_id'] as String?,
      authorName: json['author_name'] as String?,
      senderType: json['sender_type'] as String?,
      senderLabel: json['sender_label'] as String?,
      senderAvatarText: json['sender_avatar_text'] as String?,
      announcementType: json['announcement_type'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      attachments: attachments ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'group_id': groupId,
      'title': title,
      'body': body,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'is_important': isImportant,
      'is_pinned': isPinned,
      'published_at': publishedAt.toIso8601String(),
      'created_by': createdBy,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
