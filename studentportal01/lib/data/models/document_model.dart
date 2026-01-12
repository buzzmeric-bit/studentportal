class DocumentModel {
  final String id;
  final String schoolId;
  final String? classId;
  final String title;
  final String? description;
  final String category; // administrative, courses, exams, other
  final String fileUrl;
  final String fileName;
  final int? fileSize;
  final String? mimeType;
  final String? uploadedBy;
  final DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.schoolId,
    this.classId,
    required this.title,
    this.description,
    required this.category,
    required this.fileUrl,
    required this.fileName,
    this.fileSize,
    this.mimeType,
    this.uploadedBy,
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      classId: json['class_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'class_id': classId,
      'title': title,
      'description': description,
      'category': category,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayCategory {
    switch (category) {
      case 'administrative':
        return 'Administratif';
      case 'courses':
        return 'Cours';
      case 'exams':
        return 'Examens';
      default:
        return 'Autre';
    }
  }

  String get displayFileSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isPdf => mimeType == 'application/pdf' || fileName.endsWith('.pdf');
  bool get isImage => mimeType?.startsWith('image/') ?? false;
}
