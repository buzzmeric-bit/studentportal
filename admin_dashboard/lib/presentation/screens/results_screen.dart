import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/grading_config_model.dart';
import '../../data/models/student_result_model.dart';
import '../providers/results_provider.dart';
import '../widgets/results/grading_config_dialog.dart';
import '../widgets/results/bulk_grade_entry_dialog.dart';
import '../widgets/results/grade_entry_dialog.dart';
import '../widgets/admin_sidebar.dart';

/// Modern Results Management Screen
/// Redesigned for clarity, efficiency, and visual appeal
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late TabController _viewTabController;
  final _searchController = TextEditingController();
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = ResultsProvider(Supabase.instance.client);
        provider.initialize();
        return provider;
      },
      child: Consumer<ResultsProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Row(
              children: [
                const AdminSidebar(currentRoute: '/results'),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(context, provider),
                      Expanded(
                        child: Row(
                          children: [
                            // Left Panel - Filters & Quick Actions
                            if (_showFilters)
                              _buildLeftPanel(context, provider),
                            
                            // Main Content
                            Expanded(
                              child: _buildMainContent(context, provider),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Top navigation bar with search and actions
  Widget _buildTopBar(BuildContext context, ResultsProvider provider) {
    final theme = Theme.of(context);
    
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Toggle filters
          IconButton(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(_showFilters ? Icons.menu_open : Icons.menu),
            tooltip: _showFilters ? 'Masquer les filtres' : 'Afficher les filtres',
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des Notes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (provider.selectedClassId != null)
                Text(
                  _getSelectedClassName(provider),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          
          const Spacer(),
          
          // Search
          Container(
            width: 280,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un élève...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Quick Actions
          _buildQuickActionButton(
            icon: Icons.calculate_outlined,
            label: 'Calculer',
            onPressed: provider.selectedClassId != null 
                ? () => provider.calculateResults()
                : null,
            isLoading: provider.isLoading,
          ),
          
          const SizedBox(width: 8),
          
          _buildQuickActionButton(
            icon: Icons.edit_note,
            label: 'Saisie groupée',
            color: const Color(0xFF3B82F6),
            onPressed: provider.classResult != null 
                ? () => _showBulkGradeEntry(context, provider)
                : null,
          ),
          
          const SizedBox(width: 8),
          
          IconButton(
            onPressed: () => _showSettingsDialog(context, provider),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuration',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? color,
    bool isLoading = false,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF10B981),
        disabledBackgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: isLoading 
          ? const SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  /// Left panel with filters and quick stats
  Widget _buildLeftPanel(BuildContext context, ResultsProvider provider) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          // Filters Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Filtres'),
                  const SizedBox(height: 16),
                  
                  // Academic Year
                  _buildFilterDropdown(
                    label: 'Année Scolaire',
                    icon: Icons.calendar_today,
                    value: provider.selectedAcademicYearId,
                    items: provider.academicYears,
                    displayField: 'name',
                    onChanged: (v) => provider.setAcademicYear(v),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Semester
                  _buildFilterDropdown(
                    label: 'Semestre',
                    icon: Icons.schedule,
                    value: provider.selectedSemesterId,
                    items: [
                      {'id': null, 'name': 'Tous les semestres'},
                      ...provider.semesters,
                    ],
                    displayField: 'name',
                    onChanged: (v) => provider.setSemester(v),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Class
                  _buildFilterDropdown(
                    label: 'Classe',
                    icon: Icons.class_,
                    value: provider.selectedClassId,
                    items: provider.classes,
                    displayField: 'name',
                    onChanged: (v) => provider.setClass(v),
                    highlighted: true,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Group
                  _buildFilterDropdown(
                    label: 'Groupe',
                    icon: Icons.group,
                    value: provider.selectedGroupId,
                    items: [
                      {'id': null, 'name': 'Tous les groupes'},
                      ...provider.groups,
                    ],
                    displayField: 'name',
                    onChanged: (v) => provider.setGroup(v),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Stats
                  if (provider.classResult != null) ...[
                    _buildSectionTitle('Statistiques'),
                    const SizedBox(height: 16),
                    _buildQuickStats(provider.classResult!),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Subjects
                  if (provider.subjectOfferings.isNotEmpty) ...[
                    _buildSectionTitle('Matières'),
                    const SizedBox(height: 12),
                    _buildSubjectsList(provider),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String displayField,
    required Function(String?) onChanged,
    bool highlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text(
                    'Sélectionner...',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(10),
              items: items.map((item) {
                final id = item['id']?.toString();
                final name = item[displayField]?.toString() ?? '';
                return DropdownMenuItem<String>(
                  value: id,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: const Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(ClassResult result) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(
              label: 'Élèves',
              value: '${result.totalStudents}',
              icon: Icons.people,
              color: const Color(0xFF3B82F6),
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(
              label: 'Moyenne',
              value: result.classAverage?.toStringAsFixed(1) ?? '--',
              icon: Icons.analytics,
              color: const Color(0xFF10B981),
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              label: 'Réussite',
              value: '${result.passedCount}',
              icon: Icons.check_circle,
              color: const Color(0xFF22C55E),
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(
              label: 'Échec',
              value: '${result.failedCount}',
              icon: Icons.cancel,
              color: const Color(0xFFEF4444),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList(ResultsProvider provider) {
    return Column(
      children: provider.subjectOfferings.take(8).map((subject) {
        final name = subject['subjects']?['name'] ?? '';
        final code = subject['subjects']?['code'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Main content area
  Widget _buildMainContent(BuildContext context, ResultsProvider provider) {
    if (provider.selectedClassId == null) {
      return _buildWelcomeState(context);
    }

    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (provider.classResult == null) {
      return _buildCalculatePrompt(context, provider);
    }

    return Column(
      children: [
        // View tabs
        Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // Tabs header
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _buildViewTab(0, Icons.grid_view, 'Notes'),
                    _buildViewTab(1, Icons.leaderboard, 'Classement'),
                    _buildViewTab(2, Icons.article, 'Bulletins'),
                    const Spacer(),
                    // Export button
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Exporter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _viewTabController,
                  children: [
                    _buildGradesTable(context, provider),
                    _buildRankingView(context, provider),
                    _buildBulletinsView(context, provider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewTab(int index, IconData icon, String label) {
    final isSelected = _viewTabController.index == index;
    
    return GestureDetector(
      onTap: () => setState(() => _viewTabController.animateTo(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grades table view
  Widget _buildGradesTable(BuildContext context, ResultsProvider provider) {
    final students = provider.filteredStudents;
    
    if (students.isEmpty) {
      return const Center(child: Text('Aucun élève trouvé'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 48), // Rank
                const Expanded(flex: 2, child: Text('Élève', style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(child: Center(child: Text('S1', style: TextStyle(fontWeight: FontWeight.w600)))),
                const Expanded(child: Center(child: Text('S2', style: TextStyle(fontWeight: FontWeight.w600)))),
                const Expanded(child: Center(child: Text('Moyenne', style: TextStyle(fontWeight: FontWeight.w600)))),
                const SizedBox(width: 80), // Actions
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Students
          ...students.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            return _buildStudentRow(context, provider, student, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildStudentRow(BuildContext context, ResultsProvider provider, StudentResult student, int rank) {
    final avg = student.annualAverage;
    final s1 = student.semester1Average;
    final s2 = student.semester2Average;
    
    Color rankColor = const Color(0xFF64748B);
    if (rank == 1) rankColor = const Color(0xFFEAB308);
    if (rank == 2) rankColor = const Color(0xFF94A3B8);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? rankColor.withOpacity(0.1) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: rankColor,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Student info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                  backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
                  child: student.photoUrl == null
                      ? Text(
                          student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      student.studentCode,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // S1
          Expanded(
            child: Center(
              child: _buildGradeBadge(s1),
            ),
          ),
          
          // S2
          Expanded(
            child: Center(
              child: _buildGradeBadge(s2),
            ),
          ),
          
          // Average
          Expanded(
            child: Center(
              child: _buildGradeBadge(avg, isMain: true),
            ),
          ),
          
          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _showGradeEntry(context, provider, student),
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Modifier les notes',
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                  ),
                ),
                IconButton(
                  onPressed: () => _showStudentDetails(context, student),
                  icon: const Icon(Icons.visibility, size: 18),
                  tooltip: 'Voir détails',
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBadge(double? grade, {bool isMain = false}) {
    if (grade == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('--', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    Color color;
    if (grade >= 16) {
      color = const Color(0xFF22C55E);
    } else if (grade >= 14) {
      color = const Color(0xFF3B82F6);
    } else if (grade >= 12) {
      color = const Color(0xFFEAB308);
    } else if (grade >= 10) {
      color = const Color(0xFFF97316);
    } else {
      color = const Color(0xFFEF4444);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMain ? 16 : 12,
        vertical: isMain ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isMain ? 8 : 6),
        border: isMain ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Text(
        grade.toStringAsFixed(2),
        style: TextStyle(
          fontWeight: isMain ? FontWeight.w700 : FontWeight.w600,
          color: color,
          fontSize: isMain ? 15 : 13,
        ),
      ),
    );
  }

  /// Ranking view
  Widget _buildRankingView(BuildContext context, ResultsProvider provider) {
    final students = List<StudentResult>.from(provider.filteredStudents);
    students.sort((a, b) {
      final avgA = a.annualAverage ?? 0;
      final avgB = b.annualAverage ?? 0;
      return avgB.compareTo(avgA);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top 3 podium
          if (students.length >= 3) ...[
            const Text(
              'Podium',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (students.length > 1) _buildPodiumCard(students[1], 2),
                _buildPodiumCard(students[0], 1),
                if (students.length > 2) _buildPodiumCard(students[2], 3),
              ],
            ),
            const SizedBox(height: 32),
          ],
          
          // Full ranking
          const Text(
            'Classement complet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          
          ...students.asMap().entries.map((e) {
            return _buildRankingRow(e.value, e.key + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(StudentResult student, int rank) {
    final colors = {
      1: const Color(0xFFEAB308), // Gold
      2: const Color(0xFF94A3B8), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };
    
    final heights = {1: 140.0, 2: 110.0, 3: 90.0};
    final color = colors[rank]!;

    return Container(
      width: 150,
      margin: EdgeInsets.only(top: rank == 1 ? 0 : 40),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: rank == 1 ? 40 : 32,
            backgroundColor: color.withOpacity(0.2),
            backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
            child: student.photoUrl == null
                ? Text(
                    student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: rank == 1 ? 24 : 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            student.studentName,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            student.annualAverage?.toStringAsFixed(2) ?? '--',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          // Podium base
          Container(
            height: heights[rank],
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingRow(StudentResult student, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: rank <= 3 ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
            child: Text(
              student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFF3B82F6)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(student.studentName, style: const TextStyle(fontWeight: FontWeight.w500))),
          _buildGradeBadge(student.annualAverage, isMain: true),
        ],
      ),
    );
  }

  /// Bulletins view
  Widget _buildBulletinsView(BuildContext context, ResultsProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.filteredStudents.length,
      itemBuilder: (context, index) {
        final student = provider.filteredStudents[index];
        return _buildBulletinCard(context, student);
      },
    );
  }

  Widget _buildBulletinCard(BuildContext context, StudentResult student) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A5F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
                  child: student.photoUrl == null
                      ? Text(
                          student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        student.className,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Grades
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBulletinRow('Semestre 1', student.semester1Average),
                  const SizedBox(height: 8),
                  _buildBulletinRow('Semestre 2', student.semester2Average),
                  const Divider(height: 24),
                  _buildBulletinRow('Moyenne', student.annualAverage, isMain: true),
                ],
              ),
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Imprimer'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showStudentDetails(context, student),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Détails'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletinRow(String label, double? value, {bool isMain = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isMain ? FontWeight.w600 : FontWeight.w400,
            color: isMain ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        _buildGradeBadge(value, isMain: isMain),
      ],
    );
  }

  /// Empty states
  Widget _buildWelcomeState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              size: 64,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sélectionnez une classe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisissez une classe dans le panneau de gauche\npour afficher et gérer les notes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF3B82F6)),
          SizedBox(height: 24),
          Text(
            'Calcul des résultats...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatePrompt(BuildContext context, ResultsProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calculate,
              size: 64,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Prêt à calculer',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cliquez sur le bouton pour calculer\nles moyennes de la classe',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => provider.calculateResults(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Calculer les résultats', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getSelectedClassName(ResultsProvider provider) {
    final cls = provider.classes.where((c) => c['id'] == provider.selectedClassId).firstOrNull;
    return cls?['name'] ?? '';
  }

  void _showBulkGradeEntry(BuildContext context, ResultsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: const BulkGradeEntryDialog(),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, ResultsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: GradingConfigDialog(
          initialConfig: provider.gradingConfig,
          onSave: (config) {
            provider.saveGradingConfig(config);
          },
        ),
      ),
    );
  }

  void _showGradeEntry(BuildContext context, ResultsProvider provider, StudentResult student) {
    showDialog(
      context: context,
      builder: (context) => GradeEntryDialog(
        student: student,
        gradingConfig: provider.gradingConfig,
        onSave: (grades) async {
          // Save grades
        },
      ),
    );
  }

  void _showStudentDetails(BuildContext context, StudentResult student) {
    // Show detailed student view
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                    backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
                    child: student.photoUrl == null
                        ? Text(
                            student.studentName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24, color: Color(0xFF3B82F6)),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        Text('${student.className} • ${student.studentCode}', style: const TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  _buildGradeBadge(student.annualAverage, isMain: true),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Détails des notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: student.semesters.expand((sem) {
                    return sem.subjects.map((subj) => ListTile(
                      title: Text(subj.subjectName),
                      subtitle: Text('Coef: ${subj.coefficient}'),
                      trailing: _buildGradeBadge(subj.average),
                    ));
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
