import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/grade_model.dart';
import '../../../data/repositories/results_repository.dart';
import '../../../data/services/core_data_service.dart';
import '../../providers/student_context_provider.dart' as ctx;

// Results repository provider
final resultsRepositoryProvider = Provider<StudentResultsRepository>((ref) {
  return StudentResultsRepository(Supabase.instance.client);
});

// Current enrollment provider
final currentEnrollmentProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.getCurrentEnrollment();
});

// Re-export the shared semesters provider for backward compatibility
// This now uses the dynamic provider from student_context_provider
final semestersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final semesters = await ref.watch(ctx.semestersProvider.future);
  // Convert SemesterInfo to Map<String, dynamic> for backward compatibility
  return semesters.map<Map<String, dynamic>>((s) => <String, dynamic>{
    'id': s.id,
    'name': s.name,
    'number': s.number,
    'is_current': s.isCurrent,
  }).toList();
});

// Selected semester provider
final resultatsSemesterProvider = StateProvider<int>((ref) => 1);

// Grades provider - fetches real data
final gradesProvider = FutureProvider.family<List<SubjectGradesSummary>, int>((ref, semesterNumber) async {
  final enrollment = await ref.watch(currentEnrollmentProvider.future);
  final semesters = await ref.watch(semestersProvider.future);
  
  if (enrollment == null || semesters.isEmpty) {
    // Return demo data if no enrollment found
    return _getDemoGrades(semesterNumber);
  }
  
  // Find the semester by number
  final semester = semesters.firstWhere(
    (s) => s['number'] == semesterNumber,
    orElse: () => <String, dynamic>{},
  );
  
  if (semester.isEmpty || semester['id'] == null) {
    return _getDemoGrades(semesterNumber);
  }
  
  final repo = ref.watch(resultsRepositoryProvider);
  final grades = await repo.getStudentGrades(
    enrollmentId: enrollment['id'],
    semesterId: semester['id'],
  );
  
  // If no grades found, return demo data
  if (grades.isEmpty) {
    return _getDemoGrades(semesterNumber);
  }
  
  return grades;
});

