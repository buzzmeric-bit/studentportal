import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/announcement_model.dart';

// =====================================================
// REAL-TIME CLASS MESSAGES STATE NOTIFIER
// =====================================================

class MessagesState {
  final List<AnnouncementClassModel> messages;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  
  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });
  
  MessagesState copyWith({
    List<AnnouncementClassModel>? messages,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) => MessagesState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final Ref ref;
  final String? classId;
  RealtimeChannel? _subscription;
  
  MessagesNotifier(this.ref, this.classId) : super(const MessagesState(isLoading: true)) {
    _init();
  }
  
  Future<void> _init() async {
    await loadMessages();
    _setupRealtimeSubscription();
  }
  
  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;
    
    _subscription = supabase
      .channel('announcements_class_changes_${classId ?? 'all'}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'announcements_class',
        callback: (payload) {
          // Reload on any change
          loadMessages();
        },
      )
      .subscribe();
  }
  
  Future<void> loadMessages() async {
    try {
      state = state.copyWith(isLoading: state.messages.isEmpty);
      
      final supabase = Supabase.instance.client;
      
      var query = supabase.from('announcements_class').select().isFilter('deleted_at', null);
      if (classId != null && classId!.isNotEmpty) {
        query = query.eq('class_id', classId!);
      }
      
      final response = await query
          .order('is_pinned', ascending: false)
          .order('published_at', ascending: false);
      
      final messages = (response as List).map((e) => e as Map<String, dynamic>).toList();
      
      // Get all message IDs that have attachments
      final idsWithAttachment = messages
          .where((m) => m['has_attachment'] == true)
          .map((m) => m['id'] as String)
          .toList();
      
      // Fetch attachments for those messages
      Map<String, List<AnnouncementAttachment>> attachmentsMap = {};
      if (idsWithAttachment.isNotEmpty) {
        final attachmentsResponse = await supabase
            .from('announcement_attachments')
            .select()
            .eq('scope', 'class')
            .inFilter('announcement_id', idsWithAttachment);
        
        for (final att in (attachmentsResponse as List)) {
          final attachment = AnnouncementAttachment.fromJson(att);
          attachmentsMap.putIfAbsent(attachment.announcementId, () => []).add(attachment);
        }
      }
      
      final models = messages.map((e) {
        final id = e['id'] as String;
        return AnnouncementClassModel.fromJson(e, attachments: attachmentsMap[id] ?? []);
      }).toList();
      
      state = MessagesState(
        messages: models,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> refresh() async {
    await loadMessages();
  }
  
  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final messagesNotifierProvider = StateNotifierProvider.family<MessagesNotifier, MessagesState, String?>((ref, classId) {
  return MessagesNotifier(ref, classId);
});

// Type info helper class
class _TypeInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _TypeInfo(this.label, this.icon, this.color);
}

_TypeInfo _getTypeInfo(String type) {
  switch (type) {
    case 'teacher_absent':
      return _TypeInfo('Absence enseignant', Icons.person_off, Colors.orange);
    case 'room_change':
      return _TypeInfo('Changement salle', Icons.meeting_room, Colors.purple);
    case 'exam':
      return _TypeInfo('Examen', Icons.assignment, Colors.red);
    case 'closure':
      return _TypeInfo('Fermeture', Icons.cancel, Colors.grey);
    case 'reminder':
      return _TypeInfo('Rappel', Icons.alarm, Colors.blue);
    case 'trip':
      return _TypeInfo('Sortie/Voyage', Icons.directions_bus, Colors.green);
    case 'party':
      return _TypeInfo('Événement', Icons.celebration, Colors.pink);
    case 'payment':
      return _TypeInfo('Paiement', Icons.payment, Colors.indigo);
    default:
      return _TypeInfo('Général', Icons.campaign, Colors.teal);
  }
}

// Helper: normalize text for accent-insensitive search
String _normalizeForSearch(String text) {
  const accents = 'àâäéèêëïîôùûüçœæ';
  const normalized = 'aaaeeeeiioouuce';
  var result = text.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    result = result.replaceAll(accents[i], i < normalized.length ? normalized[i] : '');
  }
  return result;
}

class MessagesScreen extends ConsumerStatefulWidget {
  final String? classId; // Optional: filter by student's class
  
  const MessagesScreen({super.key, this.classId});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value.trim());
    });
  }

  bool _matchesSearch(AnnouncementClassModel a) {
    if (_searchQuery.isEmpty) return true;
    final normalized = _normalizeForSearch(_searchQuery);
    final tokens = normalized.split(RegExp(r'\s+'));
    final fields = _normalizeForSearch('${a.title} ${a.body} ${a.authorName ?? ''}');
    return tokens.every((t) => fields.contains(t));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(messagesNotifierProvider(widget.classId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.messages),
        backgroundColor: AppColors.tileMessages,
        foregroundColor: Colors.white,
        actions: [
          // Real-time indicator
          if (state.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: 'Dernière mise à jour: ${DateFormat('HH:mm:ss').format(state.lastUpdated!)}',
                child: const Icon(Icons.sync, size: 18),
              ),
            ),
          IconButton(
            icon: state.isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.refresh),
            onPressed: state.isLoading ? null : () => ref.read(messagesNotifierProvider(widget.classId).notifier).refresh(),
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _buildContent(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MessagesState state) {
    final l10n = AppLocalizations.of(context);
    
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null && state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSizes.paddingM),
            Text(l10n.error),
            const SizedBox(height: AppSizes.paddingS),
            Text(state.error!, style: const TextStyle(fontSize: 12)),
            TextButton(
              onPressed: () => ref.read(messagesNotifierProvider(widget.classId).notifier).refresh(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
    
    final filtered = state.messages.where(_matchesSearch).toList();
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: AppColors.textLight),
            const SizedBox(height: AppSizes.paddingM),
            Text(
              _searchQuery.isNotEmpty ? 'Aucun résultat' : l10n.noData,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(messagesNotifierProvider(widget.classId).notifier).refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _MessageCard(message: filtered[index]),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final AnnouncementClassModel message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.tileMessages.withValues(alpha: 0.2),
                    child: Text(
                      message.avatarText,
                      style: TextStyle(
                        color: AppColors.tileMessages,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                message.displaySenderName,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.tileMessages,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (message.isImportant) ...[
                              const SizedBox(width: AppSizes.paddingXS),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                                ),
                                child: const Text(
                                  'Important',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          dateFormat.format(message.publishedAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textLight,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingM),
              // Type badge
              if (message.announcementType != null && message.announcementType != 'general') ...[
                _buildTypeBadge(message.announcementType!),
                const SizedBox(height: AppSizes.paddingS),
              ],
              Text(
                message.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.paddingS),
              Text(
                message.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Type-specific payload fields
              if (message.payload != null && message.payload!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingS),
                _buildPayloadSection(context),
              ],
              // Display images inline like Facebook posts
              if (message.imageAttachments.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingM),
                _buildImageGallery(context, message.imageAttachments),
              ],
              // Show file attachments count
              if (message.fileAttachments.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingS),
                Row(
                  children: [
                    Icon(Icons.attach_file, size: AppSizes.iconXS, color: AppColors.primary),
                    const SizedBox(width: AppSizes.paddingXS),
                    Text(
                      '${message.fileAttachments.length} fichier(s) joint(s)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build Facebook-style image gallery for attachments
  Widget _buildImageGallery(BuildContext context, List<AnnouncementAttachment> images) {
    if (images.isEmpty) return const SizedBox.shrink();
    
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _showFullImage(context, images[0].fileUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          child: Image.network(
            images[0].fileUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
            ),
          ),
        ),
      );
    }
    
    // Multiple images - grid layout like Facebook
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            // First image (larger)
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _showImageGalleryViewer(context, images, 0),
                child: Image.network(
                  images[0].fileUrl,
                  fit: BoxFit.cover,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            // Second column with remaining images
            Expanded(
              child: Column(
                children: [
                  if (images.length > 1)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showImageGalleryViewer(context, images, 1),
                        child: Image.network(
                          images[1].fileUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    ),
                  if (images.length > 2) ...[
                    const SizedBox(height: 2),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showImageGalleryViewer(context, images, 2),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              images[2].fileUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.broken_image)),
                              ),
                            ),
                            if (images.length > 3)
                              Container(
                                color: Colors.black45,
                                child: Center(
                                  child: Text(
                                    '+${images.length - 3}',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageGalleryViewer(BuildContext context, List<AnnouncementAttachment> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: images.length,
                itemBuilder: (context, index) => InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      images[index].fileUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile(String url, String fileName) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildTypeBadge(String type) {
    final info = _getTypeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusXS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 14, color: info.color),
          const SizedBox(width: 4),
          Text(info.label, style: TextStyle(fontSize: 11, color: info.color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPayloadSection(BuildContext context) {
    if (message.payload == null || message.payload!.isEmpty) return const SizedBox.shrink();
    
    final type = message.announcementType;
    final payload = message.payload!;
    final info = type != null ? _getTypeInfo(type) : _TypeInfo('Autre', Icons.info, Colors.grey);
    final color = info.color;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildPayloadFields(payload, type, color),
      ),
    );
  }

  List<Widget> _buildPayloadFields(Map<String, dynamic> payload, String? type, Color color) {
    final widgets = <Widget>[];

    switch (type) {
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
        // Support both old date_time and new change_date/change_time fields
        if (payload['change_date']?.toString().isNotEmpty == true) {
          final dateStr = payload['change_time']?.toString().isNotEmpty == true
              ? '${payload['change_date']} à ${payload['change_time']}'
              : payload['change_date'];
          widgets.add(_payloadRow(Icons.schedule, 'Quand', dateStr, color));
        } else if (payload['date_time']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.schedule, 'Quand', payload['date_time'], color));
        }
        break;

      case 'exam':
        if (payload['subject']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.subject, 'Matière', payload['subject'], color));
        }
        // Support both old date_time and new exam_date/exam_time fields
        if (payload['exam_date']?.toString().isNotEmpty == true) {
          final dateStr = payload['exam_time']?.toString().isNotEmpty == true
              ? '${payload['exam_date']} à ${payload['exam_time']}'
              : payload['exam_date'];
          widgets.add(_payloadRow(Icons.event, 'Date/heure', dateStr, color));
        } else if (payload['date_time']?.toString().isNotEmpty == true) {
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

      case 'trip':
        if (payload['destination']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.place, 'Destination', payload['destination'], color));
        }
        if (payload['departure_date']?.toString().isNotEmpty == true) {
          final dateStr = payload['departure_time']?.toString().isNotEmpty == true
              ? '${payload['departure_date']} à ${payload['departure_time']}'
              : payload['departure_date'];
          widgets.add(_payloadRow(Icons.flight_takeoff, 'Départ', dateStr, color));
        }
        if (payload['return_date']?.toString().isNotEmpty == true) {
          final dateStr = payload['return_time']?.toString().isNotEmpty == true
              ? '${payload['return_date']} à ${payload['return_time']}'
              : payload['return_date'];
          widgets.add(_payloadRow(Icons.flight_land, 'Retour', dateStr, color));
        }
        if (payload['meeting_point']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.location_on, 'Rendez-vous', payload['meeting_point'], color));
        }
        if (payload['cost']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.attach_money, 'Coût', payload['cost'], color));
        }
        if (payload['notes']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.notes, 'Notes', payload['notes'], color));
        }
        break;

      case 'party':
        if (payload['event_name']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.event, 'Événement', payload['event_name'], color));
        }
        if (payload['event_date']?.toString().isNotEmpty == true) {
          final dateStr = payload['event_time']?.toString().isNotEmpty == true
              ? '${payload['event_date']} à ${payload['event_time']}'
              : payload['event_date'];
          widgets.add(_payloadRow(Icons.calendar_today, 'Date', dateStr, color));
        }
        if (payload['location']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.location_on, 'Lieu', payload['location'], color));
        }
        if (payload['dress_code']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.checkroom, 'Tenue', payload['dress_code'], color));
        }
        if (payload['notes']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.notes, 'Notes', payload['notes'], color));
        }
        break;

      case 'payment':
        final paymentTypeLabels = {
          'frais_scolarite': 'Frais de scolarité',
          'frais_inscription': 'Frais d\'inscription',
          'frais_sortie': 'Frais de sortie',
          'frais_materiel': 'Frais de matériel',
          'cotisation': 'Cotisation',
          'autre': 'Autre',
        };
        if (payload['payment_type']?.toString().isNotEmpty == true) {
          final typeLabel = paymentTypeLabels[payload['payment_type']] ?? payload['payment_type'];
          widgets.add(_payloadRow(Icons.category, 'Type', typeLabel, color));
        }
        if (payload['amount']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.attach_money, 'Montant', payload['amount'], color));
        }
        if (payload['due_date']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.event, 'Date limite', payload['due_date'], color));
        }
        if (payload['payment_method']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.credit_card, 'Mode de paiement', payload['payment_method'], color));
        }
        if (payload['notes']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.notes, 'Notes', payload['notes'], color));
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87),
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

  void _showDetail(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingL),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header with sender, date, badges (Facebook-style)
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.tileMessages.withValues(alpha: 0.2),
                    child: Text(
                      message.avatarText,
                      style: TextStyle(
                        color: AppColors.tileMessages,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                message.displaySenderName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (message.isImportant) ...[
                              const SizedBox(width: AppSizes.paddingS),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                                ),
                                child: const Text(
                                  'Important',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          dateFormat.format(message.publishedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingL),
              // Type badge in detail view
              if (message.announcementType != null && message.announcementType != 'general') ...[
                _buildTypeBadge(message.announcementType!),
                const SizedBox(height: AppSizes.paddingM),
              ],
              Text(
                message.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Divider(height: AppSizes.paddingXL),
              // Type-specific payload fields in detail
              if (message.payload != null && message.payload!.isNotEmpty) ...[
                _buildPayloadSection(context),
                const SizedBox(height: AppSizes.paddingM),
              ],
              Text(
                message.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
              ),
              // Images in detail view
              if (message.imageAttachments.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingL),
                _buildDetailImageGallery(context, message.imageAttachments),
              ],
              // File attachments in detail view
              if (message.fileAttachments.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingL),
                const Text('Fichiers joints:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.paddingS),
                ...message.fileAttachments.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadFile(f.fileUrl, f.fileName),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(f.fileName, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Detail view image gallery - larger images
  Widget _buildDetailImageGallery(BuildContext context, List<AnnouncementAttachment> images) {
    return Column(
      children: images.asMap().entries.map((entry) {
        final index = entry.key;
        final image = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
          child: GestureDetector(
            onTap: () => _showImageGalleryViewer(context, images, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              child: Image.network(
                image.fileUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
