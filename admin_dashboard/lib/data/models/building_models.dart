/// Building structure models for physical school layout

// ==================== BUILDING MODEL ====================
class BuildingModel {
  final String id;
  final String schoolId;
  final String name;
  final String? code;
  final String? address;
  final bool isActive;
  final DateTime? createdAt;
  final List<FloorModel> floors;
  final int roomCount;

  BuildingModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.code,
    this.address,
    this.isActive = true,
    this.createdAt,
    this.floors = const [],
    this.roomCount = 0,
  });

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    List<FloorModel> floors = [];
    if (json['floors'] != null) {
      floors = (json['floors'] as List)
          .map((f) => FloorModel.fromJson(f))
          .toList()
        ..sort((a, b) => a.floorNumber.compareTo(b.floorNumber));
    }

    return BuildingModel(
      id: json['id'] ?? '',
      schoolId: json['school_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      floors: floors,
      roomCount: json['room_count'] ?? 
          floors.fold(0, (sum, f) => sum + f.rooms.length),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    'code': code,
    'address': address,
    'is_active': isActive,
  };

  BuildingModel copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? code,
    String? address,
    bool? isActive,
    List<FloorModel>? floors,
  }) {
    return BuildingModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      floors: floors ?? this.floors,
    );
  }
}

// ==================== FLOOR MODEL ====================
class FloorModel {
  final String id;
  final String buildingId;
  final String name;
  final int floorNumber;
  final bool isActive;
  final DateTime? createdAt;
  final List<RoomModel> rooms;

  FloorModel({
    required this.id,
    required this.buildingId,
    required this.name,
    this.floorNumber = 0,
    this.isActive = true,
    this.createdAt,
    this.rooms = const [],
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    List<RoomModel> rooms = [];
    if (json['rooms'] != null) {
      rooms = (json['rooms'] as List)
          .map((r) => RoomModel.fromJson(r))
          .toList();
    }

    return FloorModel(
      id: json['id'] ?? '',
      buildingId: json['building_id'] ?? '',
      name: json['name'] ?? '',
      floorNumber: json['floor_number'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      rooms: rooms,
    );
  }

  Map<String, dynamic> toJson() => {
    'building_id': buildingId,
    'name': name,
    'floor_number': floorNumber,
    'is_active': isActive,
  };
}

// ==================== ROOM MODEL ====================
class RoomModel {
  final String id;
  final String floorId;
  final String name;
  final String roomType;
  final int capacity;
  final bool isActive;
  final DateTime? createdAt;
  // Joined data
  final String? floorName;
  final String? buildingName;

  RoomModel({
    required this.id,
    required this.floorId,
    required this.name,
    this.roomType = 'classroom',
    this.capacity = 30,
    this.isActive = true,
    this.createdAt,
    this.floorName,
    this.buildingName,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
    id: json['id'] ?? '',
    floorId: json['floor_id'] ?? '',
    name: json['name'] ?? '',
    roomType: json['room_type'] ?? 'classroom',
    capacity: json['capacity'] ?? 30,
    isActive: json['is_active'] ?? true,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null,
    floorName: json['floors']?['name'],
    buildingName: json['floors']?['buildings']?['name'],
  );

  Map<String, dynamic> toJson() => {
    'floor_id': floorId,
    'name': name,
    'room_type': roomType,
    'capacity': capacity,
    'is_active': isActive,
  };

  String get roomTypeLabel {
    switch (roomType) {
      case 'classroom': return 'Salle de classe';
      case 'lab': return 'Laboratoire';
      case 'office': return 'Bureau';
      case 'library': return 'Bibliothèque';
      case 'gym': return 'Gymnase';
      case 'cafeteria': return 'Cafétéria';
      default: return 'Autre';
    }
  }

  static const roomTypes = [
    ('classroom', 'Salle de classe'),
    ('lab', 'Laboratoire'),
    ('office', 'Bureau'),
    ('library', 'Bibliothèque'),
    ('gym', 'Gymnase'),
    ('cafeteria', 'Cafétéria'),
    ('other', 'Autre'),
  ];
}
