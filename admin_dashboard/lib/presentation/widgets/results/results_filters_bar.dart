import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/results_provider.dart';

class ResultsFiltersBar extends StatelessWidget {
  const ResultsFiltersBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ResultsProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              // Academic Year Filter
              Expanded(
                child: _FilterDropdown<String>(
                  label: 'Année Scolaire',
                  icon: Icons.calendar_today_outlined,
                  value: provider.selectedAcademicYearId,
                  items: provider.academicYears.map((year) {
                    return DropdownMenuItem(
                      value: year['id'] as String,
                      child: Text(year['name'] as String),
                    );
                  }).toList(),
                  onChanged: provider.setAcademicYear,
                ),
              ),

              const SizedBox(width: 16),

              // Semester Filter
              Expanded(
                child: _FilterDropdown<String>(
                  label: 'Semestre',
                  icon: Icons.date_range_outlined,
                  value: provider.selectedSemesterId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tous les semestres'),
                    ),
                    ...provider.semesters.map((semester) {
                      return DropdownMenuItem(
                        value: semester['id'] as String,
                        child: Text(semester['name'] as String),
                      );
                    }),
                  ],
                  onChanged: provider.setSemester,
                ),
              ),

              const SizedBox(width: 16),

              // Class Filter
              Expanded(
                child: _FilterDropdown<String>(
                  label: 'Classe',
                  icon: Icons.class_outlined,
                  value: provider.selectedClassId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sélectionner une classe'),
                    ),
                    ...provider.classes.map((cls) {
                      return DropdownMenuItem(
                        value: cls['id'] as String,
                        child: Text(cls['name'] as String),
                      );
                    }),
                  ],
                  onChanged: provider.setClass,
                ),
              ),

              const SizedBox(width: 16),

              // Group Filter
              Expanded(
                child: _FilterDropdown<String>(
                  label: 'Groupe',
                  icon: Icons.group_outlined,
                  value: provider.selectedGroupId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tous les groupes'),
                    ),
                    ...provider.groups.map((group) {
                      return DropdownMenuItem(
                        value: group['id'] as String,
                        child: Text(group['name'] as String),
                      );
                    }),
                  ],
                  onChanged: provider.setGroup,
                  enabled: provider.selectedClassId != null,
                ),
              ),

              const SizedBox(width: 24),

              // Bulk Actions
              _BulkActionsMenu(provider: provider),

              const SizedBox(width: 16),

              // Calculate Button
              FilledButton.icon(
                onPressed:
                    provider.selectedClassId == null || provider.isLoading
                    ? null
                    : () => provider.calculateResults(),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calculate),
                label: const Text('Calculer'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: enabled
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T?>(
              value: value,
              items: items,
              onChanged: enabled ? onChanged : null,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(8),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BulkActionsMenu extends StatelessWidget {
  final ResultsProvider provider;

  const _BulkActionsMenu({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopupMenuButton<ResultsFilterType>(
      tooltip: 'Calculs groupés',
      onSelected: (type) {
        provider.setFilterType(type);
        provider.calculateResults();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ResultsFilterType.byStudent,
          child: const ListTile(
            leading: Icon(Icons.person),
            title: Text('Par élève'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: ResultsFilterType.byClass,
          child: const ListTile(
            leading: Icon(Icons.class_),
            title: Text('Par classe'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: ResultsFilterType.byGradeLevel,
          child: const ListTile(
            leading: Icon(Icons.school),
            title: Text('Par niveau'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: ResultsFilterType.bySchool,
          child: const ListTile(
            leading: Icon(Icons.business),
            title: Text('Par école'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Calcul groupé',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: colorScheme.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
