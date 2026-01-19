import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/academic_models.dart';
import '../../providers/classes_provider.dart';
import '../../providers/grade_levels_provider.dart';

class ClassFormDialog extends ConsumerStatefulWidget {
  final ClassModel? classModel;
  const ClassFormDialog({super.key, this.classModel});
  @override
  ConsumerState<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends ConsumerState<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _roomController;
  late final TextEditingController _capacityController;
  String? _selectedGradeLevelId;
  String? _selectedSectionId;
  bool _isLoading = false;

  bool get isEditing => widget.classModel != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classModel?.name ?? '');
    _roomController = TextEditingController(text: widget.classModel?.room ?? '');
    _capacityController = TextEditingController(text: widget.classModel?.capacity?.toString() ?? '');
    _selectedGradeLevelId = widget.classModel?.gradeLevelId;
    _selectedSectionId = widget.classModel?.sectionId;
  }

  @override
  Widget build(BuildContext context) {
    final gradeLevelsAsync = ref.watch(gradeLevelsProvider);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isEditing ? Icons.edit : Icons.class_, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(isEditing ? 'Modifier la classe' : 'Nouvelle classe',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom de la classe *', prefixIcon: Icon(Icons.label)),
                validator: (v) => v?.isEmpty == true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              gradeLevelsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur: $e', style: const TextStyle(color: Colors.red)),
                data: (state) => Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedGradeLevelId,
                      decoration: const InputDecoration(labelText: 'Niveau scolaire *', prefixIcon: Icon(Icons.school)),
                      items: state.gradeLevels.map((g) => DropdownMenuItem<String>(
                        value: g.id, 
                        child: Text('${g.name} (${g.levelType == 'college' ? 'Collège' : 'Secondaire'})'),
                      )).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedGradeLevelId = v;
                          // Reset section when grade changes
                          _selectedSectionId = null;
                        });
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      hint: const Text('Sélectionner un niveau'),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionDropdown(state),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roomController,
                      decoration: const InputDecoration(labelText: 'Salle', prefixIcon: Icon(Icons.room)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Capacité', prefixIcon: Icon(Icons.people)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEditing ? 'Modifier' : 'Créer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDropdown(GradeLevelsState state) {
    // Get sections available for the selected grade level
    List<SectionModel> availableSections = [];
    if (_selectedGradeLevelId != null) {
      final grade = state.gradeLevels.firstWhere(
        (g) => g.id == _selectedGradeLevelId,
        orElse: () => GradeLevelModel(id: '', name: '', code: '', levelType: 'college'),
      );
      
      // Only secondaire grades have sections
      if (grade.levelType == 'secondaire') {
        // Get sections that are assigned to this grade (from the sections property)
        availableSections = grade.sections;
      }
    }

    if (availableSections.isEmpty && _selectedGradeLevelId != null) {
      final grade = state.gradeLevels.firstWhere(
        (g) => g.id == _selectedGradeLevelId,
        orElse: () => GradeLevelModel(id: '', name: '', code: '', levelType: 'college'),
      );
      if (grade.levelType == 'college') {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text('Les classes du collège n\'ont pas de filière', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        );
      }
    }

    return DropdownButtonFormField<String>(
      value: _selectedSectionId,
      decoration: const InputDecoration(labelText: 'Filière', prefixIcon: Icon(Icons.category)),
      items: availableSections.map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name))).toList(),
      onChanged: (v) => setState(() => _selectedSectionId = v),
      hint: const Text('Aucune filière'),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(classesProvider.notifier);
      final capacity = _capacityController.text.isEmpty ? null : int.tryParse(_capacityController.text);
      final room = _roomController.text.isEmpty ? null : _roomController.text.trim();

      if (isEditing) {
        await notifier.updateClass(
          id: widget.classModel!.id,
          name: _nameController.text.trim(),
          gradeLevelId: _selectedGradeLevelId,
          sectionId: _selectedSectionId,
          capacity: capacity,
          room: room,
        );
      } else {
        await notifier.create(
          name: _nameController.text.trim(),
          gradeLevelId: _selectedGradeLevelId,
          sectionId: _selectedSectionId,
          capacity: capacity,
          room: room,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Classe modifiée' : 'Classe créée'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}