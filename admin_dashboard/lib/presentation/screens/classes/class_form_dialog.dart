import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/class_model.dart';
import '../../providers/classes_provider.dart';

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
  String? _selectedGroupId;
  bool _isLoading = false;

  bool get isEditing => widget.classModel != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classModel?.name ?? '');
    _roomController = TextEditingController(text: widget.classModel?.room ?? '');
    _capacityController = TextEditingController(text: widget.classModel?.capacity?.toString() ?? '');
    _selectedGroupId = widget.classModel?.groupId;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
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
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Salle', prefixIcon: Icon(Icons.room)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacite', prefixIcon: Icon(Icons.people)),
                keyboardType: TextInputType.number,
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
                        : Text(isEditing ? 'Modifier' : 'Creer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          groupId: _selectedGroupId,
          capacity: capacity,
          room: room,
        );
      } else {
        await notifier.create(
          name: _nameController.text.trim(),
          groupId: _selectedGroupId,
          capacity: capacity,
          room: room,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Classe modifiee' : 'Classe creee'), backgroundColor: Colors.green));
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