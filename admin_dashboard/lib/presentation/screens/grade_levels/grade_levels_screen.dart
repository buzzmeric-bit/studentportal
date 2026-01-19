import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/grade_levels_provider.dart';
import '../../widgets/admin_sidebar.dart';
import '../../../data/models/academic_models.dart';

class GradeLevelsScreen extends ConsumerStatefulWidget {
  const GradeLevelsScreen({super.key});
  @override
  ConsumerState<GradeLevelsScreen> createState() => _GradeLevelsScreenState();
}

class _GradeLevelsScreenState extends ConsumerState<GradeLevelsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String? _expandedGradeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(gradeLevelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/grade-levels'),
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
                        _buildGradesTab(context, state),
                        _buildSectionsTab(context, state),
                        _buildExamTypesTab(context, state),
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
              Text('Niveaux & Filières', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('Gérer les niveaux scolaires, filières et types d\'examens', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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
              onChanged: (v) => ref.read(gradeLevelsProvider.notifier).setSearch(v),
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            onSelected: (v) => _showAddDialog(v),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'grade', child: Row(children: [Icon(Icons.school), SizedBox(width: 8), Text('Ajouter Niveau')])),
              const PopupMenuItem(value: 'section', child: Row(children: [Icon(Icons.category), SizedBox(width: 8), Text('Ajouter Filière')])),
              const PopupMenuItem(value: 'exam', child: Row(children: [Icon(Icons.quiz), SizedBox(width: 8), Text('Ajouter Type d\'examen')])),
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
          Tab(icon: Icon(Icons.school), text: 'Niveaux'),
          Tab(icon: Icon(Icons.category), text: 'Filières'),
          Tab(icon: Icon(Icons.quiz), text: 'Types d\'examen'),
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
            onPressed: () => ref.read(gradeLevelsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // ==================== GRADES TAB ====================
  Widget _buildGradesTab(BuildContext context, GradeLevelsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          Row(
            children: [
              _buildFilterChip('Tous', null, state),
              const SizedBox(width: 8),
              _buildFilterChip('Collège', 'college', state),
              const SizedBox(width: 8),
              _buildFilterChip('Secondaire', 'secondaire', state),
              const Spacer(),
              Text('${state.filtered.length} niveau(x)', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 24),
          
          // College Section
          if (state.selectedLevelType == null || state.selectedLevelType == 'college') ...[
            _buildLevelSection('Collège (Enseignement de Base)', Icons.school, Colors.blue, state.collegeGrades, state),
            const SizedBox(height: 24),
          ],
          
          // Secondaire Section
          if (state.selectedLevelType == null || state.selectedLevelType == 'secondaire') ...[
            _buildLevelSection('Secondaire', Icons.auto_stories, Colors.purple, state.secondaireGrades, state),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, GradeLevelsState state) {
    final isSelected = state.selectedLevelType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(gradeLevelsProvider.notifier).setLevelTypeFilter(value),
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildLevelSection(String title, IconData icon, Color color, List<GradeLevelModel> grades, GradeLevelsState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                Text('${grades.length} niveau(x)', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (grades.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('Aucun niveau', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            ...grades.map((grade) => _buildGradeCard(grade, color, state)),
        ],
      ),
    );
  }

  Widget _buildGradeCard(GradeLevelModel grade, Color color, GradeLevelsState state) {
    final isExpanded = _expandedGradeId == grade.id;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedGradeId = isExpanded ? null : grade.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(grade.code, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(grade.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _infoTag(Icons.class_, '${grade.classCount} classe(s)'),
                            const SizedBox(width: 12),
                            if (grade.sections.isNotEmpty)
                              _infoTag(Icons.category, '${grade.sections.length} filière(s)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showGradeDialog(grade),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _confirmDeleteGrade(grade),
                    tooltip: 'Supprimer',
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                ],
              ),
            ),
          ),
          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(grade, state),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(GradeLevelModel grade, GradeLevelsState state) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sections assigned to this grade
          if (grade.levelType == 'secondaire') ...[
            Row(
              children: [
                const Text('Filières:', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAssignSectionDialog(grade, state),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Assigner'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (grade.sections.isEmpty)
              Text('Aucune filière assignée', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: grade.sections.map((section) => Chip(
                  label: Text(section.name),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeSectionFromGrade(grade.id, section.id),
                )).toList(),
              ),
            const SizedBox(height: 16),
          ],
          
          // Classes in this grade
          Row(
            children: [
              const Text('Classes:', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showClassDialog(grade, state),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nouvelle classe'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (grade.classes.isEmpty)
            Text('Aucune classe', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: grade.classes.map((cls) => Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () {
                    debugPrint('GradeLevels: Navigating to class ${cls.id} (${cls.name})');
                    context.go('/classes/${cls.id}');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.class_, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(cls.name),
                        if (cls.sectionName != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(cls.sectionName!, style: TextStyle(fontSize: 11, color: Colors.purple.shade700)),
                          ),
                        ],
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _infoTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  // ==================== SECTIONS TAB ====================
  Widget _buildSectionsTab(BuildContext context, GradeLevelsState state) {
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
                  const Icon(Icons.category, color: Colors.purple),
                  const SizedBox(width: 12),
                  const Text('Filières (Sections)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${state.sections.length} filière(s)', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.sections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Aucune filière', style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showSectionDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter une filière'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: state.sections.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) => _buildSectionTile(state.sections[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTile(SectionModel section) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(section.code, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700, fontSize: 11))),
      ),
      title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: section.description != null ? Text(section.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showSectionDialog(section)),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _confirmDeleteSection(section)),
        ],
      ),
    );
  }

  // ==================== EXAM TYPES TAB ====================
  Widget _buildExamTypesTab(BuildContext context, GradeLevelsState state) {
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
                  const Icon(Icons.quiz, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Text('Types d\'Examen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${state.examTypes.length} type(s)', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.examTypes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Aucun type d\'examen', style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showExamTypeDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un type'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: state.examTypes.length,
                      itemBuilder: (ctx, i) => _buildExamTypeCard(state.examTypes[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamTypeCard(ExamTypeModel examType) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(examType.code, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 12))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(examType.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (examType.description != null)
                  Text(examType.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showExamTypeDialog(examType)),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _confirmDeleteExamType(examType)),
        ],
      ),
    );
  }

  // ==================== DIALOGS ====================
  void _showAddDialog(String type) {
    switch (type) {
      case 'grade': _showGradeDialog(); break;
      case 'section': _showSectionDialog(); break;
      case 'exam': _showExamTypeDialog(); break;
    }
  }

  void _showGradeDialog([GradeLevelModel? grade]) {
    final nameCtrl = TextEditingController(text: grade?.name);
    final codeCtrl = TextEditingController(text: grade?.code);
    final descCtrl = TextEditingController(text: grade?.description);
    String levelType = grade?.levelType ?? 'college';
    int orderIndex = grade?.orderIndex ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(grade == null ? 'Nouveau Niveau' : 'Modifier Niveau'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom *', hintText: 'Ex: 7ème Année Moyenne')),
                const SizedBox(height: 16),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *', hintText: 'Ex: 7AM')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: levelType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'college', child: Text('Collège (Enseignement de Base)')),
                    DropdownMenuItem(value: 'secondaire', child: Text('Lycée (Secondaire)')),
                  ],
                  onChanged: (v) => setState(() => levelType = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Ordre', hintText: 'Ordre d\'affichage'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: orderIndex.toString()),
                  onChanged: (v) => orderIndex = int.tryParse(v) ?? 0,
                ),
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
                final newGrade = GradeLevelModel(
                  id: grade?.id ?? '',
                  name: nameCtrl.text,
                  code: codeCtrl.text,
                  levelType: levelType,
                  orderIndex: orderIndex,
                  description: descCtrl.text.isEmpty ? null : descCtrl.text,
                );
                try {
                  if (grade == null) {
                    await ref.read(gradeLevelsProvider.notifier).addGradeLevel(newGrade);
                  } else {
                    await ref.read(gradeLevelsProvider.notifier).updateGradeLevel(grade.id, newGrade);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSuccess(grade == null ? 'Niveau ajouté' : 'Niveau modifié');
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
              child: Text(grade == null ? 'Ajouter' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSectionDialog([SectionModel? section]) {
    final nameCtrl = TextEditingController(text: section?.name);
    final codeCtrl = TextEditingController(text: section?.code);
    final descCtrl = TextEditingController(text: section?.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(section == null ? 'Nouvelle Filière' : 'Modifier Filière'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom *', hintText: 'Ex: Sciences Expérimentales')),
              const SizedBox(height: 16),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *', hintText: 'Ex: SE')),
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
              final newSection = SectionModel(
                id: section?.id ?? '',
                name: nameCtrl.text,
                code: codeCtrl.text,
                description: descCtrl.text.isEmpty ? null : descCtrl.text,
              );
              try {
                if (section == null) {
                  await ref.read(gradeLevelsProvider.notifier).addSection(newSection);
                } else {
                  await ref.read(gradeLevelsProvider.notifier).updateSection(section.id, newSection);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _showSuccess(section == null ? 'Filière ajoutée' : 'Filière modifiée');
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            child: Text(section == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showExamTypeDialog([ExamTypeModel? examType]) {
    final nameCtrl = TextEditingController(text: examType?.name);
    final codeCtrl = TextEditingController(text: examType?.code);
    final descCtrl = TextEditingController(text: examType?.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(examType == null ? 'Nouveau Type d\'Examen' : 'Modifier Type d\'Examen'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom *', hintText: 'Ex: Devoir, Composition')),
              const SizedBox(height: 16),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code *', hintText: 'Ex: DEV, COMP')),
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
              final newExamType = ExamTypeModel(
                id: examType?.id ?? '',
                name: nameCtrl.text,
                code: codeCtrl.text,
                description: descCtrl.text.isEmpty ? null : descCtrl.text,
              );
              try {
                if (examType == null) {
                  await ref.read(gradeLevelsProvider.notifier).addExamType(newExamType);
                } else {
                  await ref.read(gradeLevelsProvider.notifier).updateExamType(examType.id, newExamType);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _showSuccess(examType == null ? 'Type ajouté' : 'Type modifié');
              } catch (e) {
                _showError('Erreur: $e');
              }
            },
            child: Text(examType == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showAssignSectionDialog(GradeLevelModel grade, GradeLevelsState state) {
    final assignedIds = grade.sections.map((s) => s.id).toSet();
    final available = state.sections.where((s) => !assignedIds.contains(s.id)).toList();

    if (available.isEmpty) {
      _showError('Toutes les filières sont déjà assignées');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assigner une Filière'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: available.map((section) => ListTile(
              title: Text(section.name),
              subtitle: Text(section.code),
              onTap: () async {
                try {
                  await ref.read(gradeLevelsProvider.notifier).assignSectionToGrade(grade.id, section.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSuccess('Filière assignée');
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
            )).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> _removeSectionFromGrade(String gradeId, String sectionId) async {
    try {
      await ref.read(gradeLevelsProvider.notifier).removeSectionFromGrade(gradeId, sectionId);
      _showSuccess('Filière retirée');
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _confirmDeleteGrade(GradeLevelModel grade) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${grade.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(gradeLevelsProvider.notifier).deleteGradeLevel(grade.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSuccess('Niveau supprimé');
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

  void _confirmDeleteSection(SectionModel section) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${section.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(gradeLevelsProvider.notifier).deleteSection(section.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSuccess('Filière supprimée');
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

  void _confirmDeleteExamType(ExamTypeModel examType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${examType.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(gradeLevelsProvider.notifier).deleteExamType(examType.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSuccess('Type supprimé');
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

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ==================== CLASS MANAGEMENT ====================
  void _showClassDialog(GradeLevelModel grade, GradeLevelsState state) {
    final nameCtrl = TextEditingController();
    String? selectedSectionId;
    
    // For secondaire, sections are required
    final availableSections = grade.levelType == 'secondaire' ? grade.sections : <SectionModel>[];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.class_, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text('Nouvelle Classe - ${grade.name}'),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom de la classe *',
                    hintText: 'Ex: ${grade.code}-A ou 7B1',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                if (availableSections.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedSectionId,
                    decoration: InputDecoration(
                      labelText: 'Filière *',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: availableSections.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedSectionId = v),
                  ),
                ] else if (grade.levelType == 'secondaire') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aucune filière n\'est assignée à ce niveau. Veuillez d\'abord assigner des filières.',
                            style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Les classes du collège n\'ont pas de filière.',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) {
                  _showError('Le nom est requis');
                  return;
                }
                if (grade.levelType == 'secondaire' && availableSections.isNotEmpty && selectedSectionId == null) {
                  _showError('La filière est requise pour le secondaire');
                  return;
                }
                
                try {
                  await ref.read(gradeLevelsProvider.notifier).addClass(
                    name: nameCtrl.text,
                    gradeLevelId: grade.id,
                    sectionId: selectedSectionId,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSuccess('Classe "${nameCtrl.text}" créée');
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer la classe'),
            ),
          ],
        ),
      ),
    );
  }
}
