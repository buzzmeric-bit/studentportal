import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/suggestion_model.dart';

// Search query provider
final suggestionsSearchProvider = StateProvider<String>((ref) => '');

// =====================================================
// SUGGESTIONS STATE NOTIFIER WITH REAL SUPABASE
// =====================================================

class StudentSuggestionsState {
  final List<SuggestionModel> suggestions;
  final bool isLoading;
  final String? error;
  
  const StudentSuggestionsState({
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });
  
  StudentSuggestionsState copyWith({
    List<SuggestionModel>? suggestions,
    bool? isLoading,
    String? error,
  }) => StudentSuggestionsState(
    suggestions: suggestions ?? this.suggestions,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class StudentSuggestionsNotifier extends StateNotifier<StudentSuggestionsState> {
  final Ref ref;
  
  StudentSuggestionsNotifier(this.ref) : super(const StudentSuggestionsState(isLoading: true)) {
    loadSuggestions();
  }
  
  Future<void> loadSuggestions() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        state = state.copyWith(isLoading: false, suggestions: []);
        return;
      }
      
      // Fetch suggestions for this student - basic query first
      List<Map<String, dynamic>> suggestions;
      try {
        // Try with replies relation
        final response = await supabase
            .from('suggestions')
            .select('*, suggestion_replies(*)')
            .eq('student_id', user.id)
            .order('created_at', ascending: false);
        suggestions = (response as List).map((e) => e as Map<String, dynamic>).toList();
      } catch (_) {
        // Fallback: basic query without relations
        final response = await supabase
            .from('suggestions')
            .select()
            .eq('student_id', user.id)
            .order('created_at', ascending: false);
        suggestions = (response as List).map((e) => e as Map<String, dynamic>).toList();
      }
      
      // Fetch attachments for ALL suggestions (don't rely on has_attachment flag which may not be set)
      Map<String, List<SuggestionAttachment>> attachmentsMap = {};
      try {
        final allIds = suggestions.map((s) => s['id'] as String).toList();
        
        if (allIds.isNotEmpty) {
          final attachmentsResponse = await supabase
              .from('suggestion_attachments')
              .select()
              .inFilter('suggestion_id', allIds);
          
          for (final att in (attachmentsResponse as List)) {
            final attachment = SuggestionAttachment.fromJson(att);
            attachmentsMap.putIfAbsent(attachment.suggestionId, () => []).add(attachment);
          }
        }
      } catch (_) {
        // suggestion_attachments table might not exist yet
      }
      
      final models = suggestions.map((e) {
        final id = e['id'] as String;
        return SuggestionModel.fromJson(e, attachments: attachmentsMap[id] ?? []);
      }).toList();
      
      state = StudentSuggestionsState(suggestions: models, isLoading: false);
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  /// Submit suggestion with file bytes (works on web and mobile)
  Future<bool> submitSuggestionWithBytes({
    required String subject,
    required String body,
    required SuggestionType type,
    List<dynamic>? attachments, // _AttachmentFile objects
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) throw Exception('Non connecté');
      
      // Get student profile info
      final profile = await supabase
          .from('users')
          .select('full_name, school_id')
          .eq('id', user.id)
          .maybeSingle();
      
      // Get enrollment info if available
      Map<String, dynamic>? enrollment;
      try {
        enrollment = await supabase
            .from('enrollments')
            .select('id, class_id, student_code, classes(name, level)')
            .eq('student_id', user.id)
            .eq('is_active', true)
            .maybeSingle();
      } catch (_) {}
      
      // Check if we have attachments to upload and determine bucket
      final hasValidAttachments = attachments != null && attachments.isNotEmpty;
      String? storageBucket;
      
      if (hasValidAttachments) {
        // Try to find an available storage bucket
        try {
          final buckets = await supabase.storage.listBuckets();
          final bucketNames = buckets.map((b) => b.name).toList();
          
          // Try bucket names in order of preference
          if (bucketNames.contains('suggestions')) {
            storageBucket = 'suggestions';
          } else if (bucketNames.contains('suggestion-attachments')) {
            storageBucket = 'suggestion-attachments';
          } else if (bucketNames.contains('announcement-attachments')) {
            storageBucket = 'announcement-attachments';
          } else if (bucketNames.contains('attachments')) {
            storageBucket = 'attachments';
          } else {
            // Try 'suggestions' as default
            storageBucket = 'suggestions';
          }
        } catch (_) {
          // If bucket check fails, try default
          storageBucket = 'suggestions';
        }
      }
      
      // Basic suggestion data (original schema: student_id, subject, message, status='sent')
      final basicData = {
        'student_id': user.id,
        'subject': subject,
        'message': body,
        'status': 'sent',  // Original enum: sent, read, replied
      };
      
      // Extended data (requires migration - also uses 'sent' status since enum is fixed)
      final extendedData = {
        'student_id': user.id,
        'subject': subject,
        'message': body,
        'body': body,
        'content': body,
        'status': 'sent',
        'suggestion_type': _typeToString(type),
        'student_name': profile?['full_name'],
        'school_id': profile?['school_id'],
        'has_attachment': hasValidAttachments && storageBucket != null,
      };
      
      if (enrollment != null) {
        extendedData['enrollment_id'] = enrollment['id'];
        extendedData['class_id'] = enrollment['class_id'];
        extendedData['student_code'] = enrollment['student_code'];
        if (enrollment['classes'] != null) {
          final cls = enrollment['classes'];
          extendedData['class_name'] = '${cls['level'] ?? ''} ${cls['name'] ?? ''}'.trim();
        }
      }
      
      // Try EXTENDED data first (with type, attachment flags, etc.), then basic fallback
      Map<String, dynamic> insertResponse;
      try {
        insertResponse = await supabase
            .from('suggestions')
            .insert(extendedData)
            .select()
            .single();
        debugPrint('Extended insert succeeded with suggestion_type');
      } catch (extendedError) {
        // Extended failed (columns might not exist), try basic data
        debugPrint('Extended insert failed, trying basic: $extendedError');
        try {
          insertResponse = await supabase
              .from('suggestions')
              .insert(basicData)
              .select()
              .single();
          debugPrint('Basic insert succeeded');
        } catch (basicError) {
          debugPrint('Basic insert also failed: $basicError');
          rethrow;
        }
      }
      
      final suggestionId = insertResponse['id'] as String;
      
      // Upload attachments (using bytes directly)
      if (hasValidAttachments && storageBucket != null) {
        for (final file in attachments!) {
          try {
            final bytes = file.bytes as Uint8List;
            final fileName = file.name as String;
            final mimeType = file.mimeType as String?;
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final storagePath = 'suggestions/$suggestionId/${timestamp}_$fileName';
            
            // Upload to storage
            await supabase.storage.from(storageBucket).uploadBinary(
              storagePath, 
              bytes,
              fileOptions: FileOptions(contentType: mimeType),
            );
            
            // Get public URL
            final publicUrl = supabase.storage.from(storageBucket).getPublicUrl(storagePath);
            
            // Insert attachment record
            await supabase.from('suggestion_attachments').insert({
              'suggestion_id': suggestionId,
              'file_url': publicUrl,
              'file_name': fileName,
              'file_type': mimeType,
              'file_size': bytes.length,
            });
          } catch (uploadError) {
            // Continue even if individual file upload fails
            debugPrint('Failed to upload attachment: $uploadError');
          }
        }
      }
      
      // Reload suggestions
      await loadSuggestions();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
  
  Future<bool> submitSuggestion({
    required String subject,
    required String body,
    required SuggestionType type,
    List<XFile>? attachments,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) throw Exception('Non connecté');
      
      // Get student profile info
      final profile = await supabase
          .from('users')
          .select('full_name, school_id')
          .eq('id', user.id)
          .maybeSingle();
      
      // Get enrollment info if available
      Map<String, dynamic>? enrollment;
      try {
        enrollment = await supabase
            .from('enrollments')
            .select('id, class_id, student_code, classes(name, level)')
            .eq('student_id', user.id)
            .eq('is_active', true)
            .maybeSingle();
      } catch (_) {}
      
      // Basic suggestion data (original schema: student_id, subject, message, status='sent')
      final basicData = {
        'student_id': user.id,
        'subject': subject,
        'message': body,
        'status': 'sent',  // Original enum: sent, read, replied
      };
      
      // Extended data (requires migration - also uses 'sent' status)
      final extendedData = {
        'student_id': user.id,
        'subject': subject,
        'message': body,
        'body': body,
        'content': body,
        'status': 'sent',
        'suggestion_type': _typeToString(type),
        'student_name': profile?['full_name'],
        'school_id': profile?['school_id'],
        'has_attachment': attachments?.isNotEmpty ?? false,
      };
      
      if (enrollment != null) {
        extendedData['enrollment_id'] = enrollment['id'];
        extendedData['class_id'] = enrollment['class_id'];
        extendedData['student_code'] = enrollment['student_code'];
        if (enrollment['classes'] != null) {
          final cls = enrollment['classes'];
          extendedData['class_name'] = '${cls['level'] ?? ''} ${cls['name'] ?? ''}'.trim();
        }
      }
      
      // Try EXTENDED data first (with type, attachment flags, etc.), then basic fallback
      Map<String, dynamic> insertResponse;
      try {
        insertResponse = await supabase
            .from('suggestions')
            .insert(extendedData)
            .select()
            .single();
        debugPrint('Extended insert succeeded with suggestion_type');
      } catch (extendedError) {
        // Extended failed (columns might not exist), try basic data
        debugPrint('Extended insert failed, trying basic: $extendedError');
        try {
          insertResponse = await supabase
              .from('suggestions')
              .insert(basicData)
              .select()
              .single();
          debugPrint('Basic insert succeeded');
        } catch (basicError) {
          debugPrint('Basic insert also failed: $basicError');
          rethrow;
        }
      }
      
      final suggestionId = insertResponse['id'] as String;
      
      // Upload attachments (with error handling for missing bucket/table)
      if (attachments != null && attachments.isNotEmpty) {
        for (final file in attachments) {
          try {
            final bytes = await file.readAsBytes();
            final fileName = file.name;
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final storagePath = '$suggestionId/${timestamp}_$fileName';
            
            // Upload to storage (bucket: suggestion-attachments)
            await supabase.storage.from('suggestion-attachments').uploadBinary(storagePath, bytes);
            
            // Get public URL
            final publicUrl = supabase.storage.from('suggestion-attachments').getPublicUrl(storagePath);
            
            // Insert attachment record
            await supabase.from('suggestion_attachments').insert({
              'suggestion_id': suggestionId,
              'file_url': publicUrl,
              'file_name': fileName,
              'file_type': file.mimeType,
              'file_size': bytes.length,
            });
          } catch (uploadError) {
            // Continue even if attachment upload fails (bucket/table might not exist)
            debugPrint('Failed to upload attachment: $uploadError');
          }
        }
      }
      
      // Reload suggestions
      await loadSuggestions();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
  
  String _typeToString(SuggestionType type) {
    switch (type) {
      case SuggestionType.reclamationNote:
        return 'reclamation_note';
      case SuggestionType.absence:
        return 'absence';
      case SuggestionType.paiement:
        return 'paiement';
      case SuggestionType.emploiTemps:
        return 'emploi_temps';
      case SuggestionType.vieScolaire:
        return 'vie_scolaire';
      case SuggestionType.autre:
        return 'autre';
      default:
        return 'general';
    }
  }
}

final studentSuggestionsProvider = StateNotifierProvider<StudentSuggestionsNotifier, StudentSuggestionsState>((ref) {
  return StudentSuggestionsNotifier(ref);
});

class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final suggestionsState = ref.watch(studentSuggestionsProvider);
    final searchQuery = ref.watch(suggestionsSearchProvider);

    // Filter suggestions by search
    final filteredSuggestions = searchQuery.isEmpty
        ? suggestionsState.suggestions
        : suggestionsState.suggestions.where((s) {
            final query = searchQuery.toLowerCase();
            return s.subject.toLowerCase().contains(query) ||
                s.body.toLowerCase().contains(query) ||
                s.typeLabel.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.suggestions),
        backgroundColor: AppColors.tileSuggestions,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: suggestionsState.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.refresh),
            onPressed: suggestionsState.isLoading 
              ? null 
              : () => ref.read(studentSuggestionsProvider.notifier).loadSuggestions(),
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
              onChanged: (value) => ref.read(suggestionsSearchProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: '${l10n.search}...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref.read(suggestionsSearchProvider.notifier).state = '',
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _SuggestionsList(
              state: suggestionsState,
              suggestions: filteredSuggestions,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewSuggestionDialog(context, ref),
        backgroundColor: AppColors.tileSuggestions,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          l10n.newSuggestion,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showNewSuggestionDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
          ),
          child: _NewSuggestionForm(scrollController: scrollController),
        ),
      ),
    );
  }
}

