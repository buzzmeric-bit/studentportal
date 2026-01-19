import 'package:flutter/material.dart';
import '../../../data/models/student_result_model.dart';

class StudentResultsTable extends StatelessWidget {
  final List<StudentResult> students;
  final ClassResult classResult;
  final Function(StudentResult) onStudentTap;
  final Function(StudentResult) onEditGrades;

  const StudentResultsTable({
    super.key,
    required this.students,
    required this.classResult,
    required this.onStudentTap,
    required this.onEditGrades,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 60), // Avatar space
                const Expanded(flex: 3, child: _HeaderCell('Élève')),
                const Expanded(flex: 2, child: _HeaderCell('Code')),
                const Expanded(flex: 2, child: _HeaderCell('Trim. 1')),
                const Expanded(flex: 2, child: _HeaderCell('Trim. 2')),
                const Expanded(flex: 2, child: _HeaderCell('Trim. 3')),
                const Expanded(flex: 2, child: _HeaderCell('Moyenne')),
                const Expanded(flex: 2, child: _HeaderCell('Rang')),
                const Expanded(flex: 2, child: _HeaderCell('Status')),
                const SizedBox(width: 100), // Actions space
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: colorScheme.outlineVariant),

          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
              itemBuilder: (context, index) {
                final student = students[index];
                return _StudentRow(
                  student: student,
                  isEven: index % 2 == 0,
                  onTap: () => onStudentTap(student),
                  onEdit: () => onEditGrades(student),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }
}

class _StudentRow extends StatelessWidget {
  final StudentResult student;
  final bool isEven;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _StudentRow({
    required this.student,
    required this.isEven,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isEven ? null : colorScheme.surfaceContainerLow.withOpacity(0.3),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundImage: student.photoUrl != null
                  ? NetworkImage(student.photoUrl!)
                  : null,
              backgroundColor: colorScheme.primaryContainer,
              child: student.photoUrl == null
                  ? Text(
                      student.studentName.isNotEmpty
                          ? student.studentName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Name
            Expanded(
              flex: 3,
              child: Text(
                student.studentName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Code
            Expanded(
              flex: 2,
              child: Text(
                student.studentCode,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Semester 1
            Expanded(
              flex: 2,
              child: _GradeBadge(value: student.semester1Average, small: true),
            ),

            // Semester 2
            Expanded(
              flex: 2,
              child: _GradeBadge(value: student.semester2Average, small: true),
            ),

            // Semester 3
            Expanded(
              flex: 2,
              child: _GradeBadge(value: student.semester3Average, small: true),
            ),

            // Annual Average
            Expanded(flex: 2, child: _GradeBadge(value: student.annualAverage)),

            // Rank
            Expanded(
              flex: 2,
              child: _RankBadge(
                rank: student.rank,
                total: student.totalStudents,
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: _StatusChip(status: student.performanceStatus),
            ),

            // Actions
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Modifier les notes',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    onPressed: onTap,
                    tooltip: 'Voir les détails',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  final double? value;
  final bool small;

  const _GradeBadge({this.value, this.small = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (value == null) {
      return Center(
        child: Text(
          '--',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    Color bgColor;
    Color textColor;

    if (value! >= 16) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (value! >= 14) {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
    } else if (value! >= 12) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else if (value! >= 10) {
      bgColor = Colors.amber.shade50;
      textColor = Colors.amber.shade800;
    } else {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    }

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12,
          vertical: small ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value!.toStringAsFixed(2),
          style:
              (small ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                  ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final int total;

  const _RankBadge({required this.rank, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData? icon;
    Color? iconColor;

    if (rank == 1) {
      icon = Icons.emoji_events;
      iconColor = Colors.amber;
    } else if (rank == 2) {
      icon = Icons.emoji_events;
      iconColor = Colors.grey.shade400;
    } else if (rank == 3) {
      icon = Icons.emoji_events;
      iconColor = Colors.brown.shade300;
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            '$rank${_getRankSuffix(rank)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: rank <= 3 ? FontWeight.bold : null,
            ),
          ),
          Text(
            '/$total',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getRankSuffix(int rank) {
    if (rank == 1) return 'er';
    return 'ème';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Excellent':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 'Très Bien':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      case 'Bien':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      case 'Passable':
        bgColor = Colors.amber.shade100;
        textColor = Colors.amber.shade800;
        break;
      case 'Insuffisant':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
