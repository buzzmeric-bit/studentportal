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
                _buildTopBar(context, semestersAsync),
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

  Widget _buildTopBar(BuildContext context, AsyncValue<SemestersState> semestersAsync) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Row(
        children: [
          Text('Semestres', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          // Academic year filter
          semestersAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (state) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: state.selectedAcademicYearId,
                  hint: const Text('Année scolaire'),
                  items: state.academicYears.map((year) => DropdownMenuItem(
                    value: year.id,
                    child: Row(
                      children: [
                        Text(year.name),
                        if (year.isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Actuel', style: TextStyle(fontSize: 10, color: Colors.green.shade800)),
                          ),
                        ],
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => ref.read(semestersProvider.notifier).selectAcademicYear(v),
                ),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showSemesterDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter Semestre'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, SemestersState state) {
    final semesters = state.filteredSemesters;
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
            DataColumn2(label: Text('N°', style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 60),
            DataColumn2(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
            DataColumn2(label: Text('Année scolaire', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn2(label: Text('Début', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn2(label: Text('Fin', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn2(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn2(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)), fixedWidth: 150),
          ],
          rows: semesters.map((s) => DataRow2(
            cells: [
              DataCell(Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text('${s.number}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800))),
              )),
              DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(s.academicYearName ?? '-', style: TextStyle(color: Colors.grey.shade600))),
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
            const SizedBox(height: 8),
            if (state.selectedAcademicYear != null)
              Text('pour ${state.selectedAcademicYear!.name}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ])),
        ),
      ),
    );
  }

  void _showSemesterDialog(BuildContext context, {SemesterModel? semester}) {
    final asyncState = ref.read(semestersProvider);
    final state = asyncState.value;
    if (state == null) return;
    
    // Auto-generate name for new semester
    final isNew = semester == null;
    final autoName = isNew ? state.nextSemesterName : semester!.name;
    final autoNumber = isNew ? state.nextSemesterNumber : semester!.number;
    
    final nameCtrl = TextEditingController(text: autoName);
    int semesterNumber = autoNumber;
    
    // Calculate default dates
    final minStartDate = state.minStartDateForNewSemester;
    DateTime startDate = semester?.startDate ?? minStartDate ?? DateTime.now();
    DateTime endDate = semester?.endDate ?? startDate.add(const Duration(days: 120)); // ~4 months
    
    String? selectedYearId = semester?.academicYearId ?? state.selectedAcademicYearId;
    bool isCurrent = semester?.isCurrent ?? false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Validate dates
          void validateDates() {
            errorMessage = null;
            if (startDate.isAfter(endDate)) {
              errorMessage = 'La date de début doit être avant la date de fin';
            } else if (minStartDate != null && isNew && startDate.isBefore(minStartDate)) {
              errorMessage = 'Le nouveau semestre doit commencer après le ${DateFormat('dd/MM/yyyy').format(minStartDate.subtract(const Duration(days: 1)))}';
            }
            setDialogState(() {});
          }
          
          return AlertDialog(
            title: Row(
              children: [
                Icon(isNew ? Icons.add_circle : Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text(isNew ? 'Nouveau semestre' : 'Modifier le semestre'),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Academic Year selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedYearId,
                      isExpanded: true,
                      hint: const Text('Sélectionner l\'année scolaire *'),
                      items: state.academicYears.map((year) => DropdownMenuItem(
                        value: year.id,
                        child: Text(year.name),
                      )).toList(),
                      onChanged: isNew ? (v) => setDialogState(() => selectedYearId = v) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Semester number and name in row
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'N°',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: '$semesterNumber'),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null && n > 0) {
                            semesterNumber = n;
                            nameCtrl.text = 'Semestre $n';
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl, 
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: Semestre 1',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info card about minimum date
                if (isNew && minStartDate != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Le semestre précédent se termine le ${DateFormat('dd/MM/yyyy').format(minStartDate.subtract(const Duration(days: 1)))}',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Date pickers
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date de début', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate), style: const TextStyle(fontSize: 14)),
                        trailing: const Icon(Icons.calendar_today, size: 20),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx, 
                            initialDate: startDate, 
                            firstDate: minStartDate ?? DateTime(2020), 
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                              // Auto-adjust end date if needed
                              if (endDate.isBefore(startDate)) {
                                endDate = startDate.add(const Duration(days: 120));
                              }
                            });
                            validateDates();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date de fin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate), style: const TextStyle(fontSize: 14)),
                        trailing: const Icon(Icons.calendar_today, size: 20),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx, 
                            initialDate: endDate, 
                            firstDate: startDate, 
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                            validateDates();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                // Error message
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(errorMessage!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero, 
                  title: const Text('Définir comme semestre actuel'), 
                  value: isCurrent, 
                  onChanged: (v) => setDialogState(() => isCurrent = v ?? false),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: errorMessage != null || nameCtrl.text.isEmpty || selectedYearId == null 
                  ? null 
                  : () async {
                      final notifier = ref.read(semestersProvider.notifier);
                      if (isNew) {
                        await notifier.create(
                          name: nameCtrl.text, 
                          number: semesterNumber,
                          startDate: startDate, 
                          endDate: endDate, 
                          academicYearId: selectedYearId!,
                          isCurrent: isCurrent,
                        );
                      } else {
                        await notifier.updateSemester(
                          id: semester!.id, 
                          name: nameCtrl.text, 
                          number: semesterNumber,
                          startDate: startDate, 
                          endDate: endDate,
                        );
                        if (isCurrent && !semester.isCurrent) {
                          await notifier.setCurrentSemester(semester.id);
                        }
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text(isNew ? 'Créer' : 'Modifier', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
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