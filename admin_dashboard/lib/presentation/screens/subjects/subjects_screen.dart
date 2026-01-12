import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../data/models/school_models.dart';
import '../../providers/subjects_provider.dart';
import '../../widgets/admin_sidebar.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/subjects'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, ref),
                Expanded(child: subjectsAsync.when(
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
          Text('Matieres', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showSubjectDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, SubjectsState state) {
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
                  SizedBox(
                    width: 300,
                    child: TextField(
                      decoration: InputDecoration(hintText: 'Rechercher...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      onChanged: (v) => ref.read(subjectsProvider.notifier).setSearch(v),
                    ),
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

  Widget _buildTable(BuildContext context, WidgetRef ref, SubjectsState state) {
    final subjects = state.filtered;
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      minWidth: 700,
      columns: const [
        DataColumn2(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
        DataColumn2(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn2(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
        DataColumn2(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 120),
      ],
      rows: subjects.map((s) => DataRow2(
        cells: [
          DataCell(Text(s.name)),
          DataCell(Text(s.code ?? '-')),
          DataCell(Text(s.description ?? '-', overflow: TextOverflow.ellipsis)),
          DataCell(Row(children: [
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showSubjectDialog(context, ref, subject: s), tooltip: 'Modifier'),
            IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _confirmDelete(context, ref, s), tooltip: 'Supprimer'),
          ])),
        ],
      )).toList(),
      empty: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.book, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Aucune matiere', style: TextStyle(color: Colors.grey[600])),
      ])),
    );
  }

  void _showSubjectDialog(BuildContext context, WidgetRef ref, {SubjectModel? subject}) {
    final nameController = TextEditingController(text: subject?.name ?? '');
    final codeController = TextEditingController(text: subject?.code ?? '');
    final descController = TextEditingController(text: subject?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(subject == null ? 'Nouvelle matiere' : 'Modifier matiere'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              if (subject == null) {
                ref.read(subjectsProvider.notifier).create(name: nameController.text, code: codeController.text.isNotEmpty ? codeController.text : null, description: descController.text.isNotEmpty ? descController.text : null);
              } else {
                ref.read(subjectsProvider.notifier).updateSubject(id: subject.id, name: nameController.text, code: codeController.text.isNotEmpty ? codeController.text : null, description: descController.text.isNotEmpty ? descController.text : null);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(subject == null ? 'Creer' : 'Modifier', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SubjectModel s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer matiere ?'),
        content: Text('Voulez-vous supprimer "${s.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () { ref.read(subjectsProvider.notifier).delete(s.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}