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
// REAL-TIME ANNOUNCEMENT STATE NOTIFIER
// =====================================================

class NoteInfoState {
  final List<AnnouncementGlobalModel> announcements;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  
  const NoteInfoState({
    this.announcements = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });
  
  NoteInfoState copyWith({
    List<AnnouncementGlobalModel>? announcements,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) => NoteInfoState(
    announcements: announcements ?? this.announcements,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

class NoteInfoNotifier extends StateNotifier<NoteInfoState> {
  final Ref ref;
  RealtimeChannel? _subscription;
  
  NoteInfoNotifier(this.ref) : super(const NoteInfoState(isLoading: true)) {
    _init();
  }
  
  Future<void> _init() async {
    await loadAnnouncements();
    _setupRealtimeSubscription();
  }
  
  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;
    
    _subscription = supabase
      .channel('announcements_global_changes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'announcements_global',
        callback: (payload) {
          // Reload on any change (INSERT, UPDATE, DELETE)
          loadAnnouncements();
        },
      )
      .subscribe();
  }
  
  Future<void> loadAnnouncements() async {
    try {
      state = state.copyWith(isLoading: state.announcements.isEmpty);
      
      final supabase = Supabase.instance.client;
      
      // Fetch announcements (only non-deleted)
      final response = await supabase
          .from('announcements_global')
          .select()
          .isFilter('deleted_at', null)
          .order('is_pinned', ascending: false)
          .order('published_at', ascending: false);
      
      final announcements = (response as List).map((e) => e as Map<String, dynamic>).toList();
      
      // Get all announcement IDs that have attachments
      final idsWithAttachment = announcements
          .where((a) => a['has_attachment'] == true)
          .map((a) => a['id'] as String)
          .toList();
      
      // Fetch attachments for those announcements
      Map<String, List<AnnouncementAttachment>> attachmentsMap = {};
      if (idsWithAttachment.isNotEmpty) {
        final attachmentsResponse = await supabase
            .from('announcement_attachments')
            .select()
            .eq('scope', 'global')
            .inFilter('announcement_id', idsWithAttachment);
        
        for (final att in (attachmentsResponse as List)) {
          final attachment = AnnouncementAttachment.fromJson(att);
          attachmentsMap.putIfAbsent(attachment.announcementId, () => []).add(attachment);
        }
      }
      
      final models = announcements.map((e) {
        final id = e['id'] as String;
        return AnnouncementGlobalModel.fromJson(e, attachments: attachmentsMap[id] ?? []);
      }).toList();
      
      state = NoteInfoState(
        announcements: models,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> refresh() async {
    await loadAnnouncements();
  }
  
  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final noteInfoNotifierProvider = StateNotifierProvider<NoteInfoNotifier, NoteInfoState>((ref) {
  return NoteInfoNotifier(ref);
});

// Legacy provider for backwards compatibility (now uses StateNotifier internally)
final noteInfoProvider = FutureProvider<List<AnnouncementGlobalModel>>((ref) async {
  final state = ref.watch(noteInfoNotifierProvider);
  if (state.error != null) throw Exception(state.error);
  return state.announcements;
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
  const accents = 'àâäéèêëïîôùûüçœæÀÂÄÉÈÊËÏÎÔÙÛÜÇŒÆ';
  const normalized = 'aaaeeeeiioouuceAAÀEEEEIIOOUUCE';
  var result = text.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    result = result.replaceAll(accents[i], i < normalized.length ? normalized[i].toLowerCase() : '');
  }
  return result;
}

/// Get all searchable fields for an announcement (including formatted dates)
String _getSearchableFields(AnnouncementGlobalModel a) {
  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm EEEE MMMM', 'fr_FR');
  final timeFormatter = DateFormat('HH:mm', 'fr_FR');
  
  // Type labels mapping
  String typeLabel;
  switch (a.announcementType ?? 'general') {
    case 'teacher_absent': typeLabel = 'absence prof enseignant'; break;
    case 'room_change': typeLabel = 'changement salle'; break;
    case 'reminder': typeLabel = 'rappel'; break;
    case 'exam': typeLabel = 'examen controle test'; break;
    case 'closure': typeLabel = 'fermeture fermé'; break;
    default: typeLabel = 'général general';
  }
  
  // Build all searchable text
  final fields = [
    a.title,
    a.body,
    a.senderLabel ?? '',
    typeLabel,
    'note info global',
    dateFormatter.format(a.publishedAt),
    timeFormatter.format(a.publishedAt),
    a.isImportant ? 'important urgent' : '',
    a.hasAttachment ? 'pièce jointe fichier attachment image photo' : '',
  ];
  
  // Add payload fields if available
  if (a.payload != null) {
    a.payload!.forEach((key, value) {
      if (value != null) fields.add(value.toString());
    });
  }
  
  return fields.join(' ');
}

/// Highlight matching text in a string
class _MatchRange {
  int start;
  int end;
  _MatchRange(this.start, this.end);
}

Widget _highlightText(String text, String query, TextStyle? baseStyle, {int maxLines = 2}) {
  if (query.isEmpty) return Text(text, style: baseStyle, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  
  final normalizedText = _normalizeForSearch(text);
  final normalizedQuery = _normalizeForSearch(query);
  final tokens = normalizedQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  
  if (tokens.isEmpty) return Text(text, style: baseStyle, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  
  // Find all match positions
  List<_MatchRange> matches = [];
  for (final token in tokens) {
    int start = 0;
    while (true) {
      final index = normalizedText.indexOf(token, start);
      if (index == -1) break;
      matches.add(_MatchRange(index, index + token.length));
      start = index + 1;
    }
  }
  
  if (matches.isEmpty) return Text(text, style: baseStyle, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  
  // Sort and merge overlapping ranges
  matches.sort((a, b) => a.start.compareTo(b.start));
  List<_MatchRange> merged = [];
  for (final m in matches) {
    if (merged.isEmpty || merged.last.end < m.start) {
      merged.add(m);
    } else {
      merged.last = _MatchRange(merged.last.start, m.end > merged.last.end ? m.end : merged.last.end);
    }
  }
  
  // Build text spans
  List<TextSpan> spans = [];
  int lastEnd = 0;
  for (final m in merged) {
    if (m.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, m.start), style: baseStyle));
    }
    spans.add(TextSpan(
      text: text.substring(m.start, m.end),
      style: baseStyle?.copyWith(backgroundColor: Colors.yellow.shade200, fontWeight: FontWeight.bold) ?? 
             TextStyle(backgroundColor: Colors.yellow.shade200, fontWeight: FontWeight.bold),
    ));
    lastEnd = m.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
  }
  
  return RichText(text: TextSpan(children: spans), maxLines: maxLines, overflow: TextOverflow.ellipsis);
}

class NoteInfoScreen extends ConsumerStatefulWidget {
  const NoteInfoScreen({super.key});

  @override
  ConsumerState<NoteInfoScreen> createState() => _NoteInfoScreenState();
}

class _NoteInfoScreenState extends ConsumerState<NoteInfoScreen> {
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

  bool _matchesSearch(AnnouncementGlobalModel a) {
    if (_searchQuery.isEmpty) return true;
    final normalizedQuery = _normalizeForSearch(_searchQuery);
    final tokens = normalizedQuery.split(RegExp(r'\s+'));
    final searchableFields = _normalizeForSearch(_getSearchableFields(a));
    return tokens.every((t) => searchableFields.contains(t));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(noteInfoNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.noteInfo),
        backgroundColor: AppColors.tileNoteInfo,
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
            onPressed: state.isLoading ? null : () => ref.read(noteInfoNotifierProvider.notifier).refresh(),
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
                hintText: 'Rechercher (type, date, contenu...)',
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

  Widget _buildContent(BuildContext context, NoteInfoState state) {
    final l10n = AppLocalizations.of(context);
    
    if (state.isLoading && state.announcements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null && state.announcements.isEmpty) {
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
              onPressed: () => ref.read(noteInfoNotifierProvider.notifier).refresh(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
    
    final filtered = state.announcements.where(_matchesSearch).toList();
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: AppColors.textLight),
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
      onRefresh: () => ref.read(noteInfoNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _AnnouncementCard(announcement: filtered[index], searchQuery: _searchQuery),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementGlobalModel announcement;
  final String searchQuery;

  const _AnnouncementCard({required this.announcement, this.searchQuery = ''});

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
                  if (announcement.isImportant)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingS,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(right: AppSizes.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                      ),
                      child: const Text(
                        'Important',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.fontXS,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (announcement.announcementType != null && announcement.announcementType != 'general') ...[
                    _buildTypeBadge(announcement.announcementType!),
                    const SizedBox(width: AppSizes.paddingS),
                  ],
                  Expanded(
                    child: searchQuery.isNotEmpty
                      ? _highlightText(
                          announcement.title.isNotEmpty ? announcement.title : _getTypeInfo(announcement.announcementType ?? 'general').label,
                          searchQuery,
                          Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                        )
                      : Text(
                          announcement.title.isNotEmpty ? announcement.title : _getTypeInfo(announcement.announcementType ?? 'general').label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingS),
              // Body text with small image thumbnail at end
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: searchQuery.isNotEmpty
                      ? _highlightText(announcement.body, searchQuery, Theme.of(context).textTheme.bodyMedium, maxLines: 3)
                      : Text(
                          announcement.body,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                  // Small image thumbnail at end of body
                  if (announcement.imageAttachments.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _showFullImage(context, announcement.imageAttachments.first.fileUrl),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                announcement.imageAttachments.first.fileUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Show image count badge if multiple
                              if (announcement.imageAttachments.length > 1)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+${announcement.imageAttachments.length - 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Type-specific payload fields
              if (announcement.payload != null && announcement.payload!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingS),
                _buildPayloadSection(context),
              ],
              // Show file attachments count
              if (announcement.fileAttachments.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingS),
                Row(
                  children: [
                    Icon(Icons.attach_file, size: AppSizes.iconXS, color: AppColors.primary),
                    const SizedBox(width: AppSizes.paddingXS),
                    Text(
                      '${announcement.fileAttachments.length} fichier(s) joint(s)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSizes.paddingM),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: AppSizes.iconXS,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: AppSizes.paddingXS),
                  Text(
                    dateFormat.format(announcement.publishedAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textLight,
                        ),
                  ),
                ],
              ),
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
    
    // Multiple images: grid layout
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            // First image takes half width
            Expanded(
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
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

  /// Show full-screen image gallery viewer with page navigation
  void _showImageGalleryViewer(BuildContext context, List<AnnouncementAttachment> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black87),
            ),
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
            // Page indicator
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${initialIndex + 1} / ${images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    if (announcement.payload == null || announcement.payload!.isEmpty) return const SizedBox.shrink();
    
    final type = announcement.announcementType;
    final payload = announcement.payload!;
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
        // Date range
        if (payload['start_date']?.toString().isNotEmpty == true || payload['end_date']?.toString().isNotEmpty == true) {
          final startDate = payload['start_date']?.toString() ?? '';
          final endDate = payload['end_date']?.toString() ?? '';
          final dateStr = startDate == endDate || endDate.isEmpty
              ? startDate
              : '$startDate → $endDate';
          widgets.add(_payloadRow(Icons.calendar_today, 'Période', dateStr, color));
        }
        // Time range
        if (payload['start_time']?.toString().isNotEmpty == true || payload['end_time']?.toString().isNotEmpty == true) {
          final startTime = payload['start_time']?.toString() ?? '';
          final endTime = payload['end_time']?.toString() ?? '';
          String timeStr;
          if (startTime.isNotEmpty && endTime.isNotEmpty) {
            timeStr = 'de $startTime à $endTime';
          } else if (startTime.isNotEmpty) {
            timeStr = 'à partir de $startTime';
          } else {
            timeStr = 'jusqu\'à $endTime';
          }
          widgets.add(_payloadRow(Icons.access_time, 'Horaire', timeStr, color));
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
        // Separate date and time
        if (payload['change_date']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.calendar_today, 'Date', payload['change_date'], color));
        }
        if (payload['change_time']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.access_time, 'Heure', payload['change_time'], color));
        }
        break;

      case 'exam':
        if (payload['subject']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.subject, 'Matière', payload['subject'], color));
        }
        // Separate date and time
        if (payload['exam_date']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.calendar_today, 'Date', payload['exam_date'], color));
        }
        if (payload['exam_time']?.toString().isNotEmpty == true) {
          widgets.add(_payloadRow(Icons.access_time, 'Heure', payload['exam_time'], color));
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
              if (announcement.isImportant)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingS,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                  ),
                  child: const Text(
                    'Important',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppSizes.fontS,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // Type badge in detail
              if (announcement.announcementType != null && announcement.announcementType != 'general') ...[
                _buildTypeBadge(announcement.announcementType!),
                const SizedBox(height: AppSizes.paddingS),
              ],
              Text(
                announcement.title.isNotEmpty ? announcement.title : _getTypeInfo(announcement.announcementType ?? 'general').label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: AppSizes.iconS,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.paddingXS),
                  Text(
                    dateFormat.format(announcement.publishedAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const Divider(height: AppSizes.paddingXL),
              // Type-specific payload in detail
              if (announcement.payload != null && announcement.payload!.isNotEmpty) ...[
                _buildPayloadSection(context),
                const SizedBox(height: AppSizes.paddingM),
              ],
              Text(
                announcement.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
              ),
              // Display images in detail view
              if (announcement.imageAttachments.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingL),
                _buildDetailImageGallery(context, announcement.imageAttachments),
              ],
              // File attachments download buttons
              if (announcement.fileAttachments.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingL),
                const Text('Pièces jointes', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.paddingS),
                ...announcement.fileAttachments.map((att) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadFile(att.fileUrl, att.fileName),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(att.fileName, overflow: TextOverflow.ellipsis),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build image gallery for detail view with larger images
  Widget _buildDetailImageGallery(BuildContext context, List<AnnouncementAttachment> images) {
    return Column(
      children: images.map((img) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
        child: GestureDetector(
          onTap: () => _showFullImage(context, img.fileUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: Image.network(
              img.fileUrl,
              fit: BoxFit.cover,
              width: double.infinity,
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
        ),
      )).toList(),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black87),
            ),
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.white,
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
    );
  }

  void _downloadFile(String url, String fileName) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Cannot launch URL: $url');
    }
  }
}
