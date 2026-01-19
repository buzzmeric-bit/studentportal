// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart';
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
    
    try {
      final data = await supabase.from('timetable_slots').select('*, subject_offerings(subject_id, class_id, teacher_id, subjects(name), classes(name, school_id), users(full_name))').order('day_of_week').order('start_time');

      final slots = (data as List).map((e) => TimetableSlot.fromJson(e)).where((s) => s.className != null).toList();
      return TimetableState(slots: slots);
    } catch (e) {
      debugPrint('TimetableNotifier error: $e - using fallback');
      // Fallback: fetch slots without nested relations
      try {
        final slots = await supabase.from('timetable_slots').select('*').order('day_of_week').order('start_time');
        
        if ((slots as List).isEmpty) return TimetableState(slots: []);
        
        // Get unique subject_offering_ids
        final offeringIds = slots.map((s) => s['subject_offering_id']).where((id) => id != null).toSet().toList();
        if (offeringIds.isEmpty) return TimetableState(slots: []);
        
        final offerings = await supabase.from('subject_offerings').select('id, subject_id, class_id, teacher_id').inFilter('id', offeringIds);
        
        Map<String, dynamic> offeringsMap = {};
        for (var o in (offerings as List)) {
          offeringsMap[o['id']] = o;
        }
        
        // Get subjects, classes, teachers
        final subjectIds = (offerings).map((o) => o['subject_id']).where((id) => id != null).toSet().toList();
        final classIds = (offerings).map((o) => o['class_id']).where((id) => id != null).toSet().toList();
        final teacherIds = (offerings).map((o) => o['teacher_id']).where((id) => id != null).toSet().toList();
        
        Map<String, dynamic> subjectsMap = {};
        Map<String, dynamic> classesMap = {};
        Map<String, dynamic> teachersMap = {};
        
        if (subjectIds.isNotEmpty) {
          final subjects = await supabase.from('subjects').select('id, name').inFilter('id', subjectIds);
          for (var s in (subjects as List)) {
            subjectsMap[s['id']] = s;
          }
        }
        if (classIds.isNotEmpty) {
          final classes = await supabase.from('classes').select('id, name, school_id').inFilter('id', classIds);
          for (var c in (classes as List)) {
            classesMap[c['id']] = c;
          }
        }
        if (teacherIds.isNotEmpty) {
          final teachers = await supabase.from('users').select('id, full_name').inFilter('id', teacherIds);
          for (var t in (teachers as List)) {
            teachersMap[t['id']] = t;
          }
        }
        
        final result = slots.map((slot) {
          final offering = offeringsMap[slot['subject_offering_id']];
          final subject = offering != null ? subjectsMap[offering['subject_id']] : null;
          final cls = offering != null ? classesMap[offering['class_id']] : null;
          final teacher = offering != null ? teachersMap[offering['teacher_id']] : null;
          
          return TimetableSlot(
            id: slot['id']?.toString() ?? '',
            subjectOfferingId: slot['subject_offering_id']?.toString() ?? '',
            dayOfWeek: slot['day_of_week'] ?? 1,
            startTime: slot['start_time']?.toString() ?? '08:00',
            endTime: slot['end_time']?.toString() ?? '09:00',
            room: slot['room']?.toString(),
            subjectName: subject?['name']?.toString(),
            className: cls?['name']?.toString(),
            teacherName: teacher?['full_name']?.toString(),
          );
        }).where((s) => s.className != null).toList();
        
        return TimetableState(slots: result);
      } catch (e2) {
        debugPrint('TimetableNotifier fallback error: $e2');
        return TimetableState(slots: []);
      }
    }
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