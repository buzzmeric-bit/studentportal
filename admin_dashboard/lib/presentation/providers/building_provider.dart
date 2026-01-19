import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import '../../data/models/building_models.dart';

// ==================== STATE ====================
class BuildingState {
  final List<BuildingModel> buildings;
  final List<RoomModel> allRooms;
  final String searchQuery;
  final String? selectedBuildingId;

  BuildingState({
    this.buildings = const [],
    this.allRooms = const [],
    this.searchQuery = '',
    this.selectedBuildingId,
  });

  List<BuildingModel> get filteredBuildings {
    if (searchQuery.isEmpty) return buildings;
    final query = searchQuery.toLowerCase();
    return buildings.where((b) =>
        b.name.toLowerCase().contains(query) ||
        (b.code?.toLowerCase().contains(query) ?? false)).toList();
  }

  List<RoomModel> get availableRooms {
    return allRooms.where((r) => r.isActive).toList();
  }

  List<RoomModel> roomsForBuilding(String buildingId) {
    final building = buildings.firstWhere(
      (b) => b.id == buildingId,
      orElse: () => BuildingModel(id: '', schoolId: '', name: ''),
    );
    return building.floors.expand((f) => f.rooms).toList();
  }

  BuildingState copyWith({
    List<BuildingModel>? buildings,
    List<RoomModel>? allRooms,
    String? searchQuery,
    String? selectedBuildingId,
    bool clearBuildingFilter = false,
  }) => BuildingState(
    buildings: buildings ?? this.buildings,
    allRooms: allRooms ?? this.allRooms,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedBuildingId: clearBuildingFilter 
        ? null 
        : (selectedBuildingId ?? this.selectedBuildingId),
  );
}

// ==================== PROVIDER ====================
final buildingProvider = AsyncNotifierProvider<BuildingNotifier, BuildingState>(
  BuildingNotifier.new,
);

class BuildingNotifier extends AsyncNotifier<BuildingState> {
  @override
  Future<BuildingState> build() async => _load();

  Future<BuildingState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase
        .from('users')
        .select('school_id')
        .eq('id', user.id)
        .single();
    final schoolId = profile['school_id'];

    // Load buildings with nested floors and rooms
    final buildingsResp = await supabase
        .from('buildings')
        .select('''
          *,
          floors(
            *,
            rooms(*)
          )
        ''')
        .eq('school_id', schoolId)
        .eq('is_active', true)
        .order('name');

    final buildings = (buildingsResp as List)
        .map((b) => BuildingModel.fromJson(b))
        .toList();

    // Also load flat list of all rooms for quick access
    final roomsResp = await supabase
        .from('rooms')
        .select('''
          *,
          floors(name, buildings(name))
        ''')
        .eq('is_active', true)
        .order('name');

    final allRooms = (roomsResp as List)
        .map((r) => RoomModel.fromJson(r))
        .toList();

    return BuildingState(buildings: buildings, allRooms: allRooms);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  void setSearch(String query) {
    state.whenData((s) {
      state = AsyncData(s.copyWith(searchQuery: query));
    });
  }

  void setBuildingFilter(String? buildingId) {
    state.whenData((s) {
      state = AsyncData(s.copyWith(
        selectedBuildingId: buildingId,
        clearBuildingFilter: buildingId == null,
      ));
    });
  }

  // ==================== BUILDING CRUD ====================
  Future<void> addBuilding(BuildingModel building) async {
    await SupabaseConfig.client.from('buildings').insert(building.toJson());
    ref.invalidateSelf();
  }

  Future<void> updateBuilding(String id, BuildingModel building) async {
    await SupabaseConfig.client.from('buildings').update(building.toJson()).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> deleteBuilding(String id) async {
    await SupabaseConfig.client.from('buildings').update({'is_active': false}).eq('id', id);
    ref.invalidateSelf();
  }

  // ==================== FLOOR CRUD ====================
  Future<void> addFloor(FloorModel floor) async {
    await SupabaseConfig.client.from('floors').insert(floor.toJson());
    ref.invalidateSelf();
  }

  Future<void> updateFloor(String id, FloorModel floor) async {
    await SupabaseConfig.client.from('floors').update(floor.toJson()).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> deleteFloor(String id) async {
    await SupabaseConfig.client.from('floors').update({'is_active': false}).eq('id', id);
    ref.invalidateSelf();
  }

  // ==================== ROOM CRUD ====================
  Future<void> addRoom(RoomModel room) async {
    await SupabaseConfig.client.from('rooms').insert(room.toJson());
    ref.invalidateSelf();
  }

  Future<void> updateRoom(String id, RoomModel room) async {
    await SupabaseConfig.client.from('rooms').update(room.toJson()).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> deleteRoom(String id) async {
    await SupabaseConfig.client.from('rooms').update({'is_active': false}).eq('id', id);
    ref.invalidateSelf();
  }
}
