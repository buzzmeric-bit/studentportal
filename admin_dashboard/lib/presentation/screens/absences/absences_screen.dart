import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../providers/absences_provider.dart';
import '../../widgets/admin_sidebar.dart';

class AbsencesScreen extends ConsumerWidget {
  const AbsencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absencesAsync = ref.watch(absencesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/absences'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(child: absencesAsync.when(
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

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
      child: Row(
        children: [
          Text('Absences', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AbsencesState state) {
    final list = state.filtered;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: state.classFilter,
                    hint: const Text('Toutes les classes'),
                    items: [const DropdownMenuItem(value: null, child: Text('Toutes les classes')), ...state.classes.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))],
                    onChanged: (v) => ref.read(absencesProvider.notifier).setClassFilter(v),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: state.statusFilter,
                    hint: const Text('Tous les statuts'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous les statuts')),
                      DropdownMenuItem(value: 'absent', child: Text('Absent')),
                      DropdownMenuItem(value: 'late', child: Text('En retard')),
                      DropdownMenuItem(value: 'excused', child: Text('Excusé')),
                    ],
                    onChanged: (v) => ref.read(absencesProvider.notifier).setStatusFilter(v),
                  ),
                  const Spacer(),
                  Text('${list.length} absence(s)', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Expanded(
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 16,
                minWidth: 700,
                columns: const [
                  DataColumn2(label: Text('Étudiant', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
                  DataColumn2(label: Text('Classe', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn2(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn2(label: Text('Période', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn2(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn2(label: Text('Justifié', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn2(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 100),
                ],
                rows: list.map((a) => DataRow2(
                  cells: [
                    DataCell(Text(a.studentName)),
                    DataCell(Text(a.className ?? '-')),
                    DataCell(Text(dateFormat.format(a.date))),
                    DataCell(Text(a.period ?? '-')),
                    DataCell(_StatusChip(status: a.status)),
                    DataCell(IconButton(
                      icon: Icon(a.justified ? Icons.check_circle : Icons.cancel, color: a.justified ? Colors.green : Colors.grey, size: 20),
                      onPressed: () => ref.read(absencesProvider.notifier).toggleJustified(a.id, a.justified),
                      tooltip: a.justified ? 'Marquer non justifié' : 'Marquer justifié',
                    )),
                    DataCell(IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => ref.read(absencesProvider.notifier).delete(a.id), tooltip: 'Supprimer')),
                  ],
                )).toList(),
                empty: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.event_busy, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), Text('Aucune absence', style: TextStyle(color: Colors.grey[600]))])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case 'absent': bg = Colors.red.shade100; label = 'Absent'; break;
      case 'late': bg = Colors.orange.shade100; label = 'Retard'; break;
      case 'excused': bg = Colors.green.shade100; label = 'Excusé'; break;
      default: bg = Colors.grey.shade100; label = status;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)));
  }
}
