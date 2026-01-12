import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../providers/semesters_provider.dart';
import '../../widgets/admin_sidebar.dart';

class SemestersScreen extends ConsumerStatefulWidget {
  const SemestersScreen({super.key});
  @override
  ConsumerState<SemestersScreen> createState() => _SemestersScreenState();
}

class _SemestersScreenState extends ConsumerState<SemestersScreen> {
  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semestersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/semesters'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: semestersAsync.when(
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
          Text('Semestres', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showSemesterDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, SemestersState state) {
    final semesters = state.semesters;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 16,
          minWidth: 600,
          columns: const [
            DataColumn2(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
            DataColumn2(label: Text('Debut', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn2(label: Text('Fin', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn2(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn2(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 150),
          ],
          rows: semesters.map((s) => DataRow2(
            cells: [
              DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(dateFormat.format(s.startDate))),
              DataCell(Text(dateFormat.format(s.endDate))),
              DataCell(s.isCurrent
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Text('Actuel', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  : const Text('-')),
              DataCell(Row(children: [
                if (!s.isCurrent)
                  IconButton(icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.green), onPressed: () => ref.read(semestersProvider.notifier).setCurrentSemester(s.id), tooltip: 'Definir actuel'),
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showSemesterDialog(context, semester: s), tooltip: 'Modifier'),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _confirmDelete(context, s), tooltip: 'Supprimer'),
              ])),
            ],
          )).toList(),
          empty: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucun semestre', style: TextStyle(color: Colors.grey[600])),
          ])),
        ),
      ),
    );
  }

  void _showSemesterDialog(BuildContext context, {SemesterModel? semester}) {
    final nameCtrl = TextEditingController(text: semester?.name ?? '');
    DateTime startDate = semester?.startDate ?? DateTime.now();
    DateTime endDate = semester?.endDate ?? DateTime.now().add(const Duration(days: 180));
    bool isCurrent = semester?.isCurrent ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(semester == null ? 'Nouveau semestre' : 'Modifier le semestre'),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom *')),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date de debut'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setDialogState(() => startDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date de fin'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setDialogState(() => endDate = picked);
                },
              ),
              CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Semestre actuel'), value: isCurrent, onChanged: (v) => setDialogState(() => isCurrent = v ?? false)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final notifier = ref.read(semestersProvider.notifier);
                if (semester == null) {
                  await notifier.create(name: nameCtrl.text, startDate: startDate, endDate: endDate, isCurrent: isCurrent);
                } else {
                  await notifier.updateSemester(id: semester.id, name: nameCtrl.text, startDate: startDate, endDate: endDate);
                  if (isCurrent && !semester.isCurrent) {
                    await notifier.setCurrentSemester(semester.id);
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(semester == null ? 'Creer' : 'Modifier', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SemesterModel s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le semestre ?'),
        content: Text('Voulez-vous supprimer "${s.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () { ref.read(semestersProvider.notifier).delete(s.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}