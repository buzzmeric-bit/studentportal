import 'package:flutter/material.dart';
import '../../../data/models/student_result_model.dart';

class ResultsStatsCards extends StatelessWidget {
  final ClassResult classResult;

  const ResultsStatsCards({super.key, required this.classResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Total Students
          Expanded(
            child: _StatCard(
              icon: Icons.people_outline,
              iconColor: colorScheme.primary,
              bgColor: colorScheme.primaryContainer.withOpacity(0.3),
              title: 'Effectif Total',
              value: classResult.totalStudents.toString(),
              subtitle: 'élèves',
            ),
          ),

          const SizedBox(width: 16),

          // Class Average
          Expanded(
            child: _StatCard(
              icon: Icons.analytics_outlined,
              iconColor: Colors.blue,
              bgColor: Colors.blue.withOpacity(0.1),
              title: 'Moyenne de Classe',
              value: classResult.classAverage?.toStringAsFixed(2) ?? '--',
              subtitle: '/ 20',
            ),
          ),

          const SizedBox(width: 16),

          // Success Rate
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              bgColor: Colors.green.withOpacity(0.1),
              title: 'Taux de Réussite',
              value: '${classResult.successRate.toStringAsFixed(1)}%',
              subtitle: '${classResult.passedCount} admis',
            ),
          ),

          const SizedBox(width: 16),

          // Failure Rate
          Expanded(
            child: _StatCard(
              icon: Icons.warning_amber_outlined,
              iconColor: Colors.red,
              bgColor: Colors.red.withOpacity(0.1),
              title: 'En Difficulté',
              value: classResult.failedCount.toString(),
              subtitle: 'élèves < 10',
            ),
          ),

          const SizedBox(width: 16),

          // Highest Average
          Expanded(
            child: _StatCard(
              icon: Icons.emoji_events_outlined,
              iconColor: Colors.amber.shade700,
              bgColor: Colors.amber.withOpacity(0.1),
              title: 'Meilleure Moyenne',
              value: classResult.highestAverage?.toStringAsFixed(2) ?? '--',
              subtitle: classResult.topStudent?.studentName ?? '',
            ),
          ),

          const SizedBox(width: 16),

          // Lowest Average
          Expanded(
            child: _StatCard(
              icon: Icons.trending_down_outlined,
              iconColor: Colors.orange,
              bgColor: Colors.orange.withOpacity(0.1),
              title: 'Plus Basse Moyenne',
              value: classResult.lowestAverage?.toStringAsFixed(2) ?? '--',
              subtitle: '/ 20',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
