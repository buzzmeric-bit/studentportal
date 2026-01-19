import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/results_provider.dart';

/// Dialog for entering grades in bulk for multiple students
class BulkGradeEntryDialog extends StatefulWidget {
  final Map<String, dynamic>? subjectOffering;
  final String? examType;

  const BulkGradeEntryDialog({
    super.key,
    this.subjectOffering,
    this.examType,
  });

  @override
  State<BulkGradeEntryDialog> createState() => _BulkGradeEntryDialogState();
}

class _BulkGradeEntryDialogState extends State<BulkGradeEntryDialog> {
  // Current selection
  String? _selectedSubjectId;
  String? _selectedExamType;
  
  // Grade entries by student ID
  final Map<String, TextEditingController> _gradeControllers = {};
  final Map<String, double?> _grades = {};
  
  // Students list for bulk entry
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  
  // Exam types
  final List<String> _examTypes = ['DC1', 'DC2', 'DS', 'TP', 'Oral'];

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.subjectOffering?['id'];
    _selectedExamType = widget.examType ?? 'DC1';
    _loadStudents();
  }

  @override
  void dispose() {
    for (final controller in _gradeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<ResultsProvider>();
      // Get students from class results
      final result = provider.classResult;
      if (result != null && result.students.isNotEmpty) {
        _students = result.students.map((sr) => {
          'id': sr.studentId,
          'name': sr.studentName,
          'photo_url': sr.photoUrl,
          'student_number': '', // TODO: Get from enrollment
        }).toList();
        
        // Initialize controllers
        for (final student in _students) {
          _gradeControllers[student['id']] = TextEditingController();
        }
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            
            const SizedBox(height: 24),
            
            // Selection row
            _buildSelectionRow(context),
            
            const SizedBox(height: 16),
            
            // Quick actions
            _buildQuickActions(context),
            
            const SizedBox(height: 16),
            
            // Students list header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    flex: 2,
                    child: Text('Élève', style: theme.textTheme.titleSmall),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text('Note', style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
            ),
            
            // Students list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? _buildEmptyState(context)
                      : _buildStudentsList(context),
            ),
            
            // Actions
            const Divider(),
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.edit_note, color: colorScheme.onTertiaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saisie Groupée des Notes', style: theme.textTheme.headlineSmall),
              Text(
                'Entrez les notes pour tous les élèves à la fois',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        // Stats badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people, size: 18, color: colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Text(
                '${_students.length} élèves',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSelectionRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ResultsProvider>(
      builder: (context, provider, _) {
        final subjects = provider.subjectOfferings;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              // Subject dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: 'Matière',
                    prefixIcon: const Icon(Icons.book),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: subjects.map((s) {
                    final name = s['subjects']?['name'] ?? '';
                    return DropdownMenuItem(
                      value: s['id']?.toString(),
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedSubjectId = v),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Exam type dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedExamType,
                  decoration: InputDecoration(
                    labelText: 'Type d\'examen',
                    prefixIcon: const Icon(Icons.quiz),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _examTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedExamType = v),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Fill all with same value
        FilledButton.tonalIcon(
          onPressed: _fillAllWithValue,
          icon: const Icon(Icons.format_paint, size: 18),
          label: const Text('Remplir tout'),
        ),
        const SizedBox(width: 8),
        
        // Clear all
        OutlinedButton.icon(
          onPressed: _clearAll,
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text('Effacer'),
        ),
        const SizedBox(width: 8),
        
        // Import from clipboard
        OutlinedButton.icon(
          onPressed: _importFromClipboard,
          icon: const Icon(Icons.content_paste, size: 18),
          label: const Text('Coller'),
        ),
        
        const Spacer(),
        
        // Filled/Total indicator
        Text(
          '${_filledCount}/${_students.length} remplis',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  int get _filledCount => _gradeControllers.values.where((c) => c.text.isNotEmpty).length;

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Aucun élève trouvé',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez une classe dans la page principale',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final controller = _gradeControllers[student['id']]!;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: index.isOdd ? colorScheme.surfaceContainerLowest : null,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              // Index
              SizedBox(
                width: 32,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: student['photo_url'] != null
                    ? NetworkImage(student['photo_url'])
                    : null,
                child: student['photo_url'] == null
                    ? Text(
                        _getInitials(student['name'] ?? ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // Name
              Expanded(
                flex: 2,
                child: Text(
                  student['name'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              
              // Grade input
              SizedBox(
                width: 100,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: '/ 20',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  onChanged: (value) {
                    final grade = double.tryParse(value);
                    if (grade != null && (grade < 0 || grade > 20)) {
                      controller.text = grade < 0 ? '0' : '20';
                    }
                    setState(() {
                      _grades[student['id']] = double.tryParse(controller.text);
                    });
                  },
                  onSubmitted: (_) {
                    // Move to next input
                    if (index < _students.length - 1) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Grade color indicator
              _buildGradeIndicator(double.tryParse(controller.text)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeIndicator(double? grade) {
    if (grade == null) {
      return const SizedBox(width: 72);
    }

    Color color;
    String label;
    
    if (grade >= 16) {
      color = Colors.green;
      label = 'Excellent';
    } else if (grade >= 14) {
      color = Colors.lightGreen;
      label = 'Très bien';
    } else if (grade >= 12) {
      color = Colors.blue;
      label = 'Bien';
    } else if (grade >= 10) {
      color = Colors.orange;
      label = 'Passable';
    } else {
      color = Colors.red;
      label = 'Insuffisant';
    }

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final provider = context.read<ResultsProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Stats summary
        if (_filledCount > 0) ...[
          _buildStatChip('Moy.', _calculateAverage()),
          const SizedBox(width: 8),
          _buildStatChip('Min', _calculateMin()),
          const SizedBox(width: 8),
          _buildStatChip('Max', _calculateMax()),
          const Spacer(),
        ] else
          const Spacer(),
        
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _filledCount > 0 ? () => _saveGrades(provider) : null,
          icon: const Icon(Icons.save),
          label: Text('Enregistrer (${_filledCount})'),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _calculateAverage() {
    final grades = _grades.values.whereType<double>().toList();
    if (grades.isEmpty) return '-';
    final avg = grades.reduce((a, b) => a + b) / grades.length;
    return avg.toStringAsFixed(2);
  }

  String _calculateMin() {
    final grades = _grades.values.whereType<double>().toList();
    if (grades.isEmpty) return '-';
    return grades.reduce((a, b) => a < b ? a : b).toStringAsFixed(2);
  }

  String _calculateMax() {
    final grades = _grades.values.whereType<double>().toList();
    if (grades.isEmpty) return '-';
    return grades.reduce((a, b) => a > b ? a : b).toStringAsFixed(2);
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _fillAllWithValue() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Remplir toutes les notes'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Entrez une note (0-20)',
              suffixText: '/ 20',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text;
                for (final c in _gradeControllers.values) {
                  c.text = value;
                }
                for (final student in _students) {
                  _grades[student['id']] = double.tryParse(value);
                }
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Appliquer'),
            ),
          ],
        );
      },
    );
  }

  void _clearAll() {
    for (final controller in _gradeControllers.values) {
      controller.clear();
    }
    _grades.clear();
    setState(() {});
  }

  void _importFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null) return;

      final lines = data!.text!.split('\n');
      int index = 0;
      
      for (final line in lines) {
        if (index >= _students.length) break;
        
        final value = line.trim();
        final grade = double.tryParse(value);
        
        if (grade != null) {
          final studentId = _students[index]['id'];
          _gradeControllers[studentId]?.text = grade.toString();
          _grades[studentId] = grade;
          index++;
        }
      }
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$index notes importées du presse-papiers')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'importation')),
        );
      }
    }
  }

  void _saveGrades(ResultsProvider provider) async {
    if (_selectedSubjectId == null || _selectedExamType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une matière et un type d\'examen')),
      );
      return;
    }

    // Build grades list
    final gradesToSave = <Map<String, dynamic>>[];
    
    for (final student in _students) {
      final grade = _grades[student['id']];
      if (grade != null) {
        gradesToSave.add({
          'student_id': student['id'],
          'grade': grade,
        });
      }
    }

    if (gradesToSave.isEmpty) {
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // TODO: Call provider.saveBulkGrades()
      await Future.delayed(const Duration(seconds: 1)); // Simulate save
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${gradesToSave.length} notes enregistrées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
