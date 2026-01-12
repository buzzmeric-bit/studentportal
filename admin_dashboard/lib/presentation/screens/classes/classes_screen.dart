import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../data/models/class_model.dart';
import '../../providers/classes_provider.dart';
import '../../widgets/admin_sidebar.dart';
import 'class_form_dialog.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});
  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/classes'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: classesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
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
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Row(
        children: [
          Text('Classes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showClassDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ClassesState state) {
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
                  Text('${state.filtered.length} classe(s)', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Expanded(child: _buildTable(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, ClassesState state) {
    final classes = state.filtered;

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      minWidth: 600,
      columns: const [
        DataColumn2(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
        DataColumn2(label: Text('Groupe', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn2(label: Text('Salle', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn2(label: Text('Capacite', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn2(label: Text('Etudiants', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn2(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 120),
      ],
      rows: classes.map((cls) => DataRow2(
        cells: [
          DataCell(Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.class_, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Text(cls.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          ])),
          DataCell(Text(cls.groupName ?? '-')),
          DataCell(Text(cls.room ?? '-')),
          DataCell(Text(cls.capacity?.toString() ?? '-')),
          DataCell(Text(cls.studentCount.toString())),
          DataCell(Row(children: [
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showClassDialog(context, cls: cls), tooltip: 'Modifier'),
            IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _confirmDelete(context, cls), tooltip: 'Supprimer'),
          ])),
        ],
      )).toList(),
      empty: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.class_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Aucune classe trouvee', style: TextStyle(color: Colors.grey[600])),
      ])),
    );
  }

  void _showClassDialog(BuildContext context, {ClassModel? cls}) {
    showDialog(context: context, builder: (ctx) => ClassFormDialog(classModel: cls));
  }

  void _confirmDelete(BuildContext context, ClassModel cls) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la classe ${cls.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              ref.read(classesProvider.notifier).delete(cls.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Classe supprimee'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}