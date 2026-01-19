import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../providers/absences_provider.dart';
import '../../widgets/admin_sidebar.dart';

class AbsencesScreen extends ConsumerStatefulWidget {
  const AbsencesScreen({super.key});

  @override
  ConsumerState<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends ConsumerState<AbsencesScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;
  bool _isSelectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final absencesAsync = ref.watch(absencesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/absences'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, absencesAsync),
                if (_isSelectionMode) _buildSelectionBar(context, absencesAsync),
                if (_showFilters) _buildFilterBar(context, absencesAsync),
                Expanded(
                  child: absencesAsync.when(
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

  Widget _buildTopBar(BuildContext context, AsyncValue<AbsencesState> absencesAsync) {
    final state = absencesAsync.asData?.value;
    final totalCount = state?.absences.length ?? 0;
    final filteredCount = state?.filtered.length ?? 0;
    final totalHours = state?.totalHours ?? 0;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          // Title with icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event_busy, color: Colors.orange.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Gestion des Absences',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$filteredCount absence(s) • ${totalHours.toStringAsFixed(1)}h total',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: 32),
          // Search bar
          SizedBox(
            width: 350,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => ref.read(absencesProvider.notifier).setSearchQuery(v),
              decoration: InputDecoration(
                hintText: 'Rechercher étudiant, classe, matière, motif...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(absencesProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filter toggle
          Badge(
            isLabelVisible: _showFilters || _hasActiveFilters(state),
            backgroundColor: Colors.orange,
            child: IconButton(
              icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
              tooltip: 'Filtres avancés',
              onPressed: () => setState(() => _showFilters = !_showFilters),
              color: _showFilters || _hasActiveFilters(state) ? Colors.orange : null,
            ),
          ),
          const Spacer(),
          // Selection mode toggle
          IconButton(
            onPressed: () {
              setState(() => _isSelectionMode = !_isSelectionMode);
              if (!_isSelectionMode) {
                ref.read(absencesProvider.notifier).clearSelection();
              }
            },
            icon: Icon(
              _isSelectionMode ? Icons.check_box : Icons.check_box_outline_blank,
              color: _isSelectionMode ? Colors.blue : null,
            ),
            tooltip: _isSelectionMode ? 'Quitter sélection' : 'Mode sélection',
          ),
          const SizedBox(width: 8),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(absencesProvider),
          ),
          const SizedBox(width: 8),
          // Add absence button
          ElevatedButton.icon(
            onPressed: () => _showAddAbsenceDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle absence'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(AbsencesState? state) {
    if (state == null) return false;
    return state.classFilter != null ||
        state.subjectFilter != null ||
        state.justifiedFilter != null ||
        state.dateFromFilter != null ||
        state.dateToFilter != null;
  }

  Widget _buildSelectionBar(BuildContext context, AsyncValue<AbsencesState> absencesAsync) {
    final state = absencesAsync.asData?.value;
    final selectedCount = state?.selectedIds.length ?? 0;
    final filteredCount = state?.filtered.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Checkbox(
            value: selectedCount > 0 && selectedCount == filteredCount,
            tristate: true,
            onChanged: (v) {
              if (v == true || selectedCount == 0) {
                ref.read(absencesProvider.notifier).selectAll();
              } else {
                ref.read(absencesProvider.notifier).clearSelection();
              }
            },
          ),
          Text(
            '$selectedCount sélectionné(s)',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 24),
          if (selectedCount > 0) ...[
            ElevatedButton.icon(
              onPressed: () async {
                final count = await ref.read(absencesProvider.notifier).bulkToggleJustified(true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count absence(s) marquée(s) justifiée(s)'), backgroundColor: Colors.green),
                  );
                  ref.read(absencesProvider.notifier).clearSelection();
                }
              },
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Justifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final count = await ref.read(absencesProvider.notifier).bulkToggleJustified(false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count absence(s) marquée(s) non justifiée(s)'), backgroundColor: Colors.orange),
                  );
                  ref.read(absencesProvider.notifier).clearSelection();
                }
              },
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('Non justifier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _confirmBulkDelete(context, selectedCount),
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() => _isSelectionMode = false);
              ref.read(absencesProvider.notifier).clearSelection();
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, AsyncValue<AbsencesState> absencesAsync) {
    final state = absencesAsync.asData?.value;
    if (state == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.grey.shade50,
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Class filter
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              value: state.classFilter,
              decoration: InputDecoration(
                labelText: 'Classe',
                prefixIcon: const Icon(Icons.class_, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes les classes')),
                ...state.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => ref.read(absencesProvider.notifier).setClassFilter(v),
            ),
          ),
          // Subject filter
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              value: state.subjectFilter,
              decoration: InputDecoration(
                labelText: 'Matière',
                prefixIcon: const Icon(Icons.menu_book, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes les matières')),
                ...state.subjectOfferings.map((o) => DropdownMenuItem(
                  value: o.id,
                  child: Text('${o.subjectName} (${o.className ?? "?"})', overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: (v) => ref.read(absencesProvider.notifier).setSubjectFilter(v),
            ),
          ),
          // Justified filter
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: state.justifiedFilter,
              decoration: InputDecoration(
                labelText: 'Justification',
                prefixIcon: const Icon(Icons.verified, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
                DropdownMenuItem(value: 'justified', child: Text('Justifiées')),
                DropdownMenuItem(value: 'not_justified', child: Text('Non justifiées')),
              ],
              onChanged: (v) => ref.read(absencesProvider.notifier).setJustifiedFilter(v),
            ),
          ),
          // Date from
          _buildDatePicker(
            context,
            label: 'Du',
            value: state.dateFromFilter,
            onChanged: (d) => ref.read(absencesProvider.notifier).setDateRange(d, state.dateToFilter),
          ),
          // Date to
          _buildDatePicker(
            context,
            label: 'Au',
            value: state.dateToFilter,
            onChanged: (d) => ref.read(absencesProvider.notifier).setDateRange(state.dateFromFilter, d),
          ),
          // Clear filters
          if (_hasActiveFilters(state))
            TextButton.icon(
              onPressed: () => ref.read(absencesProvider.notifier).clearFilters(),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Réinitialiser'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            locale: const Locale('fr', 'FR'),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today, size: 18),
            suffixIcon: value != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => onChanged(null),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: Colors.white,
          ),
          child: Text(
            value != null ? dateFormat.format(value) : '—',
            style: TextStyle(color: value != null ? Colors.black87 : Colors.grey),
          ),
        ),
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
            onPressed: () => ref.invalidate(absencesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AbsencesState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Stats cards row
          _buildStatsRow(state),
          const SizedBox(height: 24),
          // Data table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildDataTable(context, state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AbsencesState state) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.event_busy,
          title: 'Total absences',
          value: state.filtered.length.toString(),
          color: Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.access_time,
          title: 'Heures total',
          value: '${state.totalHours.toStringAsFixed(1)}h',
          color: Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.check_circle,
          title: 'Justifiées',
          value: state.justifiedCount.toString(),
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.cancel,
          title: 'Non justifiées',
          value: state.notJustifiedCount.toString(),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, AbsencesState state) {
    final list = state.filtered;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      minWidth: 1000,
      headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      dataRowHeight: 60,
      columns: [
        if (_isSelectionMode)
          const DataColumn2(label: SizedBox.shrink(), fixedWidth: 50),
        const DataColumn2(label: Text('Étudiant'), size: ColumnSize.L),
        const DataColumn2(label: Text('Classe')),
        const DataColumn2(label: Text('Matière')),
        const DataColumn2(label: Text('Date')),
        const DataColumn2(label: Text('Heures'), fixedWidth: 80),
        const DataColumn2(label: Text('Type'), fixedWidth: 80),
        const DataColumn2(label: Text('Motif'), size: ColumnSize.L),
        const DataColumn2(label: Text('Justifié'), fixedWidth: 100),
        const DataColumn2(label: Text('Actions'), fixedWidth: 120),
      ],
      rows: list.map((a) {
        final isSelected = state.selectedIds.contains(a.id);
        return DataRow2(
          selected: isSelected,
          color: WidgetStateProperty.resolveWith((states) {
            if (isSelected) return Colors.blue.withOpacity(0.1);
            return null;
          }),
          onTap: _isSelectionMode ? () => ref.read(absencesProvider.notifier).toggleSelection(a.id) : null,
          cells: [
            if (_isSelectionMode)
              DataCell(
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => ref.read(absencesProvider.notifier).toggleSelection(a.id),
                ),
              ),
            DataCell(
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      a.studentName.isNotEmpty ? a.studentName[0].toUpperCase() : '?',
                      style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: Text(a.studentName, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            DataCell(Text(a.className ?? '—')),
            DataCell(Text(a.subjectName ?? '—', overflow: TextOverflow.ellipsis)),
            DataCell(Text(dateFormat.format(a.date))),
            DataCell(Text('${a.hoursAbsent.toStringAsFixed(0)}h')),
            DataCell(_SessionTypeChip(type: a.sessionType)),
            DataCell(
              Tooltip(
                message: a.reason ?? 'Aucun motif',
                child: Text(
                  a.reason ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: a.reason != null ? Colors.black87 : Colors.grey),
                ),
              ),
            ),
            DataCell(
              _JustifiedBadge(
                justified: a.justified,
                onTap: () => ref.read(absencesProvider.notifier).toggleJustified(a.id, a.justified),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: Colors.blue,
                    tooltip: 'Modifier',
                    onPressed: () => _showEditDialog(context, a),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.red,
                    tooltip: 'Supprimer',
                    onPressed: () => _confirmDelete(context, a),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
      empty: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Aucune absence trouvée', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Modifiez vos filtres ou ajoutez une nouvelle absence', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showAddAbsenceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddAbsenceDialog(ref: ref),
    );
  }

  void _showEditDialog(BuildContext context, AbsenceModel absence) {
    final reasonController = TextEditingController(text: absence.reason);
    double hoursAbsent = absence.hoursAbsent;
    String? sessionType = absence.sessionType;
    bool justified = absence.justified;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Text('Modifier l\'absence'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${absence.studentName} - ${absence.className ?? ""}'),
                Text('${DateFormat('dd/MM/yyyy').format(absence.date)} • ${absence.subjectName ?? ""}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        value: hoursAbsent,
                        decoration: const InputDecoration(
                          labelText: 'Heures',
                          border: OutlineInputBorder(),
                        ),
                        items: [1, 2, 3, 4, 5, 6].map((h) => DropdownMenuItem(value: h.toDouble(), child: Text('${h}h'))).toList(),
                        onChanged: (v) => setDialogState(() => hoursAbsent = v ?? 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: sessionType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('—')),
                          DropdownMenuItem(value: 'CI', child: Text('CI')),
                          DropdownMenuItem(value: 'TD', child: Text('TD')),
                          DropdownMenuItem(value: 'TP', child: Text('TP')),
                        ],
                        onChanged: (v) => setDialogState(() => sessionType = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motif',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Maladie, RDV médical...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Justifiée'),
                  value: justified,
                  onChanged: (v) => setDialogState(() => justified = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(absencesProvider.notifier).updateAbsence(
                  id: absence.id,
                  hoursAbsent: hoursAbsent,
                  sessionType: sessionType,
                  reason: reasonController.text.isNotEmpty ? reasonController.text : null,
                  justified: justified,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AbsenceModel absence) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Text('Supprimer l\'absence de ${absence.studentName} du ${DateFormat('dd/MM/yyyy').format(absence.date)} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(absencesProvider.notifier).delete(absence.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete(BuildContext context, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Text('Supprimer $count absence(s) sélectionnée(s) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final deleted = await ref.read(absencesProvider.notifier).deleteSelected();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$deleted absence(s) supprimée(s)'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

/// Period selection for bulk absences
enum AbsencePeriod { day, week, month, custom }

/// Dialog for adding new absences - SMART TIMETABLE-DRIVEN
class _AddAbsenceDialog extends StatefulWidget {
  final WidgetRef ref;
  const _AddAbsenceDialog({required this.ref});

  @override
  State<_AddAbsenceDialog> createState() => _AddAbsenceDialogState();
}

class _AddAbsenceDialogState extends State<_AddAbsenceDialog> {
  bool _isBulkMode = false;
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();
  DateTime? _endDate; // For custom period
  AbsencePeriod _period = AbsencePeriod.day;
  String _reason = '';
  bool _justified = false;
  
  // For single student mode
  String? _selectedStudentEnrollmentId;
  
  // For bulk/timetable mode
  List<StudentInfo> _classStudents = [];
  Set<String> _selectedStudentEnrollmentIds = {};
  
  // Timetable slots selection
  List<TimetableSlotInfo> _classTimetableSlots = [];
  Set<String> _selectedTimetableSlotIds = {};
  
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.ref.watch(absencesProvider).asData?.value;
    if (state == null) return const SizedBox.shrink();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.event_busy, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          const Expanded(child: Text('Marquer absence')),
          // Mode toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Individuelle'), icon: Icon(Icons.person, size: 16)),
              ButtonSegment(value: true, label: Text('Classe'), icon: Icon(Icons.groups, size: 16)),
            ],
            selected: {_isBulkMode},
            onSelectionChanged: (v) {
              setState(() {
                _isBulkMode = v.first;
                _selectedStudentEnrollmentId = null;
                _selectedStudentEnrollmentIds.clear();
                if (_isBulkMode && _classStudents.isNotEmpty) {
                  _selectedStudentEnrollmentIds = _classStudents
                      .where((s) => s.enrollmentId != null)
                      .map((s) => s.enrollmentId!)
                      .toSet();
                }
              });
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        height: 550,
        child: _isSubmitting 
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Création des absences en cours...'),
              ],
            ))
          : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class selection
              DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Classe *',
                  prefixIcon: Icon(Icons.class_),
                  border: OutlineInputBorder(),
                ),
                items: state.classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: _onClassChanged,
              ),
              const SizedBox(height: 16),

              // Period selection (for bulk mode)
              if (_isBulkMode) ...[
                Text('Période d\'absence', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _periodChip(AbsencePeriod.day, Icons.today, 'Journée'),
                    _periodChip(AbsencePeriod.week, Icons.view_week, 'Semaine'),
                    _periodChip(AbsencePeriod.month, Icons.calendar_month, 'Mois'),
                    _periodChip(AbsencePeriod.custom, Icons.date_range, 'Personnalisé'),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Date selection
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: _period == AbsencePeriod.custom ? 'Date début *' : 'Date *',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('EEE dd/MM/yyyy', 'fr_FR').format(_selectedDate)),
                      ),
                    ),
                  ),
                  if (_isBulkMode && _period == AbsencePeriod.custom) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date fin *',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_endDate != null 
                            ? DateFormat('EEE dd/MM/yyyy', 'fr_FR').format(_endDate!)
                            : 'Sélectionner...'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Student selection (for single mode)
              if (!_isBulkMode && _selectedClassId != null) ...[
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else
                  DropdownButtonFormField<String>(
                    value: _selectedStudentEnrollmentId,
                    decoration: const InputDecoration(
                      labelText: 'Étudiant *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    items: _classStudents.where((s) => s.enrollmentId != null).map((s) => DropdownMenuItem(
                      value: s.enrollmentId,
                      child: Text(s.fullName),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedStudentEnrollmentId = v),
                  ),
                const SizedBox(height: 16),
              ],

              // Timetable slots for the selected day - SMART VIEW
              if (_selectedClassId != null && !_isLoading) ...[
                _buildTimetableSection(),
                const SizedBox(height: 16),
              ],

              // Student list (for bulk mode - collapsible)
              if (_isBulkMode && _selectedClassId != null && !_isLoading) ...[
                ExpansionTile(
                  title: Text('Étudiants (${_selectedStudentEnrollmentIds.length}/${_classStudents.length})'),
                  leading: const Icon(Icons.people),
                  initiallyExpanded: false,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() {
                            if (_selectedStudentEnrollmentIds.length == _classStudents.length) {
                              _selectedStudentEnrollmentIds.clear();
                            } else {
                              _selectedStudentEnrollmentIds = _classStudents.where((s) => s.enrollmentId != null).map((s) => s.enrollmentId!).toSet();
                            }
                          }),
                          icon: Icon(_selectedStudentEnrollmentIds.length == _classStudents.length ? Icons.deselect : Icons.select_all, size: 18),
                          label: Text(_selectedStudentEnrollmentIds.length == _classStudents.length ? 'Désélectionner' : 'Tout'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        itemCount: _classStudents.length,
                        itemBuilder: (ctx, i) {
                          final student = _classStudents[i];
                          final isSelected = _selectedStudentEnrollmentIds.contains(student.enrollmentId);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: student.enrollmentId == null ? null : (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedStudentEnrollmentIds.add(student.enrollmentId!);
                                } else {
                                  _selectedStudentEnrollmentIds.remove(student.enrollmentId);
                                }
                              });
                            },
                            title: Text(student.fullName, style: const TextStyle(fontSize: 13)),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Reason
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Motif (optionnel)',
                  prefixIcon: Icon(Icons.comment),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Maladie, RDV médical...',
                ),
                maxLines: 2,
                onChanged: (v) => _reason = v,
              ),
              const SizedBox(height: 12),

              // Justified toggle
              SwitchListTile(
                title: const Text('Absence justifiée'),
                value: _justified,
                onChanged: (v) => setState(() => _justified = v),
                contentPadding: EdgeInsets.zero,
              ),

              // Summary
              if (_canSubmit()) _buildSummary(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton.icon(
          onPressed: _canSubmit() && !_isSubmitting ? _submit : null,
          icon: const Icon(Icons.save),
          label: Text(_getSaveButtonText()),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _periodChip(AbsencePeriod period, IconData icon, String label) {
    final isSelected = _period == period;
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
      label: Text(label),
      selected: isSelected,
      onSelected: (v) {
        if (v) {
          setState(() {
            _period = period;
            _endDate = null;
            _updateTimetableSlotsForPeriod();
          });
        }
      },
      selectedColor: Colors.orange,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700),
    );
  }

  Widget _buildTimetableSection() {
    final dayIndex = _selectedDate.weekday; // 1=Mon, 7=Sun
    final slotsForDay = _classTimetableSlots.where((s) => s.dayIndex == dayIndex).toList();
    
    // For multi-day periods, show all slots
    final List<TimetableSlotInfo> displaySlots;
    if (_isBulkMode && _period != AbsencePeriod.day) {
      displaySlots = _classTimetableSlots;
    } else {
      displaySlots = slotsForDay;
    }

    if (displaySlots.isEmpty && _classTimetableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            const Expanded(child: Text('Aucun emploi du temps trouvé pour cette classe.')),
          ],
        ),
      );
    }

    if (displaySlots.isEmpty && _classTimetableSlots.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text('Pas de cours le ${DateFormat('EEEE', 'fr_FR').format(_selectedDate)}.')),
          ],
        ),
      );
    }

    // Group by day for multi-day periods
    if (_isBulkMode && _period != AbsencePeriod.day) {
      return _buildMultiDayTimetable(displaySlots);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Emploi du temps - ${DateFormat('EEEE dd/MM', 'fr_FR').format(_selectedDate)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  if (_selectedTimetableSlotIds.length == displaySlots.length) {
                    _selectedTimetableSlotIds.clear();
                  } else {
                    _selectedTimetableSlotIds = displaySlots.map((s) => s.id).toSet();
                  }
                });
              },
              icon: Icon(_selectedTimetableSlotIds.length == displaySlots.length ? Icons.deselect : Icons.select_all, size: 16),
              label: Text(_selectedTimetableSlotIds.length == displaySlots.length ? 'Aucun' : 'Tous', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...displaySlots.map((slot) => _buildSlotTile(slot)),
      ],
    );
  }

  Widget _buildMultiDayTimetable(List<TimetableSlotInfo> slots) {
    // Group by day
    final byDay = <int, List<TimetableSlotInfo>>{};
    for (final slot in slots) {
      byDay.putIfAbsent(slot.dayIndex, () => []).add(slot);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            const Text('Séances à marquer absentes', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  if (_selectedTimetableSlotIds.length == slots.length) {
                    _selectedTimetableSlotIds.clear();
                  } else {
                    _selectedTimetableSlotIds = slots.map((s) => s.id).toSet();
                  }
                });
              },
              icon: Icon(_selectedTimetableSlotIds.length == slots.length ? Icons.deselect : Icons.select_all, size: 16),
              label: Text(_selectedTimetableSlotIds.length == slots.length ? 'Aucun' : 'Tous', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView(
            children: [
              for (final day in [1, 2, 3, 4, 5, 6]) // Mon-Sat
                if (byDay.containsKey(day)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      _dayName(day),
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                  ...byDay[day]!.map((slot) => _buildSlotTile(slot)),
                ],
            ],
          ),
        ),
      ],
    );
  }

  String _dayName(int dayIndex) {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[dayIndex];
  }

  Widget _buildSlotTile(TimetableSlotInfo slot) {
    final isSelected = _selectedTimetableSlotIds.contains(slot.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: isSelected ? Colors.orange.shade50 : null,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (v) {
          setState(() {
            if (v == true) {
              _selectedTimetableSlotIds.add(slot.id);
            } else {
              _selectedTimetableSlotIds.remove(slot.id);
            }
          });
        },
        title: Row(
          children: [
            Text(slot.subjectName, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            _SessionTypeChip(type: slot.sessionType),
          ],
        ),
        subtitle: Text(
          '${slot.startTime.substring(0, 5)} - ${slot.endTime.substring(0, 5)} • ${slot.hours}h${slot.room != null ? ' • ${slot.room}' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildSummary() {
    final totalHours = _calculateTotalHours();
    final studentCount = _isBulkMode ? _selectedStudentEnrollmentIds.length : 1;
    final sessionCount = _selectedTimetableSlotIds.length;
    
    int daysCount = 1;
    if (_isBulkMode) {
      switch (_period) {
        case AbsencePeriod.week:
          daysCount = 5; // Weekdays only
          break;
        case AbsencePeriod.month:
          daysCount = _countWeekdaysInMonth(_selectedDate);
          break;
        case AbsencePeriod.custom:
          if (_endDate != null) {
            daysCount = _countWeekdaysBetween(_selectedDate, _endDate!);
          }
          break;
        default:
          daysCount = 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              const Text('Résumé', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• $studentCount étudiant(s) × $sessionCount séance(s)${daysCount > 1 ? ' × $daysCount jours' : ''} = ${studentCount * sessionCount * daysCount} absence(s)',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            '• Total: ${totalHours * studentCount * daysCount} heures d\'absence',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  double _calculateTotalHours() {
    double total = 0;
    for (final slotId in _selectedTimetableSlotIds) {
      final slot = _classTimetableSlots.firstWhere((s) => s.id == slotId, orElse: () => _classTimetableSlots.first);
      total += slot.hours;
    }
    return total;
  }

  int _countWeekdaysInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return _countWeekdaysBetween(firstDay, lastDay);
  }

  int _countWeekdaysBetween(DateTime start, DateTime end) {
    int count = 0;
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      if (d.weekday <= 6) count++; // Mon-Sat
    }
    return count;
  }

  Future<void> _onClassChanged(String? classId) async {
    setState(() {
      _selectedClassId = classId;
      _selectedStudentEnrollmentId = null;
      _classStudents = [];
      _selectedStudentEnrollmentIds.clear();
      _classTimetableSlots = [];
      _selectedTimetableSlotIds.clear();
    });
    if (classId != null) {
      setState(() => _isLoading = true);
      final students = await widget.ref.read(absencesProvider.notifier).getStudentsForClass(classId);
      final slots = widget.ref.read(absencesProvider.notifier).getTimetableSlotsForClass(classId);
      setState(() {
        _classStudents = students;
        _classTimetableSlots = slots;
        if (_isBulkMode) {
          _selectedStudentEnrollmentIds = students.where((s) => s.enrollmentId != null).map((s) => s.enrollmentId!).toSet();
        }
        // Auto-select all slots for the current day
        _updateTimetableSlotsForPeriod();
        _isLoading = false;
      });
    }
  }

  void _updateTimetableSlotsForPeriod() {
    if (_period == AbsencePeriod.day) {
      final dayIndex = _selectedDate.weekday;
      _selectedTimetableSlotIds = _classTimetableSlots.where((s) => s.dayIndex == dayIndex).map((s) => s.id).toSet();
    } else {
      // For week/month, select all by default
      _selectedTimetableSlotIds = _classTimetableSlots.map((s) => s.id).toSet();
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _selectedDate : (_endDate ?? _selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedDate = picked;
          _updateTimetableSlotsForPeriod();
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _getSaveButtonText() {
    if (_isBulkMode) {
      final count = _selectedStudentEnrollmentIds.length * _selectedTimetableSlotIds.length;
      return 'Créer ($count)';
    }
    return 'Créer (${_selectedTimetableSlotIds.length})';
  }

  bool _canSubmit() {
    if (_selectedClassId == null) return false;
    if (_selectedTimetableSlotIds.isEmpty) return false;
    if (_isBulkMode) {
      if (_selectedStudentEnrollmentIds.isEmpty) return false;
      if (_period == AbsencePeriod.custom && _endDate == null) return false;
    } else {
      if (_selectedStudentEnrollmentId == null) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final notifier = widget.ref.read(absencesProvider.notifier);
      int totalCreated = 0;

      if (_isBulkMode) {
        // Determine date range based on period
        DateTime startDate = _selectedDate;
        DateTime endDate = _selectedDate;
        
        switch (_period) {
          case AbsencePeriod.day:
            endDate = _selectedDate;
            break;
          case AbsencePeriod.week:
            // Start from Monday of the selected week
            startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
            endDate = startDate.add(const Duration(days: 5)); // Mon-Sat
            break;
          case AbsencePeriod.month:
            startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
            endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
            break;
          case AbsencePeriod.custom:
            endDate = _endDate!;
            break;
        }

        if (_period == AbsencePeriod.day) {
          totalCreated = await notifier.createAbsencesFromTimetable(
            classId: _selectedClassId!,
            date: _selectedDate,
            enrollmentIds: _selectedStudentEnrollmentIds.toList(),
            timetableSlotIds: _selectedTimetableSlotIds.toList(),
            reason: _reason.isNotEmpty ? _reason : null,
            justified: _justified,
          );
        } else {
          totalCreated = await notifier.createAbsencesForDateRange(
            classId: _selectedClassId!,
            startDate: startDate,
            endDate: endDate,
            enrollmentIds: _selectedStudentEnrollmentIds.toList(),
            timetableSlotIds: _selectedTimetableSlotIds.toList(),
            reason: _reason.isNotEmpty ? _reason : null,
            justified: _justified,
          );
        }
      } else {
        // Single student
        totalCreated = await notifier.createAbsencesFromTimetable(
          classId: _selectedClassId!,
          date: _selectedDate,
          enrollmentIds: [_selectedStudentEnrollmentId!],
          timetableSlotIds: _selectedTimetableSlotIds.toList(),
          reason: _reason.isNotEmpty ? _reason : null,
          justified: _justified,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$totalCreated absence(s) créée(s)'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Chip for session type (CI, TD, TP)
class _SessionTypeChip extends StatelessWidget {
  final String? type;
  const _SessionTypeChip({this.type});

  @override
  Widget build(BuildContext context) {
    if (type == null) return const Text('—');
    
    Color bg;
    switch (type) {
      case 'CI': bg = Colors.blue.shade100; break;
      case 'TD': bg = Colors.green.shade100; break;
      case 'TP': bg = Colors.purple.shade100; break;
      default: bg = Colors.grey.shade100;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(type!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
    );
  }
}

/// Badge for justified/not justified status
class _JustifiedBadge extends StatelessWidget {
  final bool justified;
  final VoidCallback onTap;
  const _JustifiedBadge({required this.justified, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: justified ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              justified ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: justified ? Colors.green.shade700 : Colors.red.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              justified ? 'Oui' : 'Non',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: justified ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
