class CourseModel {
  final String id;
  final String schoolId;
  final String classId;
  final String? groupId;
  final String subject;
  final String? teacherId;
  final String teacherName;
  final String title;
  final String? description;
  final String? externalLink;
  final DateTime publishedAt;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  
  // Related data (loaded separately)
  final List<CourseAttachmentModel>? attachments;
  final bool? isViewed; // If the current student has viewed this course

  CourseModel({
    required this.id,
    required this.schoolId,
    required this.classId,
    this.groupId,
    required this.subject,
    this.teacherId,
    required this.teacherName,
    required this.title,
    this.description,
    this.externalLink,
    required this.publishedAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublished,
    this.attachments,
    this.isViewed,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      classId: json['class_id'] as String,
      groupId: json['group_id'] as String?,
      subject: json['subject'] as String,
      teacherId: json['teacher_id'] as String?,
      teacherName: json['teacher_name'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      externalLink: json['external_link'] as String?,
      publishedAt: DateTime.parse(json['published_at'] as String),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPublished: json['is_published'] as bool? ?? true,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => CourseAttachmentModel.fromJson(a))
              .toList()
          : null,
      isViewed: json['is_viewed'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'class_id': classId,
      'group_id': groupId,
      'subject': subject,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'title': title,
      'description': description,
      'external_link': externalLink,
      'published_at': publishedAt.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_published': isPublished,
      if (attachments != null) 'attachments': attachments!.map((a) => a.toJson()).toList(),
      if (isViewed != null) 'is_viewed': isViewed,
    };
  }

  CourseModel copyWith({
    String? id,
    String? schoolId,
    String? classId,
    String? groupId,
    String? subject,
    String? teacherId,
    String? teacherName,
    String? title,
    String? description,
    String? externalLink,
    DateTime? publishedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    List<CourseAttachmentModel>? attachments,
    bool? isViewed,
  }) {
    return CourseModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      groupId: groupId ?? this.groupId,
      subject: subject ?? this.subject,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      title: title ?? this.title,
      description: description ?? this.description,
      externalLink: externalLink ?? this.externalLink,
      publishedAt: publishedAt ?? this.publishedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      attachments: attachments ?? this.attachments,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
  
  int get attachmentCount => attachments?.length ?? 0;
  
  List<CourseAttachmentModel> get imageAttachments {
    if (attachments == null) return [];
    return attachments!.where((a) => a.isImage).toList();
  }
  
  List<CourseAttachmentModel> get documentAttachments {
    if (attachments == null) return [];
    return attachments!.where((a) => !a.isImage).toList();
  }
}

class CourseAttachmentModel {
  final String id;
  final String courseId;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;
  final DateTime createdAt;

  CourseAttachmentModel({
    required this.id,
    required this.courseId,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
  });

  factory CourseAttachmentModel.fromJson(Map<String, dynamic> json) {
    return CourseAttachmentModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CourseAttachmentModel copyWith({
    String? id,
    String? courseId,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return CourseAttachmentModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isImage {
    final lowerType = fileType.toLowerCase();
    return lowerType.contains('image') ||
        lowerType == 'image/jpeg' ||
        lowerType == 'image/jpg' ||
        lowerType == 'image/png' ||
        lowerType == 'image/gif' ||
        lowerType == 'image/webp';
  }

  bool get isPdf {
    return fileType.toLowerCase().contains('pdf');
  }

  bool get isDocument {
    final lowerType = fileType.toLowerCase();
    return lowerType.contains('document') ||
        lowerType.contains('word') ||
        lowerType.contains('msword') ||
        lowerType.contains('doc') ||
        lowerType.contains('docx');
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }
}

class CourseViewModel {
  final String id;
  final String courseId;
  final String studentId;
  final DateTime seenAt;

  CourseViewModel({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.seenAt,
  });

  factory CourseViewModel.fromJson(Map<String, dynamic> json) {
    return CourseViewModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      studentId: json['student_id'] as String,
      seenAt: DateTime.parse(json['seen_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'student_id': studentId,
      'seen_at': seenAt.toIso8601String(),
    };
  }
}
