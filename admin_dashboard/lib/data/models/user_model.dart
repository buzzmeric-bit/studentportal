class UserModel {
  final String id;
  final String? schoolId;
  final String role;
  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? studentCode;
  final DateTime? dateOfBirth;
  final String? address;
  final String? gender;  // 'M' for Masculin, 'F' for Féminin
  final String? nationality;  // User nationality (e.g., Tunisienne)
  final String? niveau;  // Legacy field - deprecated, use niveauCode
  final String? niveauCode;  // Educational level code (7eme, 8eme, etc.)
  final String? sectionCode;  // Section code (maths, sciences_exp, etc.)
  final String? className;  // Current class name (from enrollment)
  final String? initialPassword;  // Auto-generated password for admin reference
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.schoolId,
    required this.role,
    required this.fullName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.studentCode,
    this.dateOfBirth,
    this.address,
    this.gender,
    this.nationality,
    this.niveau,
    this.niveauCode,
    this.sectionCode,
    this.className,
    this.initialPassword,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String?,
      role: json['role'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      studentCode: json['student_code'] as String?,
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      address: json['address'] as String?,
      gender: json['gender'] as String?,
      nationality: json['nationality'] as String?,
      niveau: json['niveau'] as String?,
      niveauCode: json['niveau_code'] as String?,
      sectionCode: json['section_code'] as String?,
      className: json['class_name'] as String?,
      initialPassword: json['initial_password'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'role': role,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'photo_url': photoUrl,
      'student_code': studentCode,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'gender': gender,
      'nationality': nationality,
      'niveau': niveau,
      'niveau_code': niveauCode,
      'section_code': sectionCode,
      'class_name': className,
      'initial_password': initialPassword,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? schoolId,
    String? role,
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
    String? studentCode,
    DateTime? dateOfBirth,
    String? address,
    String? gender,
    String? nationality,
    String? niveau,
    String? niveauCode,
    String? sectionCode,
    String? className,
    String? initialPassword,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      studentCode: studentCode ?? this.studentCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      niveau: niveau ?? this.niveau,
      niveauCode: niveauCode ?? this.niveauCode,
      sectionCode: sectionCode ?? this.sectionCode,
      className: className ?? this.className,
      initialPassword: initialPassword ?? this.initialPassword,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Get gender display string
  String get genderDisplay {
    switch (gender) {
      case 'M':
        return 'Masculin';
      case 'F':
        return 'Féminin';
      default:
        return '-';
    }
  }
}
