import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/student_result_model.dart';
import '../../../data/models/grading_config_model.dart';

class GradeEntryDialog extends StatefulWidget {
  final StudentResult student;
  final GradingConfiguration? gradingConfig;
  final Future<void> Function(List<GradeEntry> grades) onSave;

  const GradeEntryDialog({
    super.key,
    required this.student,
    required this.gradingConfig,
    required this.onSave,
  });

  @override
  State<GradeEntryDialog> createState() => _GradeEntryDialogState();
}

class _GradeEntryDialogState extends State<GradeEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedSemesterId;
  final Map<String, Map<GradeComponentType, TextEditingController>>
  _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Default to first semester
    _selectedSemesterId = widget.student.semesters.isNotEmpty
        ? widget.student.semesters.first.semesterId
        : '';

    // Initialize controllers for all subjects and components
    for (final semester in widget.student.semesters) {
      for (final subject in semester.subjects) {
        final key = '${semester.semesterId}_${subject.subjectId}';
        _controllers[key] = {};

        for (final component in GradeComponentType.values) {
          final grade = subject.getGrade(component);
          _controllers[key]![component] = TextEditingController(
            text: grade?.value?.toString() ?? '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (final subjectMap in _controllers.values) {
      for (final controller in subjectMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentSemester = widget.student.semesters.firstWhere(
      (s) => s.semesterId == _selectedSemesterId,
      orElse: () => widget.student.semesters.first,
    );

    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.student.photoUrl != null
                        ? NetworkImage(widget.student.photoUrl!)
                        : null,
                    child: widget.student.photoUrl == null
                        ? Text(
                            widget.student.studentName.isNotEmpty
                                ? widget.student.studentName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 18),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saisie des Notes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.student.studentName} - ${widget.student.className}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Semester selector
              Row(
                children: [
                  Text('Semestre:', style: theme.textTheme.labelLarge),
                  const SizedBox(width: 16),
                  SegmentedButton<String>(
                    segments: widget.student.semesters.map((semester) {
                      return ButtonSegment(
                        value: semester.semesterId,
                        label: Text(semester.semesterName),
                      );
                    }).toList(),
                    selected: {_selectedSemesterId},
                    onSelectionChanged: (values) {
                      setState(() => _selectedSemesterId = values.first);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Formula info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Formule: Moyenne = (Oral + DC + 2×DS) / 4  •  Notes sur 20',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Grades table
              Expanded(
                child: SingleChildScrollView(
                  child: _buildGradesTable(context, currentSemester),
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveGrades,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradesTable(BuildContext context, SemesterResult semester) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final enabledComponents =
        widget.gradingConfig?.defaultFormula.weights.keys.toList() ??
        [GradeComponentType.oral, GradeComponentType.dc, GradeComponentType.ds];

    return Table(
      border: TableBorder.all(
        color: colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: {
        0: const FlexColumnWidth(2.5),
        1: const FlexColumnWidth(0.8),
        for (int i = 0; i < enabledComponents.length; i++)
          i + 2: const FlexColumnWidth(1.2),
        enabledComponents.length + 2: const FlexColumnWidth(1.2),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
          children: [
            const _HeaderCell('Matière'),
            const _HeaderCell('Coef'),
            ...enabledComponents.map((c) => _HeaderCell(_getComponentLabel(c))),
            const _HeaderCell('Moyenne'),
          ],
        ),

        // Subject rows
        for (final subject in semester.subjects)
          TableRow(
            children: [
              // Subject name
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  subject.subjectName,
                  style: theme.textTheme.bodyMedium,
                ),
              ),

              // Coefficient
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  subject.coefficient.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Grade inputs for each component
              ...enabledComponents.map((component) {
                final key = '${semester.semesterId}_${subject.subjectId}';
                final controller = _controllers[key]?[component];

                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: _GradeInput(
                    controller: controller ?? TextEditingController(),
                    onChanged: (_) => setState(() {}),
                  ),
                );
              }),

              // Calculated average
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildCalculatedAverage(
                  context,
                  semester.semesterId,
                  subject.subjectId,
                  enabledComponents,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCalculatedAverage(
    BuildContext context,
    String semesterId,
    String subjectId,
    List<GradeComponentType> components,
  ) {
    final key = '${semesterId}_$subjectId';
    final controllers = _controllers[key];

    if (controllers == null) {
      return const Text('--');
    }

    // Calculate average based on formula
    double? oral, dc, ds;

    for (final component in components) {
      final text = controllers[component]?.text;
      final value = double.tryParse(text ?? '');

      switch (component) {
        case GradeComponentType.oral:
          oral = value;
          break;
        case GradeComponentType.dc:
          dc = value;
          break;
        case GradeComponentType.ds:
          ds = value;
          break;
        default:
          break;
      }
    }

    // Calculate: (Oral + DC + 2×DS) / 4
    double? average;
    if (oral != null && dc != null && ds != null) {
      average = (oral + dc + 2 * ds) / 4;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: average != null
            ? _getGradeColor(average).withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        average?.toStringAsFixed(2) ?? '--',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: average != null ? _getGradeColor(average) : Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 16) return Colors.green.shade700;
    if (grade >= 14) return Colors.blue.shade700;
    if (grade >= 12) return Colors.orange.shade700;
    if (grade >= 10) return Colors.amber.shade800;
    return Colors.red.shade700;
  }

  String _getComponentLabel(GradeComponentType component) {
    switch (component) {
      case GradeComponentType.oral:
        return 'Oral';
      case GradeComponentType.dc:
        return 'DC';
      case GradeComponentType.ds:
        return 'DS';
      case GradeComponentType.tp:
        return 'TP';
      case GradeComponentType.project:
        return 'Projet';
      case GradeComponentType.practical:
        return 'Pratique';
    }
  }

  Future<void> _saveGrades() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final grades = <GradeEntry>[];

      for (final semester in widget.student.semesters) {
        for (final subject in semester.subjects) {
          final key = '${semester.semesterId}_${subject.subjectId}';
          final controllers = _controllers[key];

          if (controllers == null) continue;

          for (final entry in controllers.entries) {
            final value = double.tryParse(entry.value.text);
            if (value != null) {
              final existingGrade = subject.getGrade(entry.key);
              grades.add(
                GradeEntry(
                  id: existingGrade?.id ?? '',
                  componentId: existingGrade?.componentId ?? '',
                  componentType: entry.key,
                  value: value,
                  subjectOfferingId: subject.subjectOfferingId,
                  status: 'graded',
                  gradedAt: DateTime.now(),
                ),
              );
            }
          }
        }
      }

      await widget.onSave(grades);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes enregistrées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _GradeInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _GradeInput({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        hintText: '--',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final grade = double.tryParse(value);
        if (grade == null) return 'Invalide';
        if (grade < 0 || grade > 20) return '0-20';
        return null;
      },
      onChanged: onChanged,
    );
  }
}
