import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/class_model.dart';

class ClassesState {
  final List<ClassModel> classes;
  final String? selectedGroupId;
  ClassesState({this.classes = const [], this.selectedGroupId});

  List<ClassModel> get filtered => selectedGroupId == null ? classes : classes.where((c) => c.groupId == selectedGroupId).toList();

  ClassesState copyWith({List<ClassModel>? classes, String? selectedGroupId, bool clearGroupFilter = false}) => ClassesState(classes: classes ?? this.classes, selectedGroupId: clearGroupFilter ? null : (selectedGroupId ?? this.selectedGroupId));
}

class ClassesNotifier extends AsyncNotifier<ClassesState> {
  @override
  Future<ClassesState> build() async => _load();

  Future<ClassesState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final data = await supabase.from('classes').select('*, groups(name)').eq('school_id', profile['school_id']).order('name');

    return ClassesState(classes: (data as List).map((e) => ClassModel.fromJson(e)).toList());
  }

  void setGroupFilter(String? groupId) { 
    state.whenData((c) => state = AsyncData(c.copyWith(selectedGroupId: groupId, clearGroupFilter: groupId == null)));
  }

  Future<void> create({required String name, String? groupId, String? room, int? capacity}) async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();

    await supabase.from('classes').insert({
      'name': name, 'school_id': profile['school_id'], 'group_id': groupId, 'room': room, 'capacity': capacity,
    });
    ref.invalidateSelf();
  }

  Future<void> updateClass({required String id, required String name, String? groupId, String? room, int? capacity}) async {
    await SupabaseConfig.client.from('classes').update({'name': name, 'group_id': groupId, 'room': room, 'capacity': capacity}).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('classes').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

final classesProvider = AsyncNotifierProvider<ClassesNotifier, ClassesState>(ClassesNotifier.new);
