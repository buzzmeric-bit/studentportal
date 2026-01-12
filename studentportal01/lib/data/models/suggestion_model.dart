enum SuggestionStatus {
  pending,
  inReview,
  replied,
  closed,
}

// Tunisian school suggestion types
enum SuggestionType {
  general,          // Général
  reclamationNote,  // Réclamation note
  absence,          // Absence
  paiement,         // Paiement
  emploiTemps,      // Problème emploi du temps
  vieScolaire,      // Vie scolaire
  autre,            // Autre
}

class SuggestionAttachment {
  final String id;
  final String suggestionId;
  final String fileUrl;
  final String fileName;
  final String? fileType;
  final int? fileSize;
  final DateTime createdAt;

  SuggestionAttachment({
    required this.id,
    required this.suggestionId,
    required this.fileUrl,
    required this.fileName,
    this.fileType,
    this.fileSize,
    required this.createdAt,
  });

  factory SuggestionAttachment.fromJson(Map<String, dynamic> json) {
    return SuggestionAttachment(
      id: json['id'] as String,
      suggestionId: json['suggestion_id'] as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isImage {
    final type = fileType?.toLowerCase() ?? '';
    return type.startsWith('image/') || 
           fileName.toLowerCase().endsWith('.jpg') ||
           fileName.toLowerCase().endsWith('.jpeg') ||
           fileName.toLowerCase().endsWith('.png') ||
           fileName.toLowerCase().endsWith('.gif') ||
           fileName.toLowerCase().endsWith('.webp');
  }
}

class SuggestionModel {
  final String id;
  final String studentId;
  final String subject;
  final String body;
  final String? attachmentUrl;
  final String? attachmentName;
  final SuggestionStatus status;
  final SuggestionType suggestionType;
  final String? classId;
  final String? groupId;
  final String? enrollmentId;
  final String? studentCode;
  final String? studentName;
  final String? className;
  final bool hasAttachment;
  final DateTime submittedAt;
  final DateTime createdAt;
  final List<SuggestionReplyModel> replies;
  final List<SuggestionAttachment> attachments;

  SuggestionModel({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.body,
    this.attachmentUrl,
    this.attachmentName,
    required this.status,
    this.suggestionType = SuggestionType.general,
    this.classId,
    this.groupId,
    this.enrollmentId,
    this.studentCode,
    this.studentName,
    this.className,
    this.hasAttachment = false,
    required this.submittedAt,
    required this.createdAt,
    this.replies = const [],
    this.attachments = const [],
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json, {List<SuggestionAttachment>? attachments}) {
    SuggestionStatus parseStatus(String status) {
      switch (status) {
        case 'pending':
          return SuggestionStatus.pending;
        case 'sent': // Original DB enum value - treat as pending
          return SuggestionStatus.pending;
        case 'in_review':
          return SuggestionStatus.inReview;
        case 'read': // Original DB enum value - treat as in review
          return SuggestionStatus.inReview;
        case 'replied':
          return SuggestionStatus.replied;
        case 'closed':
          return SuggestionStatus.closed;
        default:
          return SuggestionStatus.pending;
      }
    }

    SuggestionType parseType(String? type) {
      switch (type) {
        case 'reclamation_note':
          return SuggestionType.reclamationNote;
        case 'absence':
          return SuggestionType.absence;
        case 'paiement':
          return SuggestionType.paiement;
        case 'emploi_temps':
          return SuggestionType.emploiTemps;
        case 'vie_scolaire':
          return SuggestionType.vieScolaire;
        case 'autre':
          return SuggestionType.autre;
        default:
          return SuggestionType.general;
      }
    }

    return SuggestionModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      subject: json['subject'] as String? ?? json['title'] as String? ?? 'Sans sujet',
      body: json['message'] as String? ?? json['body'] as String? ?? json['content'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      status: parseStatus(json['status'] as String? ?? 'pending'),
      suggestionType: parseType(json['suggestion_type'] as String?),
      classId: json['class_id'] as String?,
      groupId: json['group_id'] as String?,
      enrollmentId: json['enrollment_id'] as String?,
      studentCode: json['student_code'] as String?,
      studentName: json['student_name'] as String?,
      className: json['class_name'] as String?,
      hasAttachment: json['has_attachment'] as bool? ?? false,
      submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? '') ?? 
                   DateTime.tryParse(json['created_at']?.toString() ?? '') ?? 
                   DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      replies: json['suggestion_replies'] != null
          ? (json['suggestion_replies'] as List)
              .map((e) => SuggestionReplyModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      attachments: attachments ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    String statusToString(SuggestionStatus status) {
      switch (status) {
        case SuggestionStatus.pending:
          return 'pending';
        case SuggestionStatus.inReview:
          return 'in_review';
        case SuggestionStatus.replied:
          return 'replied';
        case SuggestionStatus.closed:
          return 'closed';
      }
    }

    String typeToString(SuggestionType type) {
      switch (type) {
        case SuggestionType.reclamationNote:
          return 'reclamation_note';
        case SuggestionType.absence:
          return 'absence';
        case SuggestionType.paiement:
          return 'paiement';
        case SuggestionType.emploiTemps:
          return 'emploi_temps';
        case SuggestionType.vieScolaire:
          return 'vie_scolaire';
        case SuggestionType.autre:
          return 'autre';
        default:
          return 'general';
      }
    }

    return {
      'id': id,
      'student_id': studentId,
      'subject': subject,
      'body': body,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'status': statusToString(status),
      'suggestion_type': typeToString(suggestionType),
      'class_id': classId,
      'group_id': groupId,
      'enrollment_id': enrollmentId,
      'student_code': studentCode,
      'student_name': studentName,
      'class_name': className,
      'has_attachment': hasAttachment,
      'submitted_at': submittedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Get label for suggestion type
  String get typeLabel {
    switch (suggestionType) {
      case SuggestionType.reclamationNote:
        return 'Réclamation note';
      case SuggestionType.absence:
        return 'Absence';
      case SuggestionType.paiement:
        return 'Paiement';
      case SuggestionType.emploiTemps:
        return 'Emploi du temps';
      case SuggestionType.vieScolaire:
        return 'Vie scolaire';
      case SuggestionType.autre:
        return 'Autre';
      default:
        return 'Général';
    }
  }
}

class SuggestionReplyModel {
  final String id;
  final String suggestionId;
  final String? adminId;
  final String? adminName;
  final String body;
  final DateTime repliedAt;
  final DateTime createdAt;

  SuggestionReplyModel({
    required this.id,
    required this.suggestionId,
    this.adminId,
    this.adminName,
    required this.body,
    required this.repliedAt,
    required this.createdAt,
  });

  factory SuggestionReplyModel.fromJson(Map<String, dynamic> json) {
    return SuggestionReplyModel(
      id: json['id'] as String,
      suggestionId: json['suggestion_id'] as String,
      adminId: json['admin_id'] as String?,
      adminName: json['admin_name'] as String?,
      body: json['body'] as String,
      repliedAt: DateTime.parse(json['replied_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suggestion_id': suggestionId,
      'admin_id': adminId,
      'admin_name': adminName,
      'body': body,
      'replied_at': repliedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