// Demo grades for testing
List<SubjectGradesSummary> _getDemoGrades(int semesterId) {
  if (semesterId == 1) {
    return [
      SubjectGradesSummary(
        subjectOfferingId: 's1',
        subjectName: 'Mathématiques',
        subjectCode: 'MATH',
        coefficient: 4.0,
        weightsDisplay: 'DC: 25% | DS: 75%',
        components: [
          ComponentGrade(
            componentId: 'c1',
            componentName: 'Devoir de Contrôle 1',
            weightPercent: 12.5,
            grade: 14.5,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c1b',
            componentName: 'Devoir de Contrôle 2',
            weightPercent: 12.5,
            grade: 15.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c2',
            componentName: 'Devoir de Synthèse',
            weightPercent: 75,
            grade: 12.0,
            status: 'OK',
          ),
        ],
        average: 12.69,
      ),
      SubjectGradesSummary(
        subjectOfferingId: 's2',
        subjectName: 'Physique',
        subjectCode: 'PHYS',
        coefficient: 4.0,
        weightsDisplay: 'DC: 25% | TP: 25% | DS: 50%',
        components: [
          ComponentGrade(
            componentId: 'c3',
            componentName: 'Devoir de Contrôle',
            weightPercent: 25,
            grade: 15.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c4',
            componentName: 'Travaux Pratiques',
            weightPercent: 25,
            grade: 16.5,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c5',
            componentName: 'Devoir de Synthèse',
            weightPercent: 50,
            grade: 11.0,
            status: 'OK',
          ),
        ],
        average: 13.38,
      ),
      SubjectGradesSummary(
        subjectOfferingId: 's3',
        subjectName: 'Sciences de la Vie et de la Terre',
        subjectCode: 'SVT',
        coefficient: 2.0,
        weightsDisplay: 'DC: 25% | DS: 75%',
        components: [
          ComponentGrade(
            componentId: 'c6',
            componentName: 'Devoir de Contrôle',
            weightPercent: 25,
            grade: 13.5,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c7',
            componentName: 'Devoir de Synthèse',
            weightPercent: 75,
            grade: 14.0,
            status: 'OK',
          ),
        ],
        average: 13.88,
      ),
      SubjectGradesSummary(
        subjectOfferingId: 's4',
        subjectName: 'Informatique',
        subjectCode: 'INFO',
        coefficient: 2.0,
        weightsDisplay: 'DC: 25% | TP: 25% | DS: 50%',
        components: [
          ComponentGrade(
            componentId: 'c8',
            componentName: 'Devoir de Contrôle',
            weightPercent: 25,
            grade: 17.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c9',
            componentName: 'Travaux Pratiques',
            weightPercent: 25,
            grade: 18.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c10',
            componentName: 'Devoir de Synthèse',
            weightPercent: 50,
            grade: 15.5,
            status: 'OK',
          ),
        ],
        average: 16.5,
      ),
      SubjectGradesSummary(
        subjectOfferingId: 's5',
        subjectName: 'Langue Arabe',
        subjectCode: 'AR',
        coefficient: 2.0,
        weightsDisplay: 'DC: 25% | ORAL: 25% | DS: 50%',
        components: [
          ComponentGrade(
            componentId: 'c11',
            componentName: 'Devoir de Contrôle',
            weightPercent: 25,
            grade: 14.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c11b',
            componentName: 'Oral',
            weightPercent: 25,
            grade: 15.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c12',
            componentName: 'Devoir de Synthèse',
            weightPercent: 50,
            grade: 12.0,
            status: 'OK',
          ),
        ],
        average: 13.25,
      ),
      SubjectGradesSummary(
        subjectOfferingId: 's6',
        subjectName: 'Langue Française',
        subjectCode: 'FR',
        coefficient: 2.0,
        weightsDisplay: 'DC: 25% | ORAL: 25% | DS: 50%',
        components: [
          ComponentGrade(
            componentId: 'c13',
            componentName: 'Devoir de Contrôle',
            weightPercent: 25,
            grade: 11.5,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c13b',
            componentName: 'Oral',
            weightPercent: 25,
            grade: 13.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c14',
            componentName: 'Devoir de Synthèse',
            weightPercent: 50,
            grade: 10.5,
            status: 'OK',
          ),
        ],
        average: 11.38,
      ),
      SubjectGradesSummary(
        subjectOfferingId: 's7',
        subjectName: 'Langue Anglaise',
        subjectCode: 'EN',
        coefficient: 2.0,
        weightsDisplay: 'DC: 25% | ORAL: 25% | DS: 50%',
        components: [
          ComponentGrade(
            componentId: 'c15',
            componentName: 'Devoir de Contrôle',
            weightPercent: 25,
            grade: 16.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c15b',
            componentName: 'Oral',
            weightPercent: 25,
            grade: 17.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c16',
            componentName: 'Devoir de Synthèse',
            weightPercent: 50,
            grade: null,
            status: 'ND',
          ),
        ],
        average: null,
      ),
      SubjectGradesSummary(
        subjectOfferingId: 's8',
        subjectName: 'Philosophie',
        subjectCode: 'PHILO',
        coefficient: 1.0,
        weightsDisplay: 'DC: 33% | DS: 67%',
        components: [
          ComponentGrade(
            componentId: 'c17',
            componentName: 'Devoir de Contrôle',
            weightPercent: 33,
            grade: 12.0,
            status: 'OK',
          ),
          ComponentGrade(
            componentId: 'c18',
            componentName: 'Devoir de Synthèse',
            weightPercent: 67,
            grade: 11.0,
            status: 'OK',
          ),
        ],
        average: 11.33,
      ),
      SubjectGradesSummary(
        subjectOfferingId: 's9',
        subjectName: 'Éducation Physique',
        subjectCode: 'EPS',
        coefficient: 1.0,
        weightsDisplay: 'Évaluation: 100%',
        components: [
          ComponentGrade(
            componentId: 'c19',
            componentName: 'Évaluation Pratique',
            weightPercent: 100,
            grade: 15.0,
            status: 'OK',
          ),
        ],
        average: 15.0,
      ),
    ];
  }

  // Semester 2 - partial data
  return [
    SubjectGradesSummary(
      subjectOfferingId: 's21',
      subjectName: 'Mathématiques',
      subjectCode: 'MATH',
      coefficient: 4.0,
      weightsDisplay: 'DC: 25% | DS: 75%',
      components: [
        ComponentGrade(
          componentId: 'c21',
          componentName: 'Devoir de Contrôle 1',
          weightPercent: 12.5,
          grade: null,
          status: 'ND',
        ),
        ComponentGrade(
          componentId: 'c21b',
          componentName: 'Devoir de Contrôle 2',
          weightPercent: 12.5,
          grade: null,
          status: 'ND',
        ),
        ComponentGrade(
          componentId: 'c22',
          componentName: 'Devoir de Synthèse',
          weightPercent: 75,
          grade: null,
          status: 'ND',
        ),
      ],
      average: null,
    ),
    SubjectGradesSummary(
      subjectOfferingId: 's22',
      subjectName: 'Physique',
      subjectCode: 'PHYS',
      coefficient: 4.0,
      weightsDisplay: 'DC: 25% | TP: 25% | DS: 50%',
      components: [
        ComponentGrade(
          componentId: 'c23',
          componentName: 'Devoir de Contrôle',
          weightPercent: 25,
          grade: null,
          status: 'ND',
        ),
        ComponentGrade(
          componentId: 'c24',
          componentName: 'Travaux Pratiques',
          weightPercent: 25,
          grade: null,
          status: 'ND',
        ),
        ComponentGrade(
          componentId: 'c25',
          componentName: 'Devoir de Synthèse',
          weightPercent: 50,
          grade: null,
          status: 'ND',
        ),
      ],
      average: null,
    ),
  ];
}

