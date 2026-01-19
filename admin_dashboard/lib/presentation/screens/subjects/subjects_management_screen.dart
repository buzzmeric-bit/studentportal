import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subjects_management_provider.dart';
import '../../widgets/admin_sidebar.dart';
import '../../../data/models/academic_models.dart';
import '../../../data/models/school_models.dart';

class SubjectsManagementScreen extends ConsumerStatefulWidget {
  const SubjectsManagementScreen({super.key});
  @override
  ConsumerState<SubjectsManagementScreen> createState() => _SubjectsManagementScreenState();
}

class _SubjectsManagementScreenState extends ConsumerState<SubjectsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(subjectsManagementProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/subjects'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                _buildTabBar(),
                Expanded(
                  child: stateAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _buildErrorState(e),
                    data: (state) => TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSubjectsTab(context, state),
                        _buildAssignmentsTab(context, state),
                      ],
                    ),
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
              Text('Matières', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('Gérer les matières, coefficients et configurations d\'examens', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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
              onChanged: (v) => ref.read(subjectsManagementProvider.notifier).setSearch(v),
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            onSelected: (v) => _showAddDialog(v),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'subject', child: Row(children: [Icon(Icons.book), SizedBox(width: 8), Text('Nouvelle Matière')])),
              const PopupMenuItem(value: 'assignment', child: Row(children: [Icon(Icons.assignment), SizedBox(width: 8), Text('Assigner Matière')])),
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.blue,
        tabs: const [
          Tab(icon: Icon(Icons.book), text: 'Toutes les Matières'),
          Tab(icon: Icon(Icons.assignment), text: 'Affectations par Niveau'),
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
            onPressed: () => ref.read(subjectsManagementProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // ==================== SUBJECTS TAB ====================
  Widget _buildSubjectsTab(BuildContext context, SubjectsManagementState state) {
    final subjects = state.filteredSubjects;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.book, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Text('Liste des Matières', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${subjects.length} matière(s)', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: subjects.isEmpty
                  ? _buildEmptyState('Aucune matière', Icons.book_outlined, () => _showSubjectDialog())
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: subjects.length,
                      itemBuilder: (ctx, i) => _buildSubjectCard(subjects[i], state),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(SubjectModel subject, SubjectsManagementState state) {
    // Count how many assignments this subject has
    final assignmentCount = state.assignments.where((a) => a.subjectId == subject.id).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getSubjectColor(subject.code).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                subject.code ?? subject.name.substring(0, 2).toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, color: _getSubjectColor(subject.code), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.assignment, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('$assignmentCount affectation(s)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                if (subject.description != null) ...[
                  const SizedBox(height: 2),
                  Text(subject.description!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showSubjectDialog(subject),
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: () => _confirmDeleteSubject(subject),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ASSIGNMENTS TAB ====================
  Widget _buildAssignmentsTab(BuildContext context, SubjectsManagementState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('Filtrer par:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String?>(
                    value: state.filterGradeId,
                    decoration: const InputDecoration(labelText: 'Niveau', contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous les niveaux')),
                      ...state.gradeLevels.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
                    ],
                    onChanged: (v) => ref.read(subjectsManagementProvider.notifier).setGradeFilter(v),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String?>(
                    value: state.filterSectionId,
                    decoration: const InputDecoration(labelText: 'Filière', contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Toutes les filières')),
                      ...state.sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => ref.read(subjectsManagementProvider.notifier).setSectionFilter(v),
                  ),
                ),
                const Spacer(),
                Text('${state.filteredAssignments.length} affectation(s)', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Assignments grouped by grade
          Expanded(
            child: state.filteredAssignments.isEmpty
                ? _buildEmptyState('Aucune affectation', Icons.assignment_outlined, () => _showAssignmentDialog(state))
                : ListView(
                    children: state.assignmentsByGrade.entries.map((entry) => 
                      _buildGradeAssignmentSection(entry.key, entry.value, state)
                    ).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeAssignmentSection(String gradeName, List<SubjectAssignmentModel> assignments, SubjectsManagementState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.school, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Text(gradeName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Text('${assignments.length} affectation(s)', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                ),
              ],
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Matière', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                Expanded(flex: 2, child: Text('Filière', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                Expanded(child: Text('Coef', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('H/Sem', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Types d\'examen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...assignments.map((a) => _buildAssignmentRow(a, state)),
        ],
      ),
    );
  }

  Widget _buildAssignmentRow(SubjectAssignmentModel assignment, SubjectsManagementState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getSubjectColor(assignment.subjectCode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      assignment.subjectCode ?? '?',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getSubjectColor(assignment.subjectCode)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assignment.subjectName ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (assignment.isMainSubject)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                          child: Text('Principal', style: TextStyle(fontSize: 9, color: Colors.amber.shade800)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(assignment.sectionName ?? '-', style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCoefColor(assignment.coefficient),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                assignment.coefficient.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Text('${assignment.weeklyHours.toStringAsFixed(0)}h', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: assignment.examConfigs.isEmpty
                  ? [Text('-', style: TextStyle(color: Colors.grey.shade400))]
                  : assignment.examConfigs.map((c) => Tooltip(
                      message: '${c.examTypeName}: ${c.countPerSemester}x, poids ${c.weight}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text(c.examTypeCode ?? c.examTypeName ?? '?', style: const TextStyle(fontSize: 10)),
                      ),
                    )).toList(),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showAssignmentDialog(state, assignment),
                  tooltip: 'Modifier',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => _confirmDeleteAssignment(assignment),
                  tooltip: 'Supprimer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, VoidCallback onAdd) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGS ====================
  void _showAddDialog(String type) {
    final stateAsync = ref.read(subjectsManagementProvider);
    stateAsync.whenData((state) {
      switch (type) {
        case 'subject': _showSubjectDialog(); break;
        case 'assignment': _showAssignmentDialog(state); break;
      }
    });
  }

  void _showSubjectDialog([SubjectModel? subject]) {
    final nameCtrl = TextEditingController(text: subject?.name);
    final codeCtrl = TextEditingController(text: subject?.code);
    final descCtrl = TextEditingController(text: subject?.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(subject == null ? 'Nouvelle Matière' : 'Modifier Matière'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom *', hintText: 'Ex: Mathématiques')),
              const SizedBox(height: 16),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *', hintText: 'Ex: MATH')),
              const SizedBox(height: 16),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
              final newSubject = SubjectModel(
                id: subject?.id ?? '',
                schoolId: subject?.schoolId ?? '',
                name: nameCtrl.text,
                code: codeCtrl.text,
                description: descCtrl.text.isEmpty ? null : descCtrl.text,
              );
              try {
                if (subject == null) {
                  await ref.read(subjectsManagementProvider.notifier).addSubject(newSubject);
                } else {
                  await ref.read(subjectsManagementProvider.notifier).updateSubject(subject.id, newSubject);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _showSuccess(subject == null ? 'Matière ajoutée' : 'Matière modifiée');
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            child: Text(subject == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDialog(SubjectsManagementState state, [SubjectAssignmentModel? assignment]) {
    String? subjectId = assignment?.subjectId;
    String? gradeId = assignment?.gradeLevelId;
    String? sectionId = assignment?.sectionId;
    double coefficient = assignment?.coefficient ?? 1.0;
    double weeklyHours = assignment?.weeklyHours ?? 0;
    bool isMainSubject = assignment?.isMainSubject ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(assignment == null ? 'Nouvelle Affectation' : 'Modifier Affectation'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: subjectId,
                  decoration: const InputDecoration(labelText: 'Matière *'),
                  items: state.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v) => setState(() => subjectId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: gradeId,
                  decoration: const InputDecoration(labelText: 'Niveau *'),
                  items: state.gradeLevels.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                  onChanged: (v) => setState(() => gradeId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: sectionId,
                  decoration: const InputDecoration(labelText: 'Filière (optionnel)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Aucune (toutes)')),
                    ...state.sections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) => setState(() => sectionId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Coefficient'),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: coefficient.toString()),
                        onChanged: (v) => coefficient = double.tryParse(v) ?? 1.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Heures/Semaine'),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: weeklyHours.toString()),
                        onChanged: (v) => weeklyHours = double.tryParse(v) ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Matière principale'),
                  subtitle: const Text('Cette matière est la principale pour cette filière'),
                  value: isMainSubject,
                  onChanged: (v) => setState(() => isMainSubject = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (subjectId == null || gradeId == null) {
                  _showError('Veuillez sélectionner une matière et un niveau');
                  return;
                }
                final newAssignment = SubjectAssignmentModel(
                  id: assignment?.id ?? '',
                  subjectId: subjectId!,
                  gradeLevelId: gradeId!,
                  sectionId: sectionId,
                  coefficient: coefficient,
                  weeklyHours: weeklyHours,
                  isMainSubject: isMainSubject,
                );
                try {
                  if (assignment == null) {
                    await ref.read(subjectsManagementProvider.notifier).addAssignment(newAssignment);
                  } else {
                    await ref.read(subjectsManagementProvider.notifier).updateAssignment(assignment.id, newAssignment);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSuccess(assignment == null ? 'Affectation ajoutée' : 'Affectation modifiée');
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
              child: Text(assignment == null ? 'Ajouter' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSubject(SubjectModel subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${subject.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(subjectsManagementProvider.notifier).deleteSubject(subject.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSuccess('Matière supprimée');
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAssignment(SubjectAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer l\'affectation de "${assignment.subjectName}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(subjectsManagementProvider.notifier).deleteAssignment(assignment.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSuccess('Affectation supprimée');
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String? code) {
    if (code == null) return Colors.grey;
    switch (code.toUpperCase()) {
      case 'MATH': return Colors.blue;
      case 'PHYS': return Colors.orange;
      case 'SVT': return Colors.green;
      case 'AR': return Colors.teal;
      case 'FR': return Colors.purple;
      case 'EN': return Colors.red;
      case 'HG': return Colors.brown;
      case 'PHILO': return Colors.indigo;
      case 'INFO': return Colors.cyan;
      case 'EPS': return Colors.lime;
      default: return Colors.blueGrey;
    }
  }

  Color _getCoefColor(double coef) {
    if (coef >= 5) return Colors.red.shade100;
    if (coef >= 3) return Colors.orange.shade100;
    if (coef >= 2) return Colors.yellow.shade100;
    return Colors.grey.shade100;
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
