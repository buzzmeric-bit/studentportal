import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/grading_config_model.dart';
import '../../providers/results_provider.dart';

/// Dialog for configuring grading formulas and exam types
class GradingConfigDialog extends StatefulWidget {
  final GradingConfiguration? initialConfig;
  final Function(GradingConfiguration) onSave;

  const GradingConfigDialog({
    super.key,
    this.initialConfig,
    required this.onSave,
  });

  @override
  State<GradingConfigDialog> createState() => _GradingConfigDialogState();
}

class _GradingConfigDialogState extends State<GradingConfigDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Formula settings
  String _formulaType = 'tunisian'; // tunisian, weighted, simple, custom
  String _customFormula = '';
  
  // Weight settings (for Tunisian: DC 25%, DS 75%)
  double _dcWeight = 25;
  double _dsWeight = 75;
  double _oralWeight = 0;
  double _tpWeight = 0;
  
  // DC breakdown
  int _dcCount = 2; // Number of DC exams
  bool _dcAverageMode = true; // Average or sum of DC
  
  // Coefficients by subject (editable)
  Map<String, double> _subjectCoefficients = {};
  
  // Exam types
  List<ExamTypeConfig> _examTypes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initFromConfig();
  }

  void _initFromConfig() {
    if (widget.initialConfig != null) {
      // TODO: Parse from initial config
      // For now, use Tunisian defaults
      _examTypes = [
        ExamTypeConfig(code: 'DC1', name: 'Devoir de Contrôle 1', weight: 12.5, order: 1),
        ExamTypeConfig(code: 'DC2', name: 'Devoir de Contrôle 2', weight: 12.5, order: 2),
        ExamTypeConfig(code: 'DS', name: 'Devoir de Synthèse', weight: 75, order: 3),
      ];
    } else {
      _examTypes = [
        ExamTypeConfig(code: 'DC1', name: 'Devoir de Contrôle 1', weight: 12.5, order: 1),
        ExamTypeConfig(code: 'DC2', name: 'Devoir de Contrôle 2', weight: 12.5, order: 2),
        ExamTypeConfig(code: 'DS', name: 'Devoir de Synthèse', weight: 75, order: 3),
      ];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.settings, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Configuration des Notes', style: theme.textTheme.headlineSmall),
                      Text(
                        'Formule de calcul, types d\'examens et coefficients',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
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

            const SizedBox(height: 24),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.calculate), text: 'Formule'),
                Tab(icon: Icon(Icons.quiz), text: 'Types d\'Examens'),
                Tab(icon: Icon(Icons.school), text: 'Coefficients'),
              ],
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFormulaTab(context),
                  _buildExamTypesTab(context),
                  _buildCoefficientsTab(context),
                ],
              ),
            ),

            // Actions
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.restore),
                  label: const Text('Valeurs par défaut'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _saveConfig,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formula type selector
          Text('Type de Formule', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _formulaChip('tunisian', 'Tunisienne', Icons.flag,
                  'DC(25%) + DS(75%)'),
              _formulaChip('weighted', 'Pondérée', Icons.balance,
                  'Moyenne pondérée personnalisée'),
              _formulaChip('simple', 'Simple', Icons.calculate,
                  'Moyenne arithmétique'),
              _formulaChip('custom', 'Personnalisée', Icons.code,
                  'Formule mathématique'),
            ],
          ),

          const SizedBox(height: 32),

          // Formula preview box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.functions, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Aperçu de la Formule', style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormulaPreview(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Formula parameters
          if (_formulaType == 'tunisian' || _formulaType == 'weighted') ...[
            Text('Répartition des Poids', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            
            _buildWeightSlider('Devoirs de Contrôle (DC)', _dcWeight, (v) {
              setState(() {
                _dcWeight = v;
                _dsWeight = 100 - v - _oralWeight - _tpWeight;
              });
            }),
            
            _buildWeightSlider('Devoir de Synthèse (DS)', _dsWeight, (v) {
              setState(() {
                _dsWeight = v;
                _dcWeight = 100 - v - _oralWeight - _tpWeight;
              });
            }),
            
            if (_formulaType == 'weighted') ...[
              _buildWeightSlider('Oral/Participation', _oralWeight, (v) {
                setState(() {
                  _oralWeight = v;
                });
              }),
              
              _buildWeightSlider('TP/Pratique', _tpWeight, (v) {
                setState(() {
                  _tpWeight = v;
                });
              }),
            ],

            const SizedBox(height: 24),

            // DC count
            Row(
              children: [
                Text('Nombre de DC par semestre:', style: theme.textTheme.bodyLarge),
                const SizedBox(width: 16),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1')),
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                  ],
                  selected: {_dcCount},
                  onSelectionChanged: (v) => setState(() => _dcCount = v.first),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Calculer la moyenne des DC'),
              subtitle: Text(_dcAverageMode
                  ? 'Les DC sont moyennés puis pondérés'
                  : 'Chaque DC a un poids individuel'),
              value: _dcAverageMode,
              onChanged: (v) => setState(() => _dcAverageMode = v),
            ),
          ],

          if (_formulaType == 'custom') ...[
            Text('Formule Personnalisée', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              'Variables disponibles: DC1, DC2, DC3, DS, ORAL, TP, PRAT',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: '(DC1 + DC2) / 2 * 0.25 + DS * 0.75',
                prefixIcon: const Icon(Icons.code),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
              onChanged: (v) => setState(() => _customFormula = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _formulaChip(String type, String label, IconData icon, String description) {
    final isSelected = _formulaType == type;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => setState(() => _formulaType = type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : null,
            )),
            const SizedBox(height: 4),
            SizedBox(
              width: 120,
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaPreview() {
    final theme = Theme.of(context);
    
    String formula;
    switch (_formulaType) {
      case 'tunisian':
        if (_dcCount == 2) {
          formula = 'Moyenne = ((DC₁ + DC₂)/2 × ${_dcWeight.toInt()}% + DS × ${_dsWeight.toInt()}%) / 100';
        } else if (_dcCount == 1) {
          formula = 'Moyenne = (DC × ${_dcWeight.toInt()}% + DS × ${_dsWeight.toInt()}%) / 100';
        } else {
          formula = 'Moyenne = ((DC₁ + DC₂ + DC₃)/3 × ${_dcWeight.toInt()}% + DS × ${_dsWeight.toInt()}%) / 100';
        }
        break;
      case 'weighted':
        formula = 'Moyenne = Σ(Note × Poids) / Σ(Poids)';
        break;
      case 'simple':
        formula = 'Moyenne = Σ(Notes) / Nombre de notes';
        break;
      case 'custom':
        formula = _customFormula.isEmpty ? '(Entrez votre formule)' : _customFormula;
        break;
      default:
        formula = '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formula,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          color: theme.colorScheme.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWeightSlider(String label, double value, Function(double) onChanged) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildExamTypesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Types d\'Examens', style: theme.textTheme.titleMedium),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _addExamType,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Définissez les types d\'examens et leurs poids dans la moyenne',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          
          // Exam types list
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _examTypes.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _examTypes.removeAt(oldIndex);
                  _examTypes.insert(newIndex, item);
                  // Update order
                  for (int i = 0; i < _examTypes.length; i++) {
                    _examTypes[i] = _examTypes[i].copyWith(order: i + 1);
                  }
                });
              },
              itemBuilder: (context, index) {
                final examType = _examTypes[index];
                return _buildExamTypeCard(examType, index);
              },
            ),
          ),
          
          // Total weight indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _totalWeight == 100 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _totalWeight == 100 ? Colors.green : Colors.orange,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _totalWeight == 100 ? Icons.check_circle : Icons.warning,
                  color: _totalWeight == 100 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'Total des poids: ${_totalWeight.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _totalWeight == 100 ? Colors.green : Colors.orange,
                  ),
                ),
                if (_totalWeight != 100) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(doit être égal à 100%)',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get _totalWeight => _examTypes.fold(0, (sum, e) => sum + e.weight);

  Widget _buildExamTypeCard(ExamTypeConfig examType, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: ValueKey(examType.code),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Drag handle
            Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            
            // Code chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                examType.code,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(examType.name, style: theme.textTheme.bodyLarge),
                  Text(
                    'Poids: ${examType.weight}%',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            // Weight slider (compact)
            SizedBox(
              width: 150,
              child: Slider(
                value: examType.weight,
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: (v) {
                  setState(() {
                    _examTypes[index] = examType.copyWith(weight: v);
                  });
                },
              ),
            ),
            
            // Weight display
            SizedBox(
              width: 50,
              child: Text(
                '${examType.weight.toInt()}%',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            
            // Edit button
            IconButton(
              onPressed: () => _editExamType(index),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
            ),
            
            // Delete button
            IconButton(
              onPressed: () => _deleteExamType(index),
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoefficientsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ResultsProvider>(
      builder: (context, provider, _) {
        final subjects = provider.subjectOfferings;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Coefficients par Matière', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _loadDefaultCoefficients,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('Charger les défauts'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Modifiez les coefficients pour le calcul de la moyenne générale',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              if (subjects.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.class_, size: 48, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('Sélectionnez une classe pour voir les matières'),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final subjectName = subject['subjects']?['name'] ?? '';
                      final subjectCode = subject['subjects']?['code'] ?? '';
                      final currentCoef = _subjectCoefficients[subject['id']] ??
                          (subject['coefficient']?.toDouble() ?? 1.0);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subjectCode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          title: Text(subjectName),
                          trailing: SizedBox(
                            width: 120,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (currentCoef > 0.5) {
                                      setState(() {
                                        _subjectCoefficients[subject['id']] = currentCoef - 0.5;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                  iconSize: 20,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    currentCoef.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _subjectCoefficients[subject['id']] = currentCoef + 0.5;
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _addExamType() {
    showDialog(
      context: context,
      builder: (context) => _ExamTypeEditDialog(
        onSave: (examType) {
          setState(() {
            _examTypes.add(examType.copyWith(order: _examTypes.length + 1));
          });
        },
      ),
    );
  }

  void _editExamType(int index) {
    showDialog(
      context: context,
      builder: (context) => _ExamTypeEditDialog(
        examType: _examTypes[index],
        onSave: (examType) {
          setState(() {
            _examTypes[index] = examType;
          });
        },
      ),
    );
  }

  void _deleteExamType(int index) {
    setState(() {
      _examTypes.removeAt(index);
    });
  }

  void _loadDefaultCoefficients() {
    // TODO: Load from TunisianCoefficientTables based on niveau
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coefficients par défaut chargés')),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _formulaType = 'tunisian';
      _dcWeight = 25;
      _dsWeight = 75;
      _oralWeight = 0;
      _tpWeight = 0;
      _dcCount = 2;
      _dcAverageMode = true;
      _examTypes = [
        ExamTypeConfig(code: 'DC1', name: 'Devoir de Contrôle 1', weight: 12.5, order: 1),
        ExamTypeConfig(code: 'DC2', name: 'Devoir de Contrôle 2', weight: 12.5, order: 2),
        ExamTypeConfig(code: 'DS', name: 'Devoir de Synthèse', weight: 75, order: 3),
      ];
      _subjectCoefficients.clear();
    });
  }

  void _saveConfig() {
    // Create proper GradingFormula from current weights
    final formula = GradingFormula(
      name: _formulaType == 'tunisian' ? 'Tunisienne' : 
            _formulaType == 'weighted' ? 'Pondérée' : 
            _formulaType == 'simple' ? 'Simple' : 'Personnalisée',
      description: _getFormulaDescription(),
      weights: {
        GradeComponentType.dc: _dcWeight / 100,
        GradeComponentType.ds: _dsWeight / 100,
        if (_oralWeight > 0) GradeComponentType.oral: _oralWeight / 100,
        if (_tpWeight > 0) GradeComponentType.tp: _tpWeight / 100,
      },
      divisor: 1.0, // Already in percentages
    );
    
    // Create GradingConfiguration
    final config = GradingConfiguration(
      id: widget.initialConfig?.id ?? DateTime.now().toIso8601String(),
      level: widget.initialConfig?.level ?? EducationLevel.lycee1,
      section: widget.initialConfig?.section,
      subjects: widget.initialConfig?.subjects ?? [],
      defaultFormula: formula,
      isEditable: true,
      updatedAt: DateTime.now(),
    );
    
    widget.onSave(config);
    Navigator.pop(context);
  }
  
  String _getFormulaDescription() {
    switch (_formulaType) {
      case 'tunisian':
        if (_dcCount == 2) {
          return '((DC₁ + DC₂)/2 × ${_dcWeight.toInt()}% + DS × ${_dsWeight.toInt()}%)';
        } else if (_dcCount == 1) {
          return '(DC × ${_dcWeight.toInt()}% + DS × ${_dsWeight.toInt()}%)';
        } else {
          return '((DC₁ + DC₂ + DC₃)/3 × ${_dcWeight.toInt()}% + DS × ${_dsWeight.toInt()}%)';
        }
      case 'weighted':
        return 'Moyenne pondérée personnalisée';
      case 'simple':
        return 'Moyenne arithmétique';
      case 'custom':
        return _customFormula.isEmpty ? 'Formule personnalisée' : _customFormula;
      default:
        return '';
    }
  }
}

/// Simple model for exam type configuration
class ExamTypeConfig {
  final String code;
  final String name;
  final double weight;
  final int order;

  ExamTypeConfig({
    required this.code,
    required this.name,
    required this.weight,
    required this.order,
  });

  ExamTypeConfig copyWith({
    String? code,
    String? name,
    double? weight,
    int? order,
  }) {
    return ExamTypeConfig(
      code: code ?? this.code,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      order: order ?? this.order,
    );
  }
}

/// Dialog for editing a single exam type
class _ExamTypeEditDialog extends StatefulWidget {
  final ExamTypeConfig? examType;
  final Function(ExamTypeConfig) onSave;

  const _ExamTypeEditDialog({
    this.examType,
    required this.onSave,
  });

  @override
  State<_ExamTypeEditDialog> createState() => _ExamTypeEditDialogState();
}

class _ExamTypeEditDialogState extends State<_ExamTypeEditDialog> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  double _weight = 25;

  @override
  void initState() {
    super.initState();
    if (widget.examType != null) {
      _codeController.text = widget.examType!.code;
      _nameController.text = widget.examType!.name;
      _weight = widget.examType!.weight;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.examType == null ? 'Nouveau Type d\'Examen' : 'Modifier Type d\'Examen'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Code',
                hintText: 'Ex: DC1, DS, TP',
                prefixIcon: Icon(Icons.code),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                hintText: 'Ex: Devoir de Contrôle 1',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Poids:'),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _weight,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_weight.toInt()}%',
                    onChanged: (v) => setState(() => _weight = v),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text('${_weight.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (_codeController.text.isEmpty || _nameController.text.isEmpty) {
              return;
            }
            widget.onSave(ExamTypeConfig(
              code: _codeController.text.toUpperCase(),
              name: _nameController.text,
              weight: _weight,
              order: widget.examType?.order ?? 1,
            ));
            Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