class ResultatsScreen extends ConsumerWidget {
  const ResultatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedSemester = ref.watch(resultatsSemesterProvider);
    final gradesAsync = ref.watch(gradesProvider(selectedSemester));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.resultats),
        backgroundColor: AppColors.tileResultats,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Semester selector
          Container(
            margin: const EdgeInsets.all(AppSizes.paddingM),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SemesterTab(
                    label: '${l10n.semester} 1',
                    isSelected: selectedSemester == 1,
                    onTap: () => ref.read(resultatsSemesterProvider.notifier).state = 1,
                  ),
                ),
                Expanded(
                  child: _SemesterTab(
                    label: '${l10n.semester} 2',
                    isSelected: selectedSemester == 2,
                    onTap: () => ref.read(resultatsSemesterProvider.notifier).state = 2,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: gradesAsync.when(
              data: (grades) {
                if (grades.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assessment_outlined,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        Text(
                          l10n.noData,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate semester average
                double totalWeighted = 0;
                double totalCoeff = 0;
                for (final g in grades) {
                  if (g.average != null) {
                    totalWeighted += g.average! * g.coefficient;
                    totalCoeff += g.coefficient;
                  }
                }
                final semesterAverage = totalCoeff > 0 ? totalWeighted / totalCoeff : null;

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                  children: [
                    // Semester average card
                    if (semesterAverage != null) ...[
                      _SemesterAverageCard(
                        average: semesterAverage,
                        semester: selectedSemester,
                      ),
                      const SizedBox(height: AppSizes.paddingL),
                    ],
                    // Subject grades
                    ...grades.map((subject) => _SubjectGradeCard(subject: subject)),
                    const SizedBox(height: AppSizes.paddingM),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppSizes.paddingM),
                    Text(l10n.error),
                    TextButton(
                      onPressed: () => ref.refresh(gradesProvider(selectedSemester)),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemesterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SemesterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tileResultats : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusL - 4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SemesterAverageCard extends StatelessWidget {
  final double average;
  final int semester;

  const _SemesterAverageCard({
    required this.average,
    required this.semester,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPassing = average >= 10;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isPassing ? AppColors.success : AppColors.error,
              isPassing ? AppColors.success.withOpacity(0.8) : AppColors.error.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
        child: Column(
          children: [
            Text(
              '${l10n.semesterAverage} $semester',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSizes.paddingS),
            Text(
              average.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.paddingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
              child: Text(
                isPassing ? l10n.passed : l10n.failed,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectGradeCard extends StatefulWidget {
  final SubjectGradesSummary subject;

  const _SubjectGradeCard({required this.subject});

  @override
  State<_SubjectGradeCard> createState() => _SubjectGradeCardState();
}

class _SubjectGradeCardState extends State<_SubjectGradeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasAverage = widget.subject.average != null;
    final isPassing = hasAverage && widget.subject.average! >= 10;
    final averageColor = !hasAverage 
        ? AppColors.textLight 
        : (isPassing ? AppColors.success : AppColors.error);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  // Average circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: averageColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: averageColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        hasAverage 
                            ? widget.subject.average!.toStringAsFixed(1)
                            : 'ND',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: averageColor,
                          fontSize: hasAverage ? 16 : 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  // Subject info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject.subjectName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (widget.subject.subjectCode != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subject.subjectCode!,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.coefficient}: ${widget.subject.coefficient.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand icon
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weights display
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingS),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pie_chart, size: 16, color: AppColors.textLight),
                        const SizedBox(width: AppSizes.paddingS),
                        Text(
                          widget.subject.weightsDisplay,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  // Components table
                  ...widget.subject.components.map((component) {
                    final isGraded = component.status == 'OK' && component.grade != null;
                    final gradeColor = !isGraded 
                        ? AppColors.textLight
                        : (component.grade! >= 10 ? AppColors.success : AppColors.error);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              component.componentName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${component.weightPercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              component.displayGrade,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: gradeColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
