class TimetableSlotModel {
  final String id;
  final String subjectOfferingId;
  final String? groupId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String? teacherName;
  final String sessionType; // CI, TP
  final DateTime createdAt;
  
  // Joined data
  final String? subjectName;
  final String? subjectCode;

  TimetableSlotModel({
    required this.id,
    required this.subjectOfferingId,
    this.groupId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacherName,
    required this.sessionType,
    required this.createdAt,
    this.subjectName,
    this.subjectCode,
  });

  factory TimetableSlotModel.fromJson(Map<String, dynamic> json) {
    // Extract subject info from nested structure
    String? subjectName;
    String? subjectCode;
    
    if (json['subject_offerings'] != null) {
      final offering = json['subject_offerings'] as Map<String, dynamic>;
      if (offering['subjects'] != null) {
        final subject = offering['subjects'] as Map<String, dynamic>;
        subjectName = subject['name'] as String?;
        subjectCode = subject['code'] as String?;
      }
    }
    
    return TimetableSlotModel(
      id: json['id'] as String,
      subjectOfferingId: json['subject_offering_id'] as String,
      groupId: json['group_id'] as String?,
      dayOfWeek: json['day_of_week'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      room: json['room'] as String?,
      teacherName: json['teacher_name'] as String?,
      sessionType: json['session_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      subjectName: subjectName,
      subjectCode: subjectCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_offering_id': subjectOfferingId,
      'group_id': groupId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'teacher_name': teacherName,
      'session_type': sessionType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  int get dayIndex {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days.indexOf(dayOfWeek.toLowerCase());
  }

  String get displayDay {
    const dayNames = {
      'monday': 'Lundi',
      'tuesday': 'Mardi',
      'wednesday': 'Mercredi',
      'thursday': 'Jeudi',
      'friday': 'Vendredi',
      'saturday': 'Samedi',
      'sunday': 'Dimanche',
    };
    return dayNames[dayOfWeek.toLowerCase()] ?? dayOfWeek;
  }

  String get displayTime => '$startTime - $endTime';
}

class DaySchedule {
  final String dayName;
  final int dayIndex;
  final List<TimetableSlotModel> slots;

  DaySchedule({
    required this.dayName,
    required this.dayIndex,
    required this.slots,
  });
}
