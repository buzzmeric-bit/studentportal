import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/absence_model.dart';

// Selected semester provider
final absencesSemesterProvider = StateProvider<int>((ref) => 1);

// Demo absences provider
final absencesProvider = FutureProvider.family<List<SubjectAbsenceSummary>, int>((ref, semesterId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Demo data for semester 1
  if (semesterId == 1) {
    return [
      SubjectAbsenceSummary(
        subjectOfferingId: 's1',
        subjectName: 'Marketing',
        subjectCode: 'MKT101',
        totalHours: 48,
        weeklyCiHours: 2.0,
        weeklyTpHours: 2.0,
        weeks: 12,
        totalAbsentHours: 4,
        absencePercent: 8.33,
        level: AbsenceLevel.normal,
      ),
      SubjectAbsenceSummary(
        subjectOfferingId: 's2',
        subjectName: 'Comptabilité Générale',
        subjectCode: 'CPT101',
        totalHours: 60,
        weeklyCiHours: 3.0,
        weeklyTpHours: 2.0,
        weeks: 12,
        totalAbsentHours: 10,
        absencePercent: 16.67,
        level: AbsenceLevel.warning,
        warningMessage: 'Attention: Vous approchez du seuil critique',
      ),
      SubjectAbsenceSummary(
        subjectOfferingId: 's3',
        subjectName: 'Droit des Affaires',
        subjectCode: 'DRT101',
        totalHours: 36,
        weeklyCiHours: 3.0,
        weeklyTpHours: 0.0,
        weeks: 12,
        totalAbsentHours: 0,
        absencePercent: 0.0,
        level: AbsenceLevel.normal,
      ),
      SubjectAbsenceSummary(
        subjectOfferingId: 's4',
        subjectName: 'Informatique de Gestion',
        subjectCode: 'INF101',
        totalHours: 48,
        weeklyCiHours: 2.0,
        weeklyTpHours: 2.0,
        weeks: 12,
        totalAbsentHours: 16,
        absencePercent: 33.33,
        level: AbsenceLevel.eliminated,
        warningMessage: 'Vous avez dépassé le seuil d\'élimination',
      ),
      SubjectAbsenceSummary(
        subjectOfferingId: 's5',
        subjectName: 'Anglais Commercial',
        subjectCode: 'ANG101',
        totalHours: 36,
        weeklyCiHours: 3.0,
        weeklyTpHours: 0.0,
        weeks: 12,
        totalAbsentHours: 9,
        absencePercent: 25.0,
        level: AbsenceLevel.critical,
        warningMessage: 'Vous êtes au seuil critique!',
      ),
    ];
  }
  
  // Demo data for semester 2
  return [
    SubjectAbsenceSummary(
      subjectOfferingId: 's6',
      subjectName: 'Finance d\'Entreprise',
      subjectCode: 'FIN201',
      totalHours: 48,
      weeklyCiHours: 2.5,
      weeklyTpHours: 1.5,
      weeks: 12,
      totalAbsentHours: 2,
      absencePercent: 4.17,
      level: AbsenceLevel.normal,
    ),
  ];
});

class AbsencesScreen extends ConsumerWidget {
  const AbsencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedSemester = ref.watch(absencesSemesterProvider);
    final absencesAsync = ref.watch(absencesProvider(selectedSemester));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.absences),
        backgroundColor: AppColors.tileAbsences,
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
                    onTap: () => ref.read(absencesSemesterProvider.notifier).state = 1,
                  ),
                ),
                Expanded(
                  child: _SemesterTab(
                    label: '${l10n.semester} 2',
                    isSelected: selectedSemester == 2,
                    onTap: () => ref.read(absencesSemesterProvider.notifier).state = 2,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: absencesAsync.when(
              data: (absences) {
                if (absences.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: AppColors.success,
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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                  itemCount: absences.length,
                  itemBuilder: (context, index) {
                    final absence = absences[index];
                    return _AbsenceCard(absence: absence);
                  },
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
                      onPressed: () => ref.refresh(absencesProvider(selectedSemester)),
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
          color: isSelected ? AppColors.tileAbsences : Colors.transparent,
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

class _AbsenceCard extends StatelessWidget {
  final SubjectAbsenceSummary absence;

  const _AbsenceCard({required this.absence});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Determine color based on level
    Color levelColor;
    IconData levelIcon;
    
    switch (absence.level) {
      case AbsenceLevel.normal:
        levelColor = AppColors.success;
        levelIcon = Icons.check_circle;
        break;
      case AbsenceLevel.warning:
        levelColor = AppColors.warning;
        levelIcon = Icons.warning;
        break;
      case AbsenceLevel.critical:
        levelColor = Colors.orange;
        levelIcon = Icons.error;
        break;
      case AbsenceLevel.eliminated:
        levelColor = AppColors.error;
        levelIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        side: absence.level != AbsenceLevel.normal 
            ? BorderSide(color: levelColor.withOpacity(0.5), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absence.subjectName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (absence.subjectCode != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          absence.subjectCode!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textLight,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Circular progress indicator
                CircularPercentIndicator(
                  radius: 35,
                  lineWidth: 6,
                  percent: (absence.absencePercent / 100).clamp(0.0, 1.0),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${absence.absencePercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                    ],
                  ),
                  progressColor: levelColor,
                  backgroundColor: AppColors.border,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingM),
            // Divider
            const Divider(height: 1),
            const SizedBox(height: AppSizes.paddingM),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: l10n.totalHours,
                    value: '${absence.totalHours.toStringAsFixed(0)}h',
                    icon: Icons.access_time,
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'CI',
                    value: '${(absence.weeklyCiHours * absence.weeks).toStringAsFixed(0)}h',
                    icon: Icons.school,
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'TP',
                    value: '${(absence.weeklyTpHours * absence.weeks).toStringAsFixed(0)}h',
                    icon: Icons.computer,
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: l10n.absenceHours,
                    value: '${absence.totalAbsentHours.toStringAsFixed(0)}h',
                    icon: Icons.event_busy,
                    valueColor: levelColor,
                  ),
                ),
              ],
            ),
            // Warning message if any
            if (absence.warningMessage != null) ...[
              const SizedBox(height: AppSizes.paddingM),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  border: Border.all(color: levelColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(levelIcon, size: 18, color: levelColor),
                    const SizedBox(width: AppSizes.paddingS),
                    Expanded(
                      child: Text(
                        absence.warningMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: levelColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textLight,
              ),
        ),
      ],
    );
  }
}
