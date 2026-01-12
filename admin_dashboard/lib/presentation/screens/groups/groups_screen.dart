import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../data/models/school_models.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/admin_sidebar.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/groups'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, ref),
                Expanded(child: groupsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                  data: (state) => _buildContent(context, ref, state),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Row(
        children: [
          Text('Groupes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showGroupDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, GroupsState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  DropdownButton<String?>(
                    value: state.selectedClassId,
                    hint: const Text('Filtrer par classe'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Toutes les classes')),
                      ...state.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => ref.read(groupsProvider.notifier).setClassFilter(v),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildTable(context, ref, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, WidgetRef ref, GroupsState state) {
    final groups = state.filtered;
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      minWidth: 600,
      columns: const [
        DataColumn2(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
        DataColumn2(label: Text('Classe', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
        DataColumn2(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 120),
      ],
      rows: groups.map((g) {
        final className = state.classes.firstWhere((c) => c.id == g.classId, orElse: () => state.classes.first).name;
        return DataRow2(
          cells: [
            DataCell(Text(g.name)),
            DataCell(Text(className)),
            DataCell(Row(children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showGroupDialog(context, ref, group: g), tooltip: 'Modifier'),
              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _confirmDelete(context, ref, g), tooltip: 'Supprimer'),
            ])),
          ],
        );
      }).toList(),
      empty: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Aucun groupe', style: TextStyle(color: Colors.grey[600])),
      ])),
    );
  }

  void _showGroupDialog(BuildContext context, WidgetRef ref, {GroupModel? group}) {
    final state = ref.read(groupsProvider).value;
    if (state == null || state.classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez creer une classe dabord'), backgroundColor: Colors.orange));
      return;
    }

    final nameController = TextEditingController(text: group?.name ?? '');
    String selectedClassId = group?.classId ?? state.classes.first.id;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(group == null ? 'Nouveau groupe' : 'Modifier groupe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom du groupe', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedClassId,
              decoration: const InputDecoration(labelText: 'Classe', border: OutlineInputBorder()),
              items: state.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => selectedClassId = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              if (group == null) {
                ref.read(groupsProvider.notifier).create(classId: selectedClassId, name: nameController.text);
              } else {
                ref.read(groupsProvider.notifier).updateGroup(id: group.id, classId: selectedClassId, name: nameController.text);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(group == null ? 'Creer' : 'Modifier', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, GroupModel g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer groupe ?'),
        content: Text('Voulez-vous supprimer "${g.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () { ref.read(groupsProvider.notifier).delete(g.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}