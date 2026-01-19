import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_context_provider.dart' as ctx;
import '../../widgets/semester_navigator.dart';
import '../../../data/models/absence_model.dart';

// Selected semester provider (dynamic from DB)
final absencesTrimesterProvider = StateProvider<int>((ref) => 1);

// Search provider
final absencesSearchProvider = StateProvider<String>((ref) => '');

// Get semesters for current enrollment - now uses shared provider
final absencesSemestersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final semesters = await ref.watch(ctx.semestersProvider.future);
  // Convert SemesterInfo to Map<String, dynamic> for backward compatibility
  return semesters.map<Map<String, dynamic>>((s) => <String, dynamic>{
    'id': s.id,
    'name': s.name,
    'number': s.number,
    'is_current': s.isCurrent,
  }).toList();
});

// Real absences provider - fetches from database
final absencesProvider = FutureProvider.family<List<SubjectAbsenceSummary>, int>((ref, semesterNumber) async {
  final authState = ref.watch(authProvider);
  final semesters = await ref.watch(absencesSemestersProvider.future);
  
  if (!authState.isAuthenticated || authState.enrollment == null) {
    debugPrint('absencesProvider: Not authenticated or no enrollment');
    return [];
  }
  
  final enrollmentId = authState.enrollment!.id;
  final schoolId = authState.user?.schoolId ?? authState.enrollment?.classInfo?.schoolId;
  
  // Find the semester ID by number
  final semester = semesters.firstWhere(
    (s) => s['number'] == semesterNumber,
    orElse: () => <String, dynamic>{},
  );
  
  final semesterId = semester['id'] as String?;
  if (semesterId == null) {
    debugPrint('absencesProvider: Semester $semesterNumber not found');
    return [];
  }
  
  final supabase = Supabase.instance.client;
  
  try {
    // 1. Get absence thresholds for the school
    double warningPercent = 20.0;
    double criticalPercent = 30.0;
    double eliminationPercent = 50.0;
    String warningMessage = 'Attention! Vous approchez du seuil d\'absences autorisé.';
    String criticalMessage = 'Attention! Vous avez dépassé le seuil critique d\'absences.';
    String eliminationMessage = 'Vous avez été éliminé de la session principale des examens.';
    
    if (schoolId != null) {
      final thresholdResponse = await supabase
          .from('absence_thresholds')
          .select()
          .eq('school_id', schoolId)
          .maybeSingle();
      
      if (thresholdResponse != null) {
        warningPercent = (thresholdResponse['warning_percent'] as num?)?.toDouble() ?? 20.0;
        criticalPercent = (thresholdResponse['critical_percent'] as num?)?.toDouble() ?? 30.0;
        eliminationPercent = (thresholdResponse['elimination_percent'] as num?)?.toDouble() ?? 50.0;
        warningMessage = thresholdResponse['warning_message'] as String? ?? warningMessage;
        criticalMessage = thresholdResponse['critical_message'] as String? ?? criticalMessage;
        eliminationMessage = thresholdResponse['elimination_message'] as String? ?? eliminationMessage;
      }
    }
    
    // 2. Get subject offerings for the student's class and semester
    final classId = authState.enrollment!.classId;
    
    final subjectOfferingsResponse = await supabase
        .from('subject_offerings')
        .select('''
          id,
          total_hours,
          weekly_ci_hours,
          weekly_tp_hours,
          weeks,
          subjects (
            id,
            code,
            name
          )
        ''')
        .eq('semester_id', semesterId)
        .eq('class_id', classId)
        .eq('is_active', true);
    
    final subjectOfferings = List<Map<String, dynamic>>.from(subjectOfferingsResponse);
    
    if (subjectOfferings.isEmpty) {
      debugPrint('absencesProvider: No subject offerings found');
      return [];
    }
    
    // 3. Get absence records for this enrollment
    final absenceResponse = await supabase
        .from('absence_records')
        .select('subject_offering_id, hours_absent')
        .eq('enrollment_id', enrollmentId);
    
    final absenceRecords = List<Map<String, dynamic>>.from(absenceResponse);
    
    // Group absences by subject_offering_id
    final absencesBySubject = <String, double>{};
    for (final record in absenceRecords) {
      final soId = record['subject_offering_id'] as String?;
      final hours = (record['hours_absent'] as num?)?.toDouble() ?? 0;
      if (soId != null) {
        absencesBySubject[soId] = (absencesBySubject[soId] ?? 0) + hours;
      }
    }
    
    // 4. Build the summary list
    final List<SubjectAbsenceSummary> summaries = [];
    
    for (final so in subjectOfferings) {
      final soId = so['id'] as String;
      final subject = so['subjects'] as Map<String, dynamic>?;
      final totalHours = (so['total_hours'] as num?)?.toDouble() ?? 0;
      final weeklyCi = (so['weekly_ci_hours'] as num?)?.toDouble() ?? 0;
      final weeklyTp = (so['weekly_tp_hours'] as num?)?.toDouble() ?? 0;
      final weeks = (so['weeks'] as num?)?.toInt() ?? 14;
      
      final absentHours = absencesBySubject[soId] ?? 0;
      final absencePercent = totalHours > 0 ? (absentHours / totalHours) * 100.0 : 0.0;
      
      // Determine level and message
      AbsenceLevel level = AbsenceLevel.normal;
      String? message;
      
      if (absencePercent >= eliminationPercent) {
        level = AbsenceLevel.eliminated;
        message = eliminationMessage;
      } else if (absencePercent >= criticalPercent) {
        level = AbsenceLevel.critical;
        message = criticalMessage;
      } else if (absencePercent >= warningPercent) {
        level = AbsenceLevel.warning;
        message = warningMessage;
      }
      
      summaries.add(SubjectAbsenceSummary(
        subjectOfferingId: soId,
        subjectName: subject?['name'] as String? ?? 'Matière inconnue',
        subjectCode: subject?['code'] as String?,
        totalHours: totalHours,
        weeklyCiHours: weeklyCi,
        weeklyTpHours: weeklyTp,
        weeks: weeks,
        totalAbsentHours: absentHours,
        absencePercent: absencePercent,
        level: level,
        warningMessage: message,
      ));
    }
    
    // Sort by absence percentage descending (most absences first)
    summaries.sort((a, b) => b.absencePercent.compareTo(a.absencePercent));
    
    return summaries;
  } catch (e) {
    debugPrint('absencesProvider error: $e');
    return [];
  }
});

