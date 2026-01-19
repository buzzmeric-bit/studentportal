import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/grade_model.dart';
import '../../providers/student_context_provider.dart';
import '../../widgets/semester_navigator.dart';

// Import providers from the original file
import 'resultats_screen.dart' show gradesProvider, resultatsSemesterProvider;

/// Premium Redesigned Results Screen - iOS 26 Style with Navbar
class ResultatsScreenV2 extends ConsumerStatefulWidget {
  const ResultatsScreenV2({super.key});

  @override
  ConsumerState<ResultatsScreenV2> createState() => _ResultatsScreenV2State();
}

class _ResultatsScreenV2State extends ConsumerState<ResultatsScreenV2>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late AnimationController _searchAnimationController;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
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
    final selectedSemester = ref.watch(resultatsSemesterProvider);
    final gradesAsync = ref.watch(gradesProvider(selectedSemester));

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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
                    selectedSemesterNumber: selectedSemester,
                    onChanged: (v) => ref.read(resultatsSemesterProvider.notifier).state = v,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Content
              gradesAsync.when(
                data: (grades) => _buildContent(context, grades, selectedSemester, l10n),
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
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
              // Normal header - slides out and fades
              Transform.translate(
                offset: Offset(-80 * slideValue, 0),
                child: Opacity(
                  opacity: fadeOut.clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 1.0 - (0.3 * slideValue),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.resultats,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Suivi de vos notes',
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
              // Search bar - slides in from right
              Transform.translate(
                offset: Offset(
                  MediaQuery.of(context).size.width * (1 - slideValue),
                  0,
                ),
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
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.grey[700],
                            size: 22,
                          ),
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
                              Icon(
                                Icons.search_rounded,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  cursorColor: Colors.grey[600],
                                  onChanged: (value) =>
                                      setState(() => _searchQuery = value),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher une matière...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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

  Widget _buildContent(BuildContext context, List<SubjectGradesSummary> grades, int semester, AppLocalizations l10n) {
    if (grades.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(context),
      );
    }

    // Filter grades based on search
    var filteredGrades = grades;
    if (_searchQuery.isNotEmpty) {
      filteredGrades = grades.where((g) => 
        g.subjectName.toLowerCase().contains(_searchQuery) ||
        (g.subjectCode?.toLowerCase().contains(_searchQuery) ?? false)
      ).toList();
    }

    // Check if ALL subjects have complete results
    final allCompleted = grades.every((g) => g.average != null);
    
    // Calculate average ONLY if all subjects are completed
    double? semesterAverage;
    if (allCompleted) {
      double totalWeighted = 0;
      double totalCoeff = 0;
      for (final g in grades) {
        if (g.average != null) {
          totalWeighted += g.average! * g.coefficient;
          totalCoeff += g.coefficient;
        }
      }
      semesterAverage = totalCoeff > 0 ? totalWeighted / totalCoeff : null;
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Semester Average Card (only if all completed)
          if (allCompleted && semesterAverage != null) ...[
            _GlassySemesterCard(
              average: semesterAverage,
              semester: semester,
              isValidated: semesterAverage >= 10,
            ),
            const SizedBox(height: 20),
          ] else ...[
            _buildPendingResultsCard(context, grades),
            const SizedBox(height: 20),
          ],

          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF06B6D4), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Détails par matière',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Subject Cards
          if (filteredGrades.isNotEmpty)
            ...filteredGrades.map((subject) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GlassySubjectCard(subject: subject),
            ))
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Aucun résultat',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: Colors.black.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune matière assignée',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les notes seront affichées ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Pending results card - CYAN theme instead of orange, NO BORDER
  Widget _buildPendingResultsCard(BuildContext context, List<SubjectGradesSummary> grades) {
    final completedCount = grades.where((g) => g.average != null).length;
    final totalCount = grades.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF06B6D4).withOpacity(0.2),
                const Color(0xFF3B82F6).withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            // NO BORDER - removed
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pending_actions_rounded, color: Color(0xFF0891B2), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultats en cours',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF155E75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedCount / $totalCount matières notées',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0E7490),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFF06B6D4).withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF06B6D4)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS 26 Style Trimester Navigator with smooth glass pill animation
class _iOS26TrimesterNav extends StatefulWidget {
  final int selectedTrimester;
  final ValueChanged<int> onChanged;

  const _iOS26TrimesterNav({
    required this.selectedTrimester,
    required this.onChanged,
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
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
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 2; // 2 semesters
              final currentIndex = widget.selectedTrimester - 1;

              return Stack(
                children: [
                  // Animated glass pill indicator
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
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Tab labels - 2 semesters only (Tunisian system)
                  Row(
                    children: [
                      _TrimesterTab(
                        label: 'Semestre 1',
                        isSelected: widget.selectedTrimester == 1,
                        onTap: () => widget.onChanged(1),
                      ),
                      _TrimesterTab(
                        label: 'Semestre 2',
                        isSelected: widget.selectedTrimester == 2,
                        onTap: () => widget.onChanged(2),
                      ),
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

  const _TrimesterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
              letterSpacing: -0.2,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// Glassy Semester Average Card - NO BORDER
class _GlassySemesterCard extends StatelessWidget {
  final double average;
  final int semester;
  final bool isValidated;

  const _GlassySemesterCard({
    required this.average,
    required this.semester,
    required this.isValidated,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = isValidated
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [const Color(0xFFEF4444), const Color(0xFFDC2626)];

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
            // NO BORDER
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moyenne Trimestre $semester',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            average.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 4),
                            child: Text(
                              '/20',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isValidated ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isValidated ? Icons.verified_rounded : Icons.cancel_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isValidated ? 'Trimestre validé' : 'Trimestre non validé',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Glassy Subject Card - NO BORDER
class _GlassySubjectCard extends StatefulWidget {
  final SubjectGradesSummary subject;

  const _GlassySubjectCard({required this.subject});

  @override
  State<_GlassySubjectCard> createState() => _GlassySubjectCardState();
}

class _GlassySubjectCardState extends State<_GlassySubjectCard> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAverage = widget.subject.average != null;
    final grade = widget.subject.average ?? 0;
    final gradeColor = !hasAverage
        ? Colors.grey.shade400
        : grade >= 10
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            // NO BORDER - removed
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                  if (_isExpanded) {
                    _controller.forward();
                  } else {
                    _controller.reverse();
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Grade indicator
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: gradeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: hasAverage
                              ? Text(
                                  grade.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: gradeColor,
                                    fontSize: 16,
                                  ),
                                )
                              : Icon(Icons.pending_outlined, color: gradeColor, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Subject info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subject.subjectName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (widget.subject.subjectCode != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.subject.subjectCode!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06B6D4).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Coef. ${widget.subject.coefficient.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0891B2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Expand button
                      RotationTransition(
                        turns: _rotationAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded content with smooth animation
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildExpandedContent(gradeColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Color gradeColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          // Weights
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.pie_chart_rounded, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.subject.weightsDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Components
          ...widget.subject.components.map((component) {
            final isGraded = component.status == 'OK' && component.grade != null;
            final compGrade = component.grade ?? 0;
            final compColor = !isGraded
                ? Colors.grey.shade400
                : compGrade >= 10
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  // Grade pill
                  Container(
                    width: 48,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: compColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        component.displayGrade,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: compColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Component name and weight
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          component.componentName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Poids: ${component.weightPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress bar or waiting badge
                  if (isGraded)
                    SizedBox(
                      width: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: compGrade / 20,
                          backgroundColor: compColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(compColor),
                          minHeight: 6,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'À venir',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