class _SuggestionsList extends ConsumerWidget {
  final StudentSuggestionsState state;
  final List<SuggestionModel> suggestions;

  const _SuggestionsList({required this.state, required this.suggestions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    if (state.isLoading && state.suggestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null && state.suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSizes.paddingM),
            Text(l10n.error),
            TextButton(
              onPressed: () => ref.read(studentSuggestionsProvider.notifier).loadSuggestions(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
    
    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppSizes.paddingM),
            Text(
              state.suggestions.isEmpty ? l10n.noData : 'Aucun résultat',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(studentSuggestionsProvider.notifier).loadSuggestions(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return _SuggestionCard(suggestion: suggestion);
        },
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final SuggestionModel suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (suggestion.status) {
      case SuggestionStatus.pending:
        statusColor = Colors.orange;
        statusText = l10n.pending;
        statusIcon = Icons.hourglass_empty;
        break;
      case SuggestionStatus.inReview:
        statusColor = AppColors.info;
        statusText = l10n.inReview;
        statusIcon = Icons.visibility;
        break;
      case SuggestionStatus.replied:
        statusColor = AppColors.success;
        statusText = l10n.replied;
        statusIcon = Icons.check_circle;
        break;
      case SuggestionStatus.closed:
        statusColor = AppColors.textLight;
        statusText = l10n.closed;
        statusIcon = Icons.archive;
        break;
    }

    // Get image attachments for preview
    final imageAttachments = suggestion.attachments.where((a) =>
        a.fileType?.startsWith('image/') == true ||
        a.fileName.toLowerCase().endsWith('.jpg') ||
        a.fileName.toLowerCase().endsWith('.jpeg') ||
        a.fileName.toLowerCase().endsWith('.png') ||
        a.fileName.toLowerCase().endsWith('.gif')).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview if has images
            if (imageAttachments.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.cardBorderRadius)),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: imageAttachments.length == 1
                      ? Image.network(
                          imageAttachments.first.fileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageAttachments.length,
                          itemBuilder: (context, index) => Container(
                            width: 150,
                            margin: EdgeInsets.only(right: index < imageAttachments.length - 1 ? 2 : 0),
                            child: Image.network(
                              imageAttachments[index].fileUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tileSuggestions.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          suggestion.typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.tileSuggestions,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingS,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: AppSizes.fontXS,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                  Text(
                    suggestion.subject,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.paddingXS),
                  Text(
                    suggestion.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: AppSizes.iconXS,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: AppSizes.paddingXS),
                      Text(
                        dateFormat.format(suggestion.submittedAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textLight,
                            ),
                      ),
                      if (suggestion.attachments.isNotEmpty) ...[
                        const SizedBox(width: AppSizes.paddingM),
                        Icon(Icons.attach_file, size: AppSizes.iconXS, color: AppColors.textLight),
                        const SizedBox(width: 2),
                        Text(
                          '${suggestion.attachments.length}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textLight),
                        ),
                      ],
                      if (suggestion.replies.isNotEmpty) ...[
                        const Spacer(),
                        Icon(
                          Icons.reply,
                          size: AppSizes.iconXS,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSizes.paddingXS),
                        Text(
                          '${suggestion.replies.length} ${l10n.reply}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    // Separate images and documents
    final imageAttachments = suggestion.attachments.where((a) =>
        a.fileType?.startsWith('image/') == true ||
        a.fileName.toLowerCase().endsWith('.jpg') ||
        a.fileName.toLowerCase().endsWith('.jpeg') ||
        a.fileName.toLowerCase().endsWith('.png') ||
        a.fileName.toLowerCase().endsWith('.gif')).toList();
    
    final docAttachments = suggestion.attachments.where((a) =>
        a.fileType?.startsWith('image/') != true &&
        !a.fileName.toLowerCase().endsWith('.jpg') &&
        !a.fileName.toLowerCase().endsWith('.jpeg') &&
        !a.fileName.toLowerCase().endsWith('.png') &&
        !a.fileName.toLowerCase().endsWith('.gif')).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
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
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tileSuggestions.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  suggestion.typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.tileSuggestions,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              Text(
                suggestion.subject,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              Text(
                '${l10n.submittedAt} ${dateFormat.format(suggestion.submittedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Divider(height: AppSizes.paddingXL),
              Text(
                suggestion.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
              ),
              // Image attachments
              if (imageAttachments.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingL),
                Text(
                  'Images jointes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingS),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageAttachments.length,
                    itemBuilder: (context, index) {
                      final att = imageAttachments[index];
                      return GestureDetector(
                        onTap: () => _showImageFullscreen(context, att.fileUrl),
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              att.fileUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              // Document attachments
              if (docAttachments.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingL),
                Text(
                  'Fichiers joints',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingS),
                ...docAttachments.map((att) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      ),
                      title: Text(att.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: att.fileSize != null
                          ? Text('${(att.fileSize! / 1024).toStringAsFixed(1)} KB')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _openUrl(att.fileUrl),
                      ),
                    )),
              ],
              if (suggestion.replies.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingXL),
                Text(
                  l10n.adminResponse,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingM),
                ...suggestion.replies.map((reply) => Container(
                      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
                      padding: const EdgeInsets.all(AppSizes.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: AppSizes.iconS,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: AppSizes.paddingS),
                              Text(
                                reply.adminName ?? 'Administration',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                dateFormat.format(reply.repliedAt),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.paddingS),
                          Text(
                            reply.body,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: AppSizes.paddingXL),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageFullscreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _NewSuggestionForm extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  
  const _NewSuggestionForm({this.scrollController});

  @override
  ConsumerState<_NewSuggestionForm> createState() => _NewSuggestionFormState();
}

// Helper class to store file data (works on web and mobile)
class _AttachmentFile {
  final String name;
  final Uint8List bytes;
  final String? mimeType;
  
  _AttachmentFile({required this.name, required this.bytes, this.mimeType});
}

class _NewSuggestionFormState extends ConsumerState<_NewSuggestionForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  SuggestionType _selectedType = SuggestionType.general;
  List<_AttachmentFile> _attachments = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        for (final image in images) {
          final bytes = await image.readAsBytes();
          setState(() {
            _attachments.add(_AttachmentFile(
              name: image.name,
              bytes: bytes,
              mimeType: image.mimeType ?? 'image/jpeg',
            ));
          });
        }
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }
  
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: true,
        withData: true, // Important for web!
      );
      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.bytes != null) {
            setState(() {
              _attachments.add(_AttachmentFile(
                name: file.name,
                bytes: file.bytes!,
                mimeType: _getMimeType(file.name),
              ));
            });
          }
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }
  
  String _getMimeType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
  
  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.submitSuggestion,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingS),
            Text(
              l10n.suggestionDesc,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingL),
            
            // Type selector
            Text(
              'Type de demande',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSizes.paddingS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SuggestionType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(_getTypeLabel(type)),
                  selected: isSelected,
                  selectedColor: AppColors.tileSuggestions.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.tileSuggestions : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.paddingL),
            
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: l10n.subject,
                hintText: l10n.enterSubject,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.fieldRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.paddingM),
            TextFormField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: l10n.yourSuggestion,
                hintText: l10n.enterSuggestion,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
              ),
              maxLines: 6,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.fieldRequired;
                }
                if (value.length < 20) {
                  return l10n.suggestionMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.paddingM),
            
            // Attachments section
            Row(
              children: [
                Text(
                  'Pièces jointes',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.image, size: 20),
                  label: const Text('Image'),
                  onPressed: _pickImage,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.attach_file, size: 20),
                  label: const Text('Fichier'),
                  onPressed: _pickFile,
                ),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingS),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    final file = _attachments[index];
                    final isImage = file.mimeType?.startsWith('image/') == true ||
                        file.name.toLowerCase().endsWith('.jpg') ||
                        file.name.toLowerCase().endsWith('.jpeg') ||
                        file.name.toLowerCase().endsWith('.png') ||
                        file.name.toLowerCase().endsWith('.gif');
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Stack(
                        children: [
                          if (isImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.memory(
                                file.bytes,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    file.name.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.insert_drive_file,
                                    size: 32,
                                    color: file.name.endsWith('.pdf') ? Colors.red : Colors.grey[600],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      file.name,
                                      style: const TextStyle(fontSize: 10),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeAttachment(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: AppSizes.paddingXL),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitSuggestion,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tileSuggestions,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.submit),
            ),
            const SizedBox(height: AppSizes.paddingXL),
          ],
        ),
      ),
    );
  }
  
  String _getTypeLabel(SuggestionType type) {
    switch (type) {
      case SuggestionType.general:
        return 'Général';
      case SuggestionType.reclamationNote:
        return 'Réclamation note';
      case SuggestionType.absence:
        return 'Absence';
      case SuggestionType.paiement:
        return 'Paiement';
      case SuggestionType.emploiTemps:
        return 'Emploi du temps';
      case SuggestionType.vieScolaire:
        return 'Vie scolaire';
      case SuggestionType.autre:
        return 'Autre';
    }
  }

  Future<void> _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await ref.read(studentSuggestionsProvider.notifier).submitSuggestionWithBytes(
        subject: _subjectController.text.trim(),
        body: _bodyController.text.trim(),
        type: _selectedType,
        attachments: _attachments.isNotEmpty ? _attachments : null,
      );

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).suggestionSubmitted),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
