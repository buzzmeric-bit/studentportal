import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/class_model.dart';
import '../../providers/classes_provider.dart';
import '../../providers/grade_levels_provider.dart';
import '../../widgets/admin_sidebar.dart';
import 'class_form_dialog.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});
  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  String? _expandedNiveauId;
  bool _showFilters = true;
  String _viewMode = 'grouped'; // 'grouped' or 'list'

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final gradeLevelsAsync = ref.watch(gradeLevelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/classes'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, classesAsync, gradeLevelsAsync),
                Expanded(
                  child: classesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _buildErrorState(e),
                    data: (state) => _buildContent(context, state, gradeLevelsAsync),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AsyncValue<ClassesState> classesAsync, AsyncValue gradeLevelsAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Classes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Gérer les classes et groupes', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
              const Spacer(),
              // View toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggle(Icons.view_agenda, 'grouped'),
                    _buildViewToggle(Icons.list, 'list'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                onPressed: () => setState(() => _showFilters = !_showFilters),
                tooltip: 'Filtres',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showClassDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle classe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, String mode) {
    final isActive = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 20),
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
            onPressed: () => ref.read(classesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ClassesState state, AsyncValue gradeLevelsAsync) {
    return Row(
      children: [
        // Left filters panel
        if (_showFilters)
          Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: _buildFiltersPanel(state, gradeLevelsAsync),
          ),
        
        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                Row(
                  children: [
                    _buildStatCard(Icons.class_, 'Total classes', state.filtered.length.toString(), Colors.blue),
                    const SizedBox(width: 16),
                    _buildStatCard(Icons.people, 'Total étudiants', state.filtered.fold(0, (sum, c) => sum + c.studentCount).toString(), Colors.green),
                    const SizedBox(width: 16),
                    _buildStatCard(Icons.school, 'Niveaux', _getUniqueNiveaux(state.filtered).length.toString(), Colors.orange),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Classes display
                _viewMode == 'grouped'
                    ? _buildGroupedView(state.filtered, gradeLevelsAsync)
                    : _buildListView(state.filtered),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersPanel(ClassesState state, AsyncValue gradeLevelsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.filter_alt, size: 20),
            const SizedBox(width: 8),
            Text('Filtres', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onChanged: (v) => ref.read(classesProvider.notifier).setSearch(v),
        ),
        const SizedBox(height: 16),
        gradeLevelsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (glState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Par niveau', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              ...glState.gradeLevels.map((g) => _buildFilterChip(
                g.name,
                state.selectedGradeLevelId == g.id,
                () => ref.read(classesProvider.notifier).setGradeLevelFilter(
                  state.selectedGradeLevelId == g.id ? null : g.id,
                ),
              )),
            ],
          ),
        ),
        const Divider(height: 32),
        OutlinedButton.icon(
          onPressed: () => ref.read(classesProvider.notifier).clearFilters(),
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Réinitialiser'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.school, size: 16, color: isSelected ? Colors.blue : Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.grey.shade700))),
              if (isSelected) const Icon(Icons.check, size: 16, color: Colors.blue),
            ],
          ),
        ),
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
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String?> _getUniqueNiveaux(List<ClassModel> classes) {
    return classes.map((c) => c.gradeLevelId).toSet().toList();
  }

  Widget _buildGroupedView(List<ClassModel> classes, AsyncValue gradeLevelsAsync) {
    // Group classes by niveau
    final Map<String?, List<ClassModel>> grouped = {};
    for (final cls in classes) {
      grouped.putIfAbsent(cls.gradeLevelId, () => []).add(cls);
    }

    if (grouped.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: grouped.entries.map((entry) {
        final niveauId = entry.key;
        final niveauClasses = entry.value;
        final niveauName = niveauClasses.first.gradeLevelName ?? 'Sans niveau';
        final isExpanded = _expandedNiveauId == niveauId;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: Column(
            children: [
              // Niveau header
              InkWell(
                onTap: () => setState(() => _expandedNiveauId = isExpanded ? null : niveauId),
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
                        child: Icon(Icons.school, color: Colors.blue.shade700, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(niveauName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _infoTag(Icons.class_, '${niveauClasses.length} classe(s)'),
                                const SizedBox(width: 16),
                                _infoTag(Icons.people, '${niveauClasses.fold(0, (sum, c) => sum + c.studentCount)} étudiant(s)'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              
              // Classes cards
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildGroupedBySectionView(niveauClasses),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupedBySectionView(List<ClassModel> classes) {
    // Group by section
    final Map<String?, List<ClassModel>> bySection = {};
    for (final cls in classes) {
      bySection.putIfAbsent(cls.sectionId, () => []).add(cls);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bySection.entries.map((entry) {
        final sectionName = entry.value.first.sectionName ?? 'Sans filière';
        final sectionClasses = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(sectionName, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.orange.shade700)),
                  ),
                  const SizedBox(width: 8),
                  Text('(${sectionClasses.length})', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: sectionClasses.map((cls) => _buildClassCard(cls)).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildClassCard(ClassModel cls) {
    return InkWell(
      onTap: () => context.push('/classes/${cls.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.class_, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(cls.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
                  onSelected: (v) {
                    if (v == 'edit') _showClassDialog(context, cls: cls);
                    if (v == 'delete') _confirmDelete(context, cls);
                    if (v == 'view') context.push('/classes/${cls.id}');
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('Voir les étudiants')])),
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Modifier')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.meeting_room, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(cls.room ?? '-', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${cls.studentCount}/${cls.capacity ?? "-"}', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: cls.capacity != null && cls.capacity! > 0 ? cls.studentCount / cls.capacity! : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                cls.capacity != null && cls.studentCount >= cls.capacity! ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text(
                  'Cliquer pour voir les étudiants →',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade400, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<ClassModel> classes) {
    if (classes.isEmpty) {
      return _buildEmptyState();
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: classes.map((cls) => SizedBox(width: 300, child: _buildClassCard(cls))).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Aucune classe trouvée', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Ajoutez une classe pour commencer', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showClassDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une classe'),
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Classe supprimée'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}