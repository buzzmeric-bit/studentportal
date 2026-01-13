import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../models/announcement_model.dart';
import '../../../../repositories/announcement_repository.dart';
import 'student_preview_cards.dart';

class AnnouncementComposerDialog extends StatefulWidget {
  final Announcement? existing;
  final String schoolId;
  final void Function(Announcement) onSaved;

  const AnnouncementComposerDialog({
    Key? key,
    this.existing,
    required this.schoolId,
    required this.onSaved,
  }) : super(key: key);

  @override
  _AnnouncementComposerDialogState createState() => _AnnouncementComposerDialogState();
}

class _AnnouncementComposerDialogState extends State<AnnouncementComposerDialog> {
  final _formKey = GlobalKey<FormState>();

  late AnnouncementScope _scope;
  String? _selectedClassId;
  String? _selectedGroupId;
  late AnnouncementType _announcementType;
  late SenderType _senderType;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _senderLabelController = TextEditingController();
  bool _isImportant = false;
  bool _isPinned = false;
  bool _isLoading = false;

  // Type-specific payload controllers
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _replacementNoteController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _oldRoomController = TextEditingController();
  final TextEditingController _newRoomController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _closedFromController = TextEditingController();
  final TextEditingController _closedToController = TextEditingController();
  final TextEditingController _reopenDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _actionRequiredController = TextEditingController();

  final List<_PendingAttachment> _pendingAttachments = [];
  final List<Attachment> _existingAttachments = [];

  late final AnnouncementRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = AnnouncementRepository();
    _scope = widget.existing?.scope ?? AnnouncementScope.global;
    _announcementType = widget.existing?.announcementType ?? AnnouncementType.general;
    _senderType = widget.existing?.senderType ?? SenderType.administration;

    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _bodyController.text = widget.existing!.body;
      _isImportant = widget.existing!.isImportant;
      _isPinned = widget.existing!.isPinned;
      _selectedClassId = widget.existing!.classId;
      _selectedGroupId = widget.existing!.groupId;
      
      // Populate sender label for teacher
      if (widget.existing!.senderType == SenderType.teacher) {
        _senderLabelController.text = widget.existing!.senderLabel ?? '';
      }

      // Load existing attachments
      _existingAttachments.addAll(widget.existing!.attachments);
      
      // Populate payload controllers from existing payload
      final payload = widget.existing!.payload;
      if (payload.isNotEmpty) {
        _teacherNameController.text = payload['teacher_name'] ?? '';
        _startDateController.text = payload['start_date'] ?? '';
        _endDateController.text = payload['end_date'] ?? '';
        _replacementNoteController.text = payload['replacement_note'] ?? '';
        _subjectController.text = payload['subject'] ?? '';
        _oldRoomController.text = payload['old_room'] ?? '';
        _newRoomController.text = payload['new_room'] ?? '';
        _dateTimeController.text = payload['date_time'] ?? '';
        _roomController.text = payload['room'] ?? '';
        _instructionsController.text = payload['instructions'] ?? '';
        _reasonController.text = payload['reason'] ?? '';
        _closedFromController.text = payload['closed_from'] ?? '';
        _closedToController.text = payload['closed_to'] ?? '';
        _reopenDateController.text = payload['reopen_date'] ?? '';
        _dueDateController.text = payload['due_date'] ?? '';
        _actionRequiredController.text = payload['action_required'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _senderLabelController.dispose();
    // Payload controllers
    _teacherNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _replacementNoteController.dispose();
    _subjectController.dispose();
    _oldRoomController.dispose();
    _newRoomController.dispose();
    _dateTimeController.dispose();
    _roomController.dispose();
    _instructionsController.dispose();
    _reasonController.dispose();
    _closedFromController.dispose();
    _closedToController.dispose();
    _reopenDateController.dispose();
    _dueDateController.dispose();
    _actionRequiredController.dispose();
    super.dispose();
  }

  /// Build payload JSON from type-specific fields
  Map<String, dynamic> _buildPayload() {
    switch (_announcementType) {
      case AnnouncementType.teacherAbsent:
        return {
          'teacher_name': _teacherNameController.text.trim(),
          'start_date': _startDateController.text.trim(),
          'end_date': _endDateController.text.trim(),
          'replacement_note': _replacementNoteController.text.trim(),
        };
      case AnnouncementType.roomChange:
        return {
          'subject': _subjectController.text.trim(),
          'old_room': _oldRoomController.text.trim(),
          'new_room': _newRoomController.text.trim(),
          'date_time': _dateTimeController.text.trim(),
        };
      case AnnouncementType.exam:
        return {
          'subject': _subjectController.text.trim(),
          'date_time': _dateTimeController.text.trim(),
          'room': _roomController.text.trim(),
          'instructions': _instructionsController.text.trim(),
        };
      case AnnouncementType.closure:
        return {
          'reason': _reasonController.text.trim(),
          'closed_from': _closedFromController.text.trim(),
          'closed_to': _closedToController.text.trim(),
          'reopen_date': _reopenDateController.text.trim(),
        };
      case AnnouncementType.reminder:
        return {
          'due_date': _dueDateController.text.trim(),
          'action_required': _actionRequiredController.text.trim(),
        };
      default:
        return {};
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_scope == AnnouncementScope.classScope && _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une classe')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      
      var announcement = Announcement(
        id: widget.existing?.id ?? '',
        scope: _scope,
        schoolId: _scope == AnnouncementScope.global ? widget.schoolId : null,
        classId: _scope == AnnouncementScope.classScope ? _selectedClassId : null,
        groupId: _scope == AnnouncementScope.classScope ? _selectedGroupId : null,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        isImportant: _isImportant,
        isPinned: _isPinned,
        announcementType: _announcementType,
        senderType: _senderType,
        senderLabel: _senderType == SenderType.teacher 
            ? _senderLabelController.text.trim() 
            : null,
        senderAvatarText: _senderType == SenderType.teacher 
            ? _senderLabelController.text.trim().isNotEmpty
                ? _senderLabelController.text.trim().substring(0, 1).toUpperCase()
                : null
            : null,
        publishedAt: now,
        createdBy: widget.existing?.createdBy,
        createdAt: widget.existing?.createdAt ?? now,
        payload: _buildPayload(), // Type-specific structured fields
      );

      // Save announcement
      Announcement savedAnnouncement;
      if (widget.existing != null) {
        savedAnnouncement = await _repository.updateAnnouncement(announcement);
      } else {
        savedAnnouncement = await _repository.createAnnouncement(announcement);
      }

      // Upload new attachments
      String? firstAttachmentUrl;
      String? firstAttachmentName;
      
      for (final pending in _pendingAttachments) {
        final url = await _repository.uploadAttachment(
          announcementId: savedAnnouncement.id,
          fileName: pending.fileName,
          fileBytes: pending.bytes,
          mimeType: pending.mimeType,
        );

        // Save metadata
        await _repository.saveAttachmentMetadata(
          scope: _scope == AnnouncementScope.global ? 'global' : 'class',
          announcementId: savedAnnouncement.id,
          fileUrl: url,
          fileName: pending.fileName,
          mimeType: pending.mimeType,
          sizeBytes: pending.bytes.length,
        );

        // Keep first attachment for backward compatibility
        firstAttachmentUrl ??= url;
        firstAttachmentName ??= pending.fileName;
      }

      // Update announcement with first attachment URL for backward compatibility
      if (firstAttachmentUrl != null) {
        savedAnnouncement = savedAnnouncement.copyWith(
          attachmentUrl: firstAttachmentUrl,
          attachmentName: firstAttachmentName,
        );
        await _repository.updateAnnouncement(savedAnnouncement);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved(savedAnnouncement);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existing != null;

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.add_circle,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Modifier l\'annonce' : 'Nouvelle annonce',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scope selection
                      Text('Type d\'annonce', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      SegmentedButton<AnnouncementScope>(
                        segments: const [
                          ButtonSegment(
                            value: AnnouncementScope.global,
                            label: Text('Notification'),
                            icon: Icon(Icons.notifications),
                          ),
                          ButtonSegment(
                            value: AnnouncementScope.classScope,
                            label: Text('Message'),
                            icon: Icon(Icons.group),
                          ),
                        ],
                        selected: {_scope},
                        onSelectionChanged: (selection) {
                          setState(() => _scope = selection.first);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Class selection (for Messages)
                      if (_scope == AnnouncementScope.classScope) ...[
                        Text('Destinataires', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        // TODO: Replace with actual class dropdown from your data
                        DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Classe',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            // TODO: Load classes from repository
                            DropdownMenuItem(value: 'class1', child: Text('6ème A')),
                            DropdownMenuItem(value: 'class2', child: Text('6ème B')),
                            DropdownMenuItem(value: 'class3', child: Text('5ème A')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedClassId = value;
                              _selectedGroupId = null;
                            });
                          },
                          validator: (value) {
                            if (_scope == AnnouncementScope.classScope && value == null) {
                              return 'Veuillez sélectionner une classe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Announcement type
                      Text('Catégorie', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AnnouncementType>(
                        value: _announcementType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: AnnouncementType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _announcementType = value!);
                        },
                      ),
                      // Type-specific form section
                      _buildTypeSpecificForm(),
                      const SizedBox(height: 16),

                      // Sender type (for Messages)
                      if (_scope == AnnouncementScope.classScope) ...[
                        Text('Expéditeur', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SegmentedButton<SenderType>(
                          segments: const [
                            ButtonSegment(
                              value: SenderType.administration,
                              label: Text('Administration'),
                            ),
                            ButtonSegment(
                              value: SenderType.teacher,
                              label: Text('Enseignant'),
                            ),
                          ],
                          selected: {_senderType},
                          onSelectionChanged: (selection) {
                            setState(() => _senderType = selection.first);
                          },
                        ),
                        if (_senderType == SenderType.teacher) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _senderLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Nom de l\'enseignant',
                              hintText: 'Ex: Prof. Benali',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le titre est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Body
                      TextFormField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          labelText: 'Contenu',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le contenu est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Options
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Important'),
                              subtitle: const Text('Afficher un badge'),
                              value: _isImportant,
                              onChanged: (value) {
                                setState(() => _isImportant = value ?? false);
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Épingler'),
                              subtitle: const Text('En haut de liste'),
                              value: _isPinned,
                              onChanged: (value) {
                                setState(() => _isPinned = value ?? false);
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Attachments
                      Text('Pièces jointes', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      
                      // Existing attachments
                      if (_existingAttachments.isNotEmpty) ...[
                        ...List.generate(_existingAttachments.length, (index) {
                          final att = _existingAttachments[index];
                          return ListTile(
                            leading: const Icon(Icons.attach_file),
                            title: Text(att.fileName),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removeExistingAttachment(index),
                            ),
                            dense: true,
                          );
                        }),
                      ],
                      
                      // Pending attachments
                      if (_pendingAttachments.isNotEmpty) ...[
                        ...List.generate(_pendingAttachments.length, (index) {
                          final att = _pendingAttachments[index];
                          return ListTile(
                            leading: const Icon(Icons.upload_file),
                            title: Text(att.fileName),
                            subtitle: Text(_formatBytes(att.bytes.length)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removePendingAttachment(index),
                            ),
                            dense: true,
                          );
                        }),
                      ],
                      
                      OutlinedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter des fichiers'),
                      ),
                    ],
                  ),
                ),
              ),

              // Preview section - REAL STUDENT APP UI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Aperçu en temps réel', style: theme.textTheme.titleSmall),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _scope == AnnouncementScope.global ? 'Notification' : 'Messages',
                            style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRealPreview(),
                  ],
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _save,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(isEditing ? 'Enregistrer' : 'Publier'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealPreview() {
    // Convert pending attachments to preview format
    final previewAttachments = _pendingAttachments.map((a) => PreviewAttachment(
      fileName: a.fileName,
      bytes: a.bytes,
      mimeType: a.mimeType,
    )).toList();

    if (_scope == AnnouncementScope.global) {
      return StudentNoteInfoPreviewCard(
        title: _titleController.text,
        body: _bodyController.text,
        isImportant: _isImportant,
        isPinned: _isPinned,
        announcementType: _announcementType.toValue(),
        publishedAt: DateTime.now(),
        hasAttachment: _pendingAttachments.isNotEmpty || _existingAttachments.isNotEmpty,
        attachments: previewAttachments,
        payload: _buildPayload(),
      );
    } else {
      return StudentMessagePreviewCard(
        title: _titleController.text,
        body: _bodyController.text,
        isImportant: _isImportant,
        isPinned: _isPinned,
        announcementType: _announcementType.toValue(),
        senderLabel: _senderType == SenderType.teacher ? _senderLabelController.text : 'Administration',
        senderAvatarText: _senderType == SenderType.teacher && _senderLabelController.text.isNotEmpty
            ? _senderLabelController.text[0].toUpperCase()
            : 'A',
        publishedAt: DateTime.now(),
        hasAttachment: _pendingAttachments.isNotEmpty || _existingAttachments.isNotEmpty,
        attachments: previewAttachments,
        payload: _buildPayload(),
      );
    }
  }

  /// Type-specific form section
  Widget _buildTypeSpecificForm() {
    switch (_announcementType) {
      case AnnouncementType.teacherAbsent:
        return _buildTeacherAbsentForm();
      case AnnouncementType.roomChange:
        return _buildRoomChangeForm();
      case AnnouncementType.exam:
        return _buildExamForm();
      case AnnouncementType.closure:
        return _buildClosureForm();
      case AnnouncementType.reminder:
        return _buildReminderForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTeacherAbsentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Détails de l\'absence', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.orange)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _teacherNameController,
          decoration: const InputDecoration(labelText: 'Nom de l\'enseignant', border: OutlineInputBorder(), isDense: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _startDateController,
                decoration: const InputDecoration(labelText: 'Date début', border: OutlineInputBorder(), isDense: true, hintText: 'JJ/MM/AAAA'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(labelText: 'Date fin', border: OutlineInputBorder(), isDense: true, hintText: 'JJ/MM/AAAA'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _replacementNoteController,
          decoration: const InputDecoration(labelText: 'Note de remplacement (optionnel)', border: OutlineInputBorder(), isDense: true),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildRoomChangeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Détails du changement', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.blue)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _subjectController,
          decoration: const InputDecoration(labelText: 'Matière (optionnel)', border: OutlineInputBorder(), isDense: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _oldRoomController,
                decoration: const InputDecoration(labelText: 'Ancienne salle', border: OutlineInputBorder(), isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 20)),
            Expanded(
              child: TextFormField(
                controller: _newRoomController,
                decoration: const InputDecoration(labelText: 'Nouvelle salle', border: OutlineInputBorder(), isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dateTimeController,
          decoration: const InputDecoration(labelText: 'Date/heure (optionnel)', border: OutlineInputBorder(), isDense: true, hintText: 'Ex: Mardi 15/01 à 10h'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildExamForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Détails de l\'examen', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.purple)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _subjectController,
          decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder(), isDense: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dateTimeController,
                decoration: const InputDecoration(labelText: 'Date et heure', border: OutlineInputBorder(), isDense: true, hintText: 'Ex: 20/01/2026 09:00'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Salle', border: OutlineInputBorder(), isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _instructionsController,
          decoration: const InputDecoration(labelText: 'Instructions', border: OutlineInputBorder(), isDense: true, hintText: 'Ex: Apporter calculatrice'),
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildClosureForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Détails de la fermeture', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.red)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          decoration: const InputDecoration(labelText: 'Raison', border: OutlineInputBorder(), isDense: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _closedFromController,
                decoration: const InputDecoration(labelText: 'Fermé du', border: OutlineInputBorder(), isDense: true, hintText: 'JJ/MM/AAAA'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _closedToController,
                decoration: const InputDecoration(labelText: 'Au', border: OutlineInputBorder(), isDense: true, hintText: 'JJ/MM/AAAA'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reopenDateController,
          decoration: const InputDecoration(labelText: 'Date de réouverture', border: OutlineInputBorder(), isDense: true, hintText: 'JJ/MM/AAAA'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildReminderForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Détails du rappel', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.teal)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dueDateController,
          decoration: const InputDecoration(labelText: 'Date limite', border: OutlineInputBorder(), isDense: true, hintText: 'JJ/MM/AAAA'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _actionRequiredController,
          decoration: const InputDecoration(labelText: 'Action requise', border: OutlineInputBorder(), isDense: true, hintText: 'Ex: Inscription aux examens'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        // TODO: Add your allowed file types
        // allowedExtensions: ['jpg', 'png', 'pdf', 'docx'],
      );

      if (result != null) {
        setState(() {
          _pendingAttachments.addAll(result.files.map((file) {
            return _PendingAttachment(
              fileName: file.name,
              bytes: file.bytes!,
              mimeType: file.extension ?? 'application/octet-stream',
            );
          }));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection des fichiers: $e')),
      );
    }
  }

  void _removePendingAttachment(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
    });
  }

  void _removeExistingAttachment(int index) {
    // TODO: Call repository to delete the attachment from server
    // _repository.deleteAttachment(_existingAttachments[index].id);

    setState(() {
      _existingAttachments.removeAt(index);
    });
  }
}

class _PendingAttachment {
  final String fileName;
  final Uint8List bytes;
  final String mimeType;

  _PendingAttachment({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });
}