import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/school_models.dart';

class SubjectsState {
  final List<SubjectModel> subjects;
  final String searchQuery;
  SubjectsState({this.subjects = const [], this.searchQuery = ''});

  List<SubjectModel> get filtered => searchQuery.isEmpty ? subjects : subjects.where((s) => s.name.toLowerCase().contains(searchQuery.toLowerCase()) || (s.code?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)).toList();

  SubjectsState copyWith({List<SubjectModel>? subjects, String? searchQuery}) =>
    SubjectsState(subjects: subjects ?? this.subjects, searchQuery: searchQuery ?? this.searchQuery);
}

class SubjectsNotifier extends AsyncNotifier<SubjectsState> {
  @override
  Future<SubjectsState> build() async => _load();

  Future<SubjectsState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecte');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final data = await supabase.from('subjects').select().eq('school_id', profile['school_id']).order('name');

    return SubjectsState(subjects: (data as List).map((e) => SubjectModel.fromJson(e)).toList());
  }

  void setSearch(String query) {
    state.whenData((s) => state = AsyncData(s.copyWith(searchQuery: query)));
  }

  Future<void> create({required String name, String? code, String? description}) async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecte');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    await supabase.from('subjects').insert({'school_id': profile['school_id'], 'name': name, 'code': code, 'description': description});
    ref.invalidateSelf();
  }

  Future<void> updateSubject({required String id, required String name, String? code, String? description}) async {
    await SupabaseConfig.client.from('subjects').update({'name': name, 'code': code, 'description': description}).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('subjects').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

final subjectsProvider = AsyncNotifierProvider<SubjectsNotifier, SubjectsState>(SubjectsNotifier.new);