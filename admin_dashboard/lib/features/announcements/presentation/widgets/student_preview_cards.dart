import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Real preview widgets that match student app UI exactly
/// These are used in the admin composer dialog to show how announcements will appear

// =============================================================================
// STUDENT NOTE INFO PREVIEW (matches note_info_screen.dart)
// =============================================================================

class StudentNoteInfoPreviewCard extends StatelessWidget {
  final String title;
  final String body;
  final bool isImportant;
  final bool isPinned;
  final String? announcementType;
  final DateTime? publishedAt;
  final bool hasAttachment;
  final String? attachmentName;
  final List<PreviewAttachment> attachments;
  final Map<String, dynamic> payload; // Type-specific structured fields

  const StudentNoteInfoPreviewCard({
    Key? key,
    required this.title,
    required this.body,
    this.isImportant = false,
    this.isPinned = false,
    this.announcementType,
    this.publishedAt,
    this.hasAttachment = false,
    this.attachmentName,
    this.attachments = const [],
    this.payload = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.campaign, size: 12, color: Color(0xFFE91E63)),
                const SizedBox(width: 4),
                const Text('Note d\'info', style: TextStyle(fontSize: 10, color: Color(0xFFE91E63), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Card content
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Row(
                    children: [
                      if (isImportant)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Important',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (isPinned)
                        const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                      if (announcementType != null && announcementType != 'general') ...[
                        const SizedBox(width: 4),
                        _buildTypeBadge(announcementType!),
                      ],
                      const Spacer(),
                    ],
                  ),
                  if (isImportant || isPinned || (announcementType != null && announcementType != 'general'))
                    const SizedBox(height: 8),
                  // Title
                  Text(
                    title.isEmpty ? 'Titre de l\'annonce...' : title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Body
                  Text(
                    body.isEmpty ? 'Contenu de l\'annonce...' : body,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Type-specific payload fields
                  if (payload.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPayloadSection(context),
                  ],
                  const SizedBox(height: 8),
                  // Footer
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        publishedAt != null ? dateFormat.format(publishedAt!) : 'Maintenant',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                      if (hasAttachment || attachments.isNotEmpty) ...[
                        const Spacer(),
                        Icon(Icons.attach_file, size: 12, color: theme.primaryColor),
                        const SizedBox(width: 2),
                        Text(
                          attachmentName ?? '${attachments.length} fichier(s)',
                          style: TextStyle(fontSize: 10, color: theme.primaryColor),
                        ),
                      ],
                    ],
                  ),
                  // Attachments preview (images)
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildAttachmentsPreview(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final info = _getTypeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 10, color: info.color),
          const SizedBox(width: 2),
          Text(info.label, style: TextStyle(fontSize: 9, color: info.color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Build payload section based on announcement type
  Widget _buildPayloadSection(BuildContext context) {
    final theme = Theme.of(context);
    final info = announcementType != null ? _getTypeInfo(announcementType!) : null;
    final color = info?.color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildPayloadFields(theme, color),
      ),
    );
  }

  List<Widget> _buildPayloadFields(ThemeData theme, Color color) {
    final widgets = <Widget>[];

    switch (announcementType) {
      case 'teacher_absent':
        if (payload['teacher_name']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.person, 'Enseignant', payload['teacher_name'], color));
        }
        if (payload['start_date']?.toString().isNotEmpty == true || payload['end_date']?.toString().isNotEmpty == true) {
          final dateStr = payload['start_date'] == payload['end_date'] || payload['end_date']?.toString().isEmpty == true
              ? payload['start_date']
              : '${payload['start_date']} → ${payload['end_date']}';
          widgets.add(_payloadRow(Icons.calendar_today, 'Période', dateStr, color));
        }
        if (payload['replacement_note']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.swap_horiz, 'Remplacement', payload['replacement_note'], color));
        }
        break;

      case 'room_change':
        if (payload['subject']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.subject, 'Matière', payload['subject'], color));
        }
        if (payload['old_room']?.toString().isNotEmpty == true || payload['new_room']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.meeting_room, 'Salle', '${payload['old_room']} → ${payload['new_room']}', color));
        }
        if (payload['date_time']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.schedule, 'Quand', payload['date_time'], color));
        }
        break;

      case 'exam':
        if (payload['subject']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.subject, 'Matière', payload['subject'], color));
        }
        if (payload['date_time']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.event, 'Date/heure', payload['date_time'], color));
        }
        if (payload['room']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.meeting_room, 'Salle', payload['room'], color));
        }
        if (payload['instructions']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.info_outline, 'Instructions', payload['instructions'], color));
        }
        break;

      case 'closure':
        if (payload['reason']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.error_outline, 'Raison', payload['reason'], color));
        }
        if (payload['closed_from']?.toString().isNotEmpty == true || payload['closed_to']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.calendar_today, 'Période', '${payload['closed_from']} → ${payload['closed_to']}', color));
        }
        if (payload['reopen_date']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.event_available, 'Réouverture', payload['reopen_date'], color));
        }
        break;

      case 'reminder':
        if (payload['due_date']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.event, 'Échéance', payload['due_date'], color));
        }
        if (payload['action_required']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.checklist, 'Action requise', payload['action_required'], color));
        }
        break;

      default:
        break;
    }

    return widgets;
  }

  Widget _payloadRow(IconData icon, String label, String? value, Color color) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 10, color: Colors.black87),
                children: [
                  TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsPreview() {
    final imageAttachments = attachments.where((a) => a.isImage).toList();
    final fileAttachments = attachments.where((a) => !a.isImage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image grid (Facebook-style)
        if (imageAttachments.isNotEmpty)
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageAttachments.length.clamp(0, 4),
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (_, i) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: imageAttachments[i].bytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(imageAttachments[i].bytes!, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
        // File chips
        if (fileAttachments.isNotEmpty) ...[
          if (imageAttachments.isNotEmpty) const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: fileAttachments.take(3).map((f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getFileIcon(f.fileName), size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    f.fileName.length > 15 ? '${f.fileName.substring(0, 12)}...' : f.fileName,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// STUDENT MESSAGE PREVIEW (matches messages_screen.dart)
// =============================================================================

class StudentMessagePreviewCard extends StatelessWidget {
  final String title;
  final String body;
  final bool isImportant;
  final bool isPinned;
  final String? announcementType;
  final String? senderLabel;
  final String? senderAvatarText;
  final DateTime? publishedAt;
  final bool hasAttachment;
  final String? attachmentName;
  final List<PreviewAttachment> attachments;
  final Map<String, dynamic> payload; // Type-specific structured fields

  const StudentMessagePreviewCard({
    Key? key,
    required this.title,
    required this.body,
    this.isImportant = false,
    this.isPinned = false,
    this.announcementType,
    this.senderLabel,
    this.senderAvatarText,
    this.publishedAt,
    this.hasAttachment = false,
    this.attachmentName,
    this.attachments = const [],
    this.payload = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final theme = Theme.of(context);
    final displaySender = senderLabel ?? 'Administration';
    final avatarText = senderAvatarText ?? (displaySender.isNotEmpty ? displaySender[0].toUpperCase() : 'A');

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail, size: 12, color: Color(0xFF00BCD4)),
                const SizedBox(width: 4),
                const Text('Message', style: TextStyle(fontSize: 10, color: Color(0xFF00BCD4), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Card content
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with avatar (Facebook-style)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF00BCD4).withOpacity(0.2),
                        child: Text(
                          avatarText,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF00BCD4), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displaySender,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00BCD4)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isImportant) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text('Important', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                                if (isPinned) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.push_pin, size: 12, color: Colors.orange),
                                ],
                              ],
                            ),
                            Text(
                              publishedAt != null ? dateFormat.format(publishedAt!) : 'Maintenant',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Type badge
                  if (announcementType != null && announcementType != 'general') ...[
                    _buildTypeBadge(announcementType!),
                    const SizedBox(height: 6),
                  ],
                  // Title
                  Text(
                    title.isEmpty ? 'Titre du message...' : title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Body
                  Text(
                    body.isEmpty ? 'Contenu du message...' : body,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Type-specific payload fields
                  if (payload.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPayloadSection(context),
                  ],
                  // Attachments preview
                  if (hasAttachment || attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildAttachmentsPreview(theme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final info = _getTypeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 10, color: info.color),
          const SizedBox(width: 2),
          Text(info.label, style: TextStyle(fontSize: 9, color: info.color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Build payload section based on announcement type
  Widget _buildPayloadSection(BuildContext context) {
    final info = announcementType != null ? _getTypeInfo(announcementType!) : null;
    final color = info?.color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildPayloadFields(color),
      ),
    );
  }

  List<Widget> _buildPayloadFields(Color color) {
    final widgets = <Widget>[];

    switch (announcementType) {
      case 'teacher_absent':
        if (payload['teacher_name']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.person, 'Enseignant', payload['teacher_name'], color));
        }
        if (payload['start_date']?.toString().isNotEmpty == true || payload['end_date']?.toString().isNotEmpty == true) {
          final dateStr = payload['start_date'] == payload['end_date'] || payload['end_date']?.toString().isEmpty == true
              ? payload['start_date']
              : '${payload['start_date']} → ${payload['end_date']}';
          widgets.add(_payloadRow(Icons.calendar_today, 'Période', dateStr, color));
        }
        if (payload['replacement_note']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.swap_horiz, 'Remplacement', payload['replacement_note'], color));
        }
        break;

      case 'room_change':
        if (payload['subject']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.subject, 'Matière', payload['subject'], color));
        }
        if (payload['old_room']?.toString().isNotEmpty == true || payload['new_room']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.meeting_room, 'Salle', '${payload['old_room']} → ${payload['new_room']}', color));
        }
        if (payload['date_time']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.schedule, 'Quand', payload['date_time'], color));
        }
        break;

      case 'exam':
        if (payload['subject']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.subject, 'Matière', payload['subject'], color));
        }
        if (payload['date_time']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.event, 'Date/heure', payload['date_time'], color));
        }
        if (payload['room']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.meeting_room, 'Salle', payload['room'], color));
        }
        if (payload['instructions']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.info_outline, 'Instructions', payload['instructions'], color));
        }
        break;

      case 'closure':
        if (payload['reason']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.error_outline, 'Raison', payload['reason'], color));
        }
        if (payload['closed_from']?.toString().isNotEmpty == true || payload['closed_to']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.calendar_today, 'Période', '${payload['closed_from']} → ${payload['closed_to']}', color));
        }
        if (payload['reopen_date']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.event_available, 'Réouverture', payload['reopen_date'], color));
        }
        break;

      case 'reminder':
        if (payload['due_date']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.event, 'Échéance', payload['due_date'], color));
        }
        if (payload['action_required']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.checklist, 'Action requise', payload['action_required'], color));
        }
        break;

      default:
        break;
    }

    return widgets;
  }

  Widget _payloadRow(IconData icon, String label, String? value, Color color) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 10, color: Colors.black87),
                children: [
                  TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsPreview(ThemeData theme) {
    if (attachments.isEmpty && hasAttachment) {
      return Row(
        children: [
          Icon(Icons.attach_file, size: 12, color: theme.primaryColor),
          const SizedBox(width: 2),
          Text(attachmentName ?? 'Pièce jointe', style: TextStyle(fontSize: 10, color: theme.primaryColor)),
        ],
      );
    }

    final imageAttachments = attachments.where((a) => a.isImage).toList();
    final fileAttachments = attachments.where((a) => !a.isImage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageAttachments.isNotEmpty)
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageAttachments.length.clamp(0, 4),
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (_, i) => Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: imageAttachments[i].bytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(imageAttachments[i].bytes!, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.image, size: 20, color: Colors.grey),
              ),
            ),
          ),
        if (fileAttachments.isNotEmpty) ...[
          if (imageAttachments.isNotEmpty) const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: fileAttachments.take(2).map((f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getFileIcon(f.fileName), size: 10, color: Colors.grey.shade600),
                  const SizedBox(width: 2),
                  Text(
                    f.fileName.length > 12 ? '${f.fileName.substring(0, 10)}...' : f.fileName,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// HELPER CLASSES AND FUNCTIONS
// =============================================================================

/// Attachment preview data for composer dialog
class PreviewAttachment {
  final String fileName;
  final Uint8List? bytes;
  final String? mimeType;

  PreviewAttachment({required this.fileName, this.bytes, this.mimeType});

  bool get isImage => mimeType?.startsWith('image/') == true ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.gif') ||
      fileName.toLowerCase().endsWith('.webp');
}

/// Convert pending attachments to preview format
List<PreviewAttachment> toPreviewAttachments(List<dynamic> pendingAttachments) {
  return pendingAttachments.map((a) => PreviewAttachment(
    fileName: a.fileName as String,
    bytes: a.bytes as Uint8List?,
    mimeType: a.mimeType as String?,
  )).toList();
}

class _TypeInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _TypeInfo(this.label, this.icon, this.color);
}

_TypeInfo _getTypeInfo(String type) {
  switch (type) {
    case 'teacher_absent':
      return const _TypeInfo('Absence prof', Icons.person_off, Colors.orange);
    case 'room_change':
      return const _TypeInfo('Changement salle', Icons.meeting_room, Colors.blue);
    case 'exam':
      return const _TypeInfo('Examen', Icons.quiz, Colors.purple);
    case 'closure':
      return const _TypeInfo('Fermeture', Icons.lock, Colors.red);
    case 'reminder':
      return const _TypeInfo('Rappel', Icons.alarm, Colors.teal);
    default:
      return const _TypeInfo('Général', Icons.info, Colors.grey);
  }
}

IconData _getFileIcon(String fileName) {
  final ext = fileName.toLowerCase().split('.').last;
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'doc':
    case 'docx':
      return Icons.description;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart;
    case 'ppt':
    case 'pptx':
      return Icons.slideshow;
    case 'zip':
    case 'rar':
      return Icons.folder_zip;
    default:
      return Icons.insert_drive_file;
  }
}