class AbsencesScreen extends ConsumerStatefulWidget {
  const AbsencesScreen({super.key});

  @override
  ConsumerState<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends ConsumerState<AbsencesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _searchAnimationController;
  bool _isSearching = false;
  String _searchQuery = '';

  static const Color _accentColor = Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 150), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedTrimester = ref.watch(absencesTrimesterProvider);
    final absencesAsync = ref.watch(absencesProvider(selectedTrimester));

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8D5F2),
              Color(0xFFD4C4E8),
              Color(0xFFC9D6F0),
              Color(0xFFE0EAF5),
              Color(0xFFF0F5FA),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(absencesProvider(selectedTrimester));
              await ref.read(absencesProvider(selectedTrimester).future);
            },
            color: _accentColor,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // Header with animated search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: _buildAnimatedHeader(l10n),
                  ),
                ),

                // Dynamic Semester Navigator (fetches from DB)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DynamicSemesterNav(
                      selectedSemesterNumber: selectedTrimester,
                      onChanged: (v) => ref.read(absencesTrimesterProvider.notifier).state = v,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Content
                absencesAsync.when(
                  data: (absences) => _buildContent(context, absences, l10n),
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    ),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Erreur: $error'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _searchAnimationController,
      builder: (context, child) {
        final slideValue = _searchAnimationController.value;
        final fadeOut = 1.0 - slideValue;
        final fadeIn = slideValue;

        return SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Normal header
              Transform.translate(
                offset: Offset(-80 * slideValue, 0),
                child: Opacity(
                  opacity: fadeOut.clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC4899).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.event_busy_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.absences,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Suivi de présence',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleSearch,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: Colors.grey[700],
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Search bar
              Transform.translate(
                offset: Offset(MediaQuery.of(context).size.width * (1 - slideValue), 0),
                child: Opacity(
                  opacity: fadeIn.clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleSearch,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(Icons.close_rounded, color: Colors.grey[700], size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                  cursorColor: Colors.grey[600],
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher une matière...',
                                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, List<SubjectAbsenceSummary> absences, AppLocalizations l10n) {
    if (absences.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
              const SizedBox(height: 16),
              Text(
                'Aucune absence',
                style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    // Filter by search
    var filteredAbsences = absences;
    if (_searchQuery.isNotEmpty) {
      filteredAbsences = absences.where((a) =>
        a.subjectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (a.subjectCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    // Calculate summary stats
    final totalHours = absences.fold<double>(0, (sum, a) => sum + a.totalHours);
    final totalAbsent = absences.fold<double>(0, (sum, a) => sum + a.totalAbsentHours);
    final overallPercent = totalHours > 0 ? (totalAbsent / totalHours) * 100 : 0.0;
    final criticalCount = absences.where((a) => a.level == AbsenceLevel.critical || a.level == AbsenceLevel.eliminated).length;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Summary Card
          _buildSummaryCard(totalAbsent, totalHours, overallPercent, criticalCount),
          const SizedBox(height: 20),

          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.list_alt_rounded, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Détails par matière',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Absence Cards
          ...filteredAbsences.map((absence) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GlassyAbsenceCard(absence: absence),
          )),
        ]),
      ),
    );
  }

  Widget _buildSummaryCard(double totalAbsent, double totalHours, double overallPercent, int criticalCount) {
    final isGood = overallPercent < 15;
    final gradientColors = isGood
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [const Color(0xFFEC4899), const Color(0xFFF43F5E)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taux d\'absence global',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          overallPercent.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, height: 1),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6, left: 4),
                          child: Text('%', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${totalAbsent.toStringAsFixed(0)}h / ${totalHours.toStringAsFixed(0)}h',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isGood ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  if (criticalCount > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$criticalCount critique${criticalCount > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// iOS 26 Style Trimester Navigator
class _iOS26TrimesterNav extends StatefulWidget {
  final int selectedTrimester;
  final ValueChanged<int> onChanged;
  final Color accentColor;

  const _iOS26TrimesterNav({
    required this.selectedTrimester,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<_iOS26TrimesterNav> createState() => _iOS26TrimesterNavState();
}

class _iOS26TrimesterNavState extends State<_iOS26TrimesterNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedTrimester - 1;
    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_iOS26TrimesterNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTrimester != widget.selectedTrimester) {
      _previousIndex = oldWidget.selectedTrimester - 1;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 2; // 2 semesters
              final currentIndex = widget.selectedTrimester - 1;

              return Stack(
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final startPos = _previousIndex * tabWidth;
                      final endPos = currentIndex * tabWidth;
                      final currentPos = startPos + (endPos - startPos) * _animation.value;

                      return Positioned(
                        left: currentPos,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [widget.accentColor, widget.accentColor.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: widget.accentColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // 2 semesters only (Tunisian system)
                  Row(
                    children: [
                      _TrimesterTab(label: 'Semestre 1', isSelected: widget.selectedTrimester == 1, onTap: () => widget.onChanged(1)),
                      _TrimesterTab(label: 'Semestre 2', isSelected: widget.selectedTrimester == 2, onTap: () => widget.onChanged(2)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrimesterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrimesterTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// Glassy Absence Card
class _GlassyAbsenceCard extends StatelessWidget {
  final SubjectAbsenceSummary absence;

  const _GlassyAbsenceCard({required this.absence});

  @override
  Widget build(BuildContext context) {
    Color levelColor;
    IconData levelIcon;
    
    switch (absence.level) {
      case AbsenceLevel.normal:
        levelColor = const Color(0xFF10B981);
        levelIcon = Icons.check_circle_rounded;
        break;
      case AbsenceLevel.warning:
        levelColor = const Color(0xFFF59E0B);
        levelIcon = Icons.warning_rounded;
        break;
      case AbsenceLevel.critical:
        levelColor = const Color(0xFFF97316);
        levelIcon = Icons.error_rounded;
        break;
      case AbsenceLevel.eliminated:
        levelColor = const Color(0xFFEF4444);
        levelIcon = Icons.cancel_rounded;
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              // Percentage indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: (absence.absencePercent / 100).clamp(0.0, 1.0),
                        strokeWidth: 4,
                        backgroundColor: levelColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(levelColor),
                      ),
                    ),
                    Text(
                      '${absence.absencePercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Subject info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      absence.subjectName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (absence.subjectCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              absence.subjectCode!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          '${absence.totalAbsentHours.toStringAsFixed(0)}h / ${absence.totalHours.toStringAsFixed(0)}h',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    if (absence.warningMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(levelIcon, size: 12, color: levelColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                absence.warningMessage!,
                                style: TextStyle(fontSize: 10, color: levelColor, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status icon
              Icon(levelIcon, color: levelColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
