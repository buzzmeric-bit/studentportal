import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/building_models.dart';
import '../../providers/building_provider.dart';
import '../../widgets/admin_sidebar.dart';

class BuildingStructureScreen extends ConsumerStatefulWidget {
  const BuildingStructureScreen({super.key});
  @override
  ConsumerState<BuildingStructureScreen> createState() => _BuildingStructureScreenState();
}

class _BuildingStructureScreenState extends ConsumerState<BuildingStructureScreen> {
  String? _expandedBuildingId;
  String? _expandedFloorId;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(buildingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/structure'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: stateAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _buildErrorState(e),
                    data: (state) => _buildContent(context, state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Structure Physique', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('Gérer les bâtiments, étages et salles', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => ref.read(buildingProvider.notifier).setSearch(v),
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            onSelected: (v) => _showAddDialog(v),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'building', child: Row(children: [Icon(Icons.business), SizedBox(width: 8), Text('Nouveau Bâtiment')])),
              const PopupMenuItem(value: 'floor', child: Row(children: [Icon(Icons.layers), SizedBox(width: 8), Text('Nouvel Étage')])),
              const PopupMenuItem(value: 'room', child: Row(children: [Icon(Icons.meeting_room), SizedBox(width: 8), Text('Nouvelle Salle')])),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [Icon(Icons.add, color: Colors.white), SizedBox(width: 8), Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Erreur: $error', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(buildingProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BuildingState state) {
    final buildings = state.filteredBuildings;
    
    if (buildings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Aucun bâtiment', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Ajoutez un bâtiment pour commencer', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog('building'),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un bâtiment'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _buildStatCard(Icons.business, 'Bâtiments', buildings.length.toString(), Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard(Icons.layers, 'Étages', buildings.fold(0, (sum, b) => sum + b.floors.length).toString(), Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard(Icons.meeting_room, 'Salles', state.allRooms.length.toString(), Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          
          // Buildings list
          ...buildings.map((building) => _buildBuildingCard(building, state)),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingCard(BuildingModel building, BuildingState state) {
    final isExpanded = _expandedBuildingId == building.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedBuildingId = isExpanded ? null : building.id),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.business, color: Colors.blue.shade700, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(building.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _infoTag(Icons.layers, '${building.floors.length} étage(s)'),
                            const SizedBox(width: 12),
                            _infoTag(Icons.meeting_room, '${building.roomCount} salle(s)'),
                            if (building.code != null) ...[
                              const SizedBox(width: 12),
                              _infoTag(Icons.tag, building.code!),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showBuildingDialog(building: building),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete('building', building.id, building.name),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                ],
              ),
            ),
          ),
          
          // Floors
          if (isExpanded) ...[
            const Divider(height: 1),
            ...building.floors.map((floor) => _buildFloorSection(floor, building)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _showFloorDialog(buildingId: building.id),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un étage'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloorSection(FloorModel floor, BuildingModel building) {
    final isExpanded = _expandedFloorId == floor.id;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expandedFloorId = isExpanded ? null : floor.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isExpanded ? Colors.orange.shade50 : null,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.layers, color: Colors.orange.shade700, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(floor.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${floor.rooms.length} salle(s)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showFloorDialog(floor: floor, buildingId: building.id),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => _confirmDelete('floor', floor.id, floor.name),
                ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
        
        // Rooms
        if (isExpanded) ...[
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (floor.rooms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Aucune salle', style: TextStyle(color: Colors.grey.shade500)),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: floor.rooms.map((room) => _buildRoomChip(room, floor)).toList(),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showRoomDialog(floorId: floor.id),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter une salle'),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRoomChip(RoomModel room, FloorModel floor) {
    final color = room.roomType == 'lab' ? Colors.purple : 
                  room.roomType == 'office' ? Colors.teal : Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            room.roomType == 'lab' ? Icons.science :
            room.roomType == 'office' ? Icons.work :
            Icons.meeting_room,
            size: 16,
            color: color.shade700,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room.name, style: TextStyle(fontWeight: FontWeight.w500, color: color.shade700)),
              Text('${room.capacity} places', style: TextStyle(fontSize: 11, color: color.shade600)),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showRoomDialog(room: room, floorId: floor.id),
            child: Icon(Icons.edit, size: 14, color: color.shade400),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _confirmDelete('room', room.id, room.name),
            child: const Icon(Icons.close, size: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _infoTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  // ==================== DIALOGS ====================
  void _showAddDialog(String type) {
    switch (type) {
      case 'building':
        _showBuildingDialog();
        break;
      case 'floor':
        _showFloorDialog();
        break;
      case 'room':
        _showRoomDialog();
        break;
    }
  }

  void _showBuildingDialog({BuildingModel? building}) {
    final nameController = TextEditingController(text: building?.name ?? '');
    final codeController = TextEditingController(text: building?.code ?? '');
    final isNew = building == null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isNew ? 'Nouveau Bâtiment' : 'Modifier Bâtiment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              
              if (isNew) {
                // For new buildings, we'll need to get school_id from provider
                await ref.read(buildingProvider.notifier).addBuilding(
                  BuildingModel(
                    id: '',
                    schoolId: '', // Provider will handle this
                    name: nameController.text,
                    code: codeController.text.isEmpty ? null : codeController.text,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bâtiment ajouté avec succès'), backgroundColor: Colors.green),
                );
              } else {
                await ref.read(buildingProvider.notifier).updateBuilding(
                  building.id,
                  building.copyWith(name: nameController.text, code: codeController.text),
                );
              }
              Navigator.pop(ctx);
            },
            child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showFloorDialog({FloorModel? floor, String? buildingId}) {
    final nameController = TextEditingController(text: floor?.name ?? '');
    final numberController = TextEditingController(text: floor?.floorNumber.toString() ?? '0');
    final isNew = floor == null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isNew ? 'Nouvel Étage' : 'Modifier Étage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Numéro d\'étage', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              if (isNew && buildingId != null) {
                await ref.read(buildingProvider.notifier).addFloor(
                  FloorModel(
                    id: '',
                    buildingId: buildingId,
                    name: nameController.text,
                    floorNumber: int.tryParse(numberController.text) ?? 0,
                  ),
                );
              } else if (!isNew) {
                await ref.read(buildingProvider.notifier).updateFloor(
                  floor.id,
                  FloorModel(
                    id: floor.id,
                    buildingId: floor.buildingId,
                    name: nameController.text,
                    floorNumber: int.tryParse(numberController.text) ?? 0,
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showRoomDialog({RoomModel? room, String? floorId}) {
    final nameController = TextEditingController(text: room?.name ?? '');
    final capacityController = TextEditingController(text: room?.capacity.toString() ?? '30');
    String roomType = room?.roomType ?? 'classroom';
    final isNew = room == null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isNew ? 'Nouvelle Salle' : 'Modifier Salle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: roomType,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: RoomModel.roomTypes.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
                onChanged: (v) => setDialogState(() => roomType = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacité', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                if (isNew && floorId != null) {
                  await ref.read(buildingProvider.notifier).addRoom(
                    RoomModel(
                      id: '',
                      floorId: floorId,
                      name: nameController.text,
                      roomType: roomType,
                      capacity: int.tryParse(capacityController.text) ?? 30,
                    ),
                  );
                } else if (!isNew) {
                  await ref.read(buildingProvider.notifier).updateRoom(
                    room.id,
                    RoomModel(
                      id: room.id,
                      floorId: room.floorId,
                      name: nameController.text,
                      roomType: roomType,
                      capacity: int.tryParse(capacityController.text) ?? 30,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String type, String id, String name) {
    final typeLabel = type == 'building' ? 'bâtiment' : type == 'floor' ? 'étage' : 'salle';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le $typeLabel "$name" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              switch (type) {
                case 'building':
                  await ref.read(buildingProvider.notifier).deleteBuilding(id);
                  break;
                case 'floor':
                  await ref.read(buildingProvider.notifier).deleteFloor(id);
                  break;
                case 'room':
                  await ref.read(buildingProvider.notifier).deleteRoom(id);
                  break;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$typeLabel supprimé'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
