import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/school_models.dart';
import '../../data/models/class_model.dart';

class GroupsState {
  final List<GroupModel> groups;
  final List<ClassModel> classes;
  final String? selectedClassId;
  GroupsState({this.groups = const [], this.classes = const [], this.selectedClassId});

  List<GroupModel> get filtered => selectedClassId == null ? groups : groups.where((g) => g.classId == selectedClassId).toList();

  GroupsState copyWith({List<GroupModel>? groups, List<ClassModel>? classes, String? selectedClassId, bool clearFilter = false}) =>
    GroupsState(groups: groups ?? this.groups, classes: classes ?? this.classes, selectedClassId: clearFilter ? null : (selectedClassId ?? this.selectedClassId));
}

class GroupsNotifier extends AsyncNotifier<GroupsState> {
  @override
  Future<GroupsState> build() async => _load();

  Future<GroupsState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecte');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final schoolId = profile['school_id'];

    final groupsData = await supabase.from('groups').select('*, classes!inner(school_id)').eq('classes.school_id', schoolId).order('name');
    final classesData = await supabase.from('classes').select().eq('school_id', schoolId).order('name');

    return GroupsState(
      groups: (groupsData as List).map((e) => GroupModel.fromJson(e)).toList(),
      classes: (classesData as List).map((e) => ClassModel.fromJson(e)).toList(),
    );
  }

  void setClassFilter(String? classId) {
    state.whenData((s) => state = AsyncData(s.copyWith(selectedClassId: classId, clearFilter: classId == null)));
  }

  Future<void> create({required String classId, required String name}) async {
    await SupabaseConfig.client.from('groups').insert({'class_id': classId, 'name': name});
    ref.invalidateSelf();
  }

  Future<void> updateGroup({required String id, required String classId, required String name}) async {
    await SupabaseConfig.client.from('groups').update({'class_id': classId, 'name': name}).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('groups').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

final groupsProvider = AsyncNotifierProvider<GroupsNotifier, GroupsState>(GroupsNotifier.new);