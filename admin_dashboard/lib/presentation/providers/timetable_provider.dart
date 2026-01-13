// ignore_for_file: unused_local_variable

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';

class TimetableSlot {
  final String id;
  final String subjectOfferingId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String? subjectName;
  final String? className;
  final String? teacherName;

  TimetableSlot({required this.id, required this.subjectOfferingId, required this.dayOfWeek, required this.startTime, required this.endTime, this.room, this.subjectName, this.className, this.teacherName});

  factory TimetableSlot.fromJson(Map<String, dynamic> json) => TimetableSlot(
    id: json['id']?.toString() ?? '',
    subjectOfferingId: json['subject_offering_id']?.toString() ?? '',
    dayOfWeek: json['day_of_week'] ?? 1,
    startTime: json['start_time']?.toString() ?? '08:00',
    endTime: json['end_time']?.toString() ?? '09:00',
    room: json['room']?.toString(),
    subjectName: json['subject_offerings']?['subjects']?['name']?.toString(),
    className: json['subject_offerings']?['classes']?['name']?.toString(),
    teacherName: json['subject_offerings']?['users']?['full_name']?.toString(),
  );
}

class TimetableState {
  final List<TimetableSlot> slots;
  final String? selectedClassId;
  TimetableState({this.slots = const [], this.selectedClassId});

  TimetableState copyWith({List<TimetableSlot>? slots, String? selectedClassId}) =>
    TimetableState(slots: slots ?? this.slots, selectedClassId: selectedClassId ?? this.selectedClassId);
}

class TimetableNotifier extends AsyncNotifier<TimetableState> {
  @override
  Future<TimetableState> build() async => _load();

  Future<TimetableState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecte');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final data = await supabase.from('timetable_slots').select('*, subject_offerings(subjects(name), classes(name, school_id), users(full_name))').order('day_of_week').order('start_time');

    final slots = (data as List).map((e) => TimetableSlot.fromJson(e)).where((s) => s.className != null).toList();
    return TimetableState(slots: slots);
  }

  Future<void> create({required String subjectOfferingId, required int dayOfWeek, required String startTime, required String endTime, String? room}) async {
    await SupabaseConfig.client.from('timetable_slots').insert({'subject_offering_id': subjectOfferingId, 'day_of_week': dayOfWeek, 'start_time': startTime, 'end_time': endTime, 'room': room});
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('timetable_slots').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

final timetableProvider = AsyncNotifierProvider<TimetableNotifier, TimetableState>(TimetableNotifier.new);