import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';

class SemesterModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  SemesterModel({required this.id, required this.name, required this.startDate, required this.endDate, this.isCurrent = false});

  factory SemesterModel.fromJson(Map<String, dynamic> json) => SemesterModel(
    id: json['id'],
    name: json['name'] ?? '',
    startDate: DateTime.parse(json['start_date']),
    endDate: DateTime.parse(json['end_date']),
    isCurrent: json['is_current'] ?? false,
  );
}

class SemestersState {
  final List<SemesterModel> semesters;
  SemestersState({this.semesters = const []});

  SemesterModel? get current => semesters.where((s) => s.isCurrent).firstOrNull;

  SemestersState copyWith({List<SemesterModel>? semesters}) => SemestersState(semesters: semesters ?? this.semesters);
}

class SemestersNotifier extends AsyncNotifier<SemestersState> {
  @override
  Future<SemestersState> build() async => _load();

  Future<SemestersState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final data = await supabase.from('semesters').select().eq('school_id', profile['school_id']).order('start_date', ascending: false);

    return SemestersState(semesters: (data as List).map((e) => SemesterModel.fromJson(e)).toList());
  }

  Future<void> setCurrentSemester(String id) async {
    state.whenData((c) async {
      final supabase = SupabaseConfig.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();

      await supabase.from('semesters').update({'is_current': false}).eq('school_id', profile['school_id']);
      await supabase.from('semesters').update({'is_current': true}).eq('id', id);
      ref.invalidateSelf();
    });
  }

  Future<void> create({required String name, required DateTime startDate, required DateTime endDate, bool isCurrent = false}) async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();

    if (isCurrent) {
      await supabase.from('semesters').update({'is_current': false}).eq('school_id', profile['school_id']);
    }

    await supabase.from('semesters').insert({
      'name': name, 'school_id': profile['school_id'],
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_current': isCurrent,
    });
    ref.invalidateSelf();
  }

  Future<void> updateSemester({required String id, required String name, required DateTime startDate, required DateTime endDate}) async {
    await SupabaseConfig.client.from('semesters').update({
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    }).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('semesters').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

final semestersProvider = AsyncNotifierProvider<SemestersNotifier, SemestersState>(SemestersNotifier.new);
