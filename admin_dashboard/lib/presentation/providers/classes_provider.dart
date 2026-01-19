import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/class_model.dart';

class ClassesState {
  final List<ClassModel> classes;
  final String? selectedGroupId;
  final String? selectedGradeLevelId;
  final String? searchQuery;
  
  ClassesState({
    this.classes = const [],
    this.selectedGroupId,
    this.selectedGradeLevelId,
    this.searchQuery,
  });

  List<ClassModel> get filtered {
    var result = classes;
    if (selectedGroupId != null) {
      result = result.where((c) => c.groupId == selectedGroupId).toList();
    }
    if (selectedGradeLevelId != null) {
      result = result
          .where((c) => c.gradeLevelId == selectedGradeLevelId)
          .toList();
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result.where((c) =>
        c.name.toLowerCase().contains(query) ||
        (c.gradeLevelName?.toLowerCase().contains(query) ?? false) ||
        (c.sectionName?.toLowerCase().contains(query) ?? false) ||
        (c.room?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    return result;
  }

  ClassesState copyWith({
    List<ClassModel>? classes,
    String? selectedGroupId,
    String? selectedGradeLevelId,
    String? searchQuery,
    bool clearGroupFilter = false,
    bool clearGradeLevelFilter = false,
    bool clearSearch = false,
  }) => ClassesState(
    classes: classes ?? this.classes,
    selectedGroupId: clearGroupFilter
        ? null
        : (selectedGroupId ?? this.selectedGroupId),
    selectedGradeLevelId: clearGradeLevelFilter
        ? null
        : (selectedGradeLevelId ?? this.selectedGradeLevelId),
    searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
  );
}

class ClassesNotifier extends AsyncNotifier<ClassesState> {
  @override
  Future<ClassesState> build() async => _load();

  Future<ClassesState> _load() async {
    final supabase = SupabaseConfig.adminClient;
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase
        .from('users')
        .select('school_id')
        .eq('id', user.id)
        .single();

    // Load student counts per class (active enrollments only)
    final enrollmentsResp = await supabase
        .from('enrollments')
        .select('class_id')
        .eq('is_active', true);

    final Map<String, int> studentCounts = {};
    for (final row in enrollmentsResp as List) {
      final cid = row['class_id'] as String?;
      if (cid == null) continue;
      studentCounts[cid] = (studentCounts[cid] ?? 0) + 1;
    }

    final data = await supabase
        .from('classes')
        .select(
          '*, niveaux:niveau_id(code, name), sections:section_id(code, name, color)',
        )
        .eq('school_id', profile['school_id'])
        .order('name');

    final classes = (data as List).map((e) {
      e['student_count'] = studentCounts[e['id']] ?? 0;
      return ClassModel.fromJson(e);
    }).toList();

    return ClassesState(classes: classes);
  }

  void setGroupFilter(String? groupId) {
    state.whenData(
      (c) => state = AsyncData(
        c.copyWith(selectedGroupId: groupId, clearGroupFilter: groupId == null),
      ),
    );
  }

  void setGradeLevelFilter(String? gradeLevelId) {
    state.whenData(
      (c) => state = AsyncData(
        c.copyWith(
          selectedGradeLevelId: gradeLevelId,
          clearGradeLevelFilter: gradeLevelId == null,
        ),
      ),
    );
  }

  void setSearch(String query) {
    state.whenData(
      (c) => state = AsyncData(
        c.copyWith(
          searchQuery: query,
          clearSearch: query.isEmpty,
        ),
      ),
    );
  }

  void clearFilters() {
    state.whenData(
      (c) => state = AsyncData(
        c.copyWith(
          clearGroupFilter: true,
          clearGradeLevelFilter: true,
          clearSearch: true,
        ),
      ),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load());
  }

  Future<void> create({
    required String name,
    String? groupId,
    String? gradeLevelId,
    String? sectionId,
    String? room,
    int? capacity,
  }) async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase
        .from('users')
        .select('school_id')
        .eq('id', user.id)
        .single();

    await supabase.from('classes').insert({
      'name': name,
      'school_id': profile['school_id'],
      'niveau_id': gradeLevelId,
      'section_id': sectionId,
      'room': room,
      'capacity': capacity,
    });
    ref.invalidateSelf();
  }

  Future<void> updateClass({
    required String id,
    required String name,
    String? groupId,
    String? gradeLevelId,
    String? sectionId,
    String? room,
    int? capacity,
  }) async {
    await SupabaseConfig.client
        .from('classes')
        .update({
          'name': name,
          'niveau_id': gradeLevelId,
          'section_id': sectionId,
          'room': room,
          'capacity': capacity,
        })
        .eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('classes').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

final classesProvider = AsyncNotifierProvider<ClassesNotifier, ClassesState>(
  ClassesNotifier.new,
);
