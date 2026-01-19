import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../core/config/supabase_config.dart';
import '../../models/announcement_model.dart';
import '../../repositories/announcement_repository.dart';

/// AnnouncementModel with full support for announcement types, sender info, and attachments
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String? targetRole;
  final String? targetClassId;
  final bool isPinned;
  final bool isImportant;
  final String scope;
  final DateTime createdAt;
  final String? authorName;
  final String announcementType;
  final String senderType;
  final String? senderLabel;
  final String? senderAvatarText;
  final bool hasAttachment;
  final String? className;
  final Map<String, dynamic> payload;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.targetRole,
    this.targetClassId,
    this.isPinned = false,
    this.isImportant = false,
    this.scope = 'global',
    required this.createdAt,
    this.authorName,
    this.announcementType = 'general',
    this.senderType = 'administration',
    this.senderLabel,
    this.senderAvatarText,
    this.hasAttachment = false,
    this.className,
    this.payload = const {},
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) => AnnouncementModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    content: (json['body'] ?? json['content'] ?? '').toString(),
    targetRole: json['target_role']?.toString(),
    targetClassId: json['class_id']?.toString() ?? json['target_class_id']?.toString(),
    isPinned: json['is_pinned'] == true,
    isImportant: json['is_important'] == true,
    scope: json['scope']?.toString() ?? 'global',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['published_at']?.toString() ?? '') ?? DateTime.now(),
    authorName: json['users']?['full_name']?.toString() ?? json['sender_label']?.toString(),
    announcementType: json['announcement_type']?.toString() ?? 'general',
    senderType: json['sender_type']?.toString() ?? 'administration',
    senderLabel: json['sender_label']?.toString(),
    senderAvatarText: json['sender_avatar_text']?.toString(),
    hasAttachment: json['has_attachment'] == true,
    className: json['class_name']?.toString(),
    payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
  );

  Announcement toAnnouncement() => Announcement(
    id: id,
    scope: scope == 'class' ? AnnouncementScope.classScope : AnnouncementScope.global,
    title: title,
    body: content,
    isPinned: isPinned,
    isImportant: isImportant,
    classId: targetClassId,
    createdAt: createdAt,
    payload: payload,
  );
}

class AnnouncementsState {
  final List<AnnouncementModel> announcements;
  final String searchQuery;
  AnnouncementsState({this.announcements = const [], this.searchQuery = ''});

  List<AnnouncementModel> get filtered => searchQuery.isEmpty 
      ? announcements 
      : announcements.where((a) => a.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();

  AnnouncementsState copyWith({List<AnnouncementModel>? announcements, String? searchQuery}) => 
      AnnouncementsState(
        announcements: announcements ?? this.announcements, 
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class AnnouncementsNotifier extends AsyncNotifier<AnnouncementsState> {
  AnnouncementRepository? _repository;
  AnnouncementRepository get repository => _repository ??= AnnouncementRepository();

  @override
  Future<AnnouncementsState> build() async {
    return _load();
  }

  Future<AnnouncementsState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final schoolId = profile['school_id'] as String?;

    try {
      // Use the unified view vw_announcements for reading - filter out soft deleted
      final data = await supabase
          .from('vw_announcements')
          .select()
          .or('school_id.eq.$schoolId,school_id.is.null')
          .order('is_pinned', ascending: false)
          .order('published_at', ascending: false);

      return AnnouncementsState(
        announcements: (data as List).map((e) => AnnouncementModel.fromJson(e)).toList(),
      );
    } catch (e) {
      // Fallback: try to fetch from individual tables
      try {
        final globalData = await supabase
            .from('announcements_global')
            .select()
            .eq('school_id', schoolId ?? '')
            .order('published_at', ascending: false);
        
        final classData = await supabase
            .from('announcements_class')
            .select()
            .order('published_at', ascending: false);

        final List<AnnouncementModel> announcements = [
          ...(globalData as List).map((e) => AnnouncementModel.fromJson({...e, 'scope': 'global'})),
          ...(classData as List).map((e) => AnnouncementModel.fromJson({...e, 'scope': 'class'})),
        ];
        
        announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return AnnouncementsState(announcements: announcements);
      } catch (_) {
        // If all fails, return empty
        return AnnouncementsState(announcements: []);
      }
    }
  }

  /// Force refresh - clears cache and reloads from Supabase
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load());
  }

  void setSearchQuery(String q) { 
    state.whenData((c) => state = AsyncData(c.copyWith(searchQuery: q)));
  }

  /// Fetch all classes from database with niveau information and student count
  Future<List<Map<String, dynamic>>> fetchClasses() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
      final schoolId = profile['school_id'] as String?;
      if (schoolId == null) return [];

      // Fetch classes with niveau info
      final classesData = await supabase
          .from('classes')
          .select('id, name, niveau_id')
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('name');

      final classes = (classesData as List).cast<Map<String, dynamic>>();
      
      // Fetch niveaux separately
      final niveauxData = await supabase
          .from('niveaux')
          .select('id, code, name, cycle, display_order')
          .order('display_order');
      
      final niveauxMap = <String, Map<String, dynamic>>{};
      for (final n in (niveauxData as List)) {
        niveauxMap[n['id'] as String] = n as Map<String, dynamic>;
      }
      
      // Get student counts per class via RPC (security definer to bypass RLS)
      final studentCounts = <String, int>{};
      try {
        final stats = await supabase.rpc('get_class_stats');
        for (final row in (stats as List)) {
          final classId = row['class_id'] as String?;
          final count = (row['student_count'] as num?)?.toInt() ?? 0;
          if (classId != null) studentCounts[classId] = count;
        }
      } catch (e) {
        debugPrint('Error fetching class stats rpc: $e');
        // Fallback: zero counts
      }
      
      // Enrich classes with niveau info and student count
      for (final c in classes) {
        final niveauId = c['niveau_id'] as String?;
        if (niveauId != null && niveauxMap.containsKey(niveauId)) {
          c['niveaux'] = niveauxMap[niveauId];
        }
        c['student_count'] = studentCounts[c['id'] as String] ?? 0;
      }
      
      // Sort by niveau display_order then by class name
      classes.sort((a, b) {
        final niveauA = a['niveaux'] as Map<String, dynamic>?;
        final niveauB = b['niveaux'] as Map<String, dynamic>?;
        final orderA = niveauA?['display_order'] as int? ?? 999;
        final orderB = niveauB?['display_order'] as int? ?? 999;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
      });
      
      return classes;
    } catch (e) {
      debugPrint('Error fetching classes: $e');
      return [];
    }
  }
  
  /// Fetch niveaux (grade levels) for the school
  Future<List<Map<String, dynamic>>> fetchNiveaux() async {
    final supabase = SupabaseConfig.client;
    
    try {
      final data = await supabase
          .from('niveaux')
          .select('id, code, name, cycle, display_order')
          .order('display_order');
      
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching niveaux: $e');
      return [];
    }
  }

  /// Create announcement - routes to correct table based on scope
  Future<String?> create({
    required String title, 
    required String content, 
    String? targetClassId, 
    bool isPinned = false,
    bool isImportant = false,
    String scope = 'global',
    String announcementType = 'general',
    String senderType = 'administration',
    String? senderLabel,
    Map<String, dynamic>? payload,
  }) async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final schoolId = profile['school_id'] as String?;

    String? insertedId;

    if (scope == 'class' && targetClassId != null) {
      final result = await supabase.from('announcements_class').insert({
        'title': title,
        'body': content,
        'class_id': targetClassId,
        'is_pinned': isPinned,
        'is_important': isImportant,
        'created_by': user.id,
        'published_at': DateTime.now().toIso8601String(),
        'announcement_type': announcementType,
        'sender_type': senderType,
        'sender_label': senderLabel,
        'sender_avatar_text': senderLabel != null && senderLabel.isNotEmpty ? senderLabel[0].toUpperCase() : null,
        'payload': payload ?? {},
      }).select('id').single();
      insertedId = result['id'];
    } else {
      final result = await supabase.from('announcements_global').insert({
        'title': title,
        'body': content,
        'school_id': schoolId,
        'is_pinned': isPinned,
        'is_important': isImportant,
        'created_by': user.id,
        'published_at': DateTime.now().toIso8601String(),
        'announcement_type': announcementType,
        'sender_type': senderType,
        'sender_label': senderLabel,
        'sender_avatar_text': senderLabel != null && senderLabel.isNotEmpty ? senderLabel[0].toUpperCase() : null,
        'payload': payload ?? {},
      }).select('id').single();
      insertedId = result['id'];
    }
    ref.invalidateSelf();
    return insertedId;
  }

  /// Upload attachment to Supabase storage and record in announcement_attachments table
  Future<void> uploadAttachment({
    required String announcementId,
    required String scope,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    String? displayName, // Custom display name for non-images
  }) async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    // Get school_id for unique path
    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final schoolId = profile['school_id'] as String? ?? 'unknown';

    const bucketName = SupabaseConfig.attachmentsBucket;

    // Generate unique path: school_id/announcements/<announcement_id>/<timestamp>_<filename>
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$schoolId/announcements/$announcementId/${timestamp}_$safeName';

    try {
      // Upload to storage
      await supabase.storage
          .from(bucketName)
          .uploadBinary(storagePath, fileBytes, fileOptions: FileOptions(contentType: mimeType));
    } catch (e) {
      throw Exception('Erreur upload storage: $e\nPath: $storagePath');
    }

    // Get public URL
    final publicUrl = supabase.storage.from(bucketName).getPublicUrl(storagePath);

    try {
      // Record in database
      final insertData = {
        'announcement_id': announcementId,
        'scope': scope,
        'file_name': fileName,
        'file_url': publicUrl,
        'file_type': mimeType,
        'file_size': fileBytes.length,
      };
      
      // Add display_name if provided and different from fileName
      if (displayName != null && displayName.isNotEmpty && displayName != fileName) {
        insertData['display_name'] = displayName;
      }
      
      await supabase.from('announcement_attachments').insert(insertData);
    } catch (e) {
      throw Exception('Erreur insert attachment: $e');
    }

    try {
      // Update has_attachment flag
      final table = scope == 'class' ? 'announcements_class' : 'announcements_global';
      await supabase.from(table).update({'has_attachment': true}).eq('id', announcementId);
    } catch (e) {
      throw Exception('Erreur update has_attachment: $e');
    }
  }

  /// Delete attachment from storage and database
  Future<void> deleteAttachment(String attachmentId) async {
    final supabase = SupabaseConfig.client;
    
    // Get attachment info first
    final att = await supabase
        .from('announcement_attachments')
        .select()
        .eq('id', attachmentId)
        .single();
    
    final fileUrl = att['file_url'] as String;
    final announcementId = att['announcement_id'] as String;
    final scope = att['scope'] as String;
    
    // Extract storage path from URL
    final bucketName = SupabaseConfig.attachmentsBucket;
    final urlParts = fileUrl.split('/$bucketName/');
    if (urlParts.length > 1) {
      final storagePath = urlParts[1];
      try {
        await supabase.storage.from(bucketName).remove([storagePath]);
      } catch (e) {
        debugPrint('Storage delete error (may not exist): $e');
      }
    }
    
    // Delete from database
    await supabase.from('announcement_attachments').delete().eq('id', attachmentId);
    
    // Check if announcement still has attachments
    final remaining = await supabase
        .from('announcement_attachments')
        .select('id')
        .eq('announcement_id', announcementId)
        .eq('scope', scope);
    
    if ((remaining as List).isEmpty) {
      // Update has_attachment flag to false
      final table = scope == 'class' ? 'announcements_class' : 'announcements_global';
      await supabase.from(table).update({'has_attachment': false}).eq('id', announcementId);
    }
  }

  /// Update announcement - routes to correct table based on scope
  Future<void> updateAnnouncement({
    required String id, 
    required String title, 
    required String content, 
    String? targetClassId, 
    bool isPinned = false,
    bool isImportant = false,
    String scope = 'global',
    String announcementType = 'general',
    String senderType = 'administration',
    String? senderLabel,
    Map<String, dynamic>? payload,
  }) async {
    final supabase = SupabaseConfig.client;
    
    final updateData = {
      'title': title,
      'body': content,
      'is_pinned': isPinned,
      'is_important': isImportant,
      'announcement_type': announcementType,
      'sender_type': senderType,
      'sender_label': senderLabel,
      'sender_avatar_text': senderLabel != null && senderLabel.isNotEmpty ? senderLabel[0].toUpperCase() : null,
      'payload': payload ?? {},
    };

    if (scope == 'class') {
      await supabase.from('announcements_class').update(updateData).eq('id', id);
    } else {
      await supabase.from('announcements_global').update(updateData).eq('id', id);
    }
    ref.invalidateSelf();
  }

  /// Delete announcement - SOFT DELETE (sets deleted_at)
  Future<void> delete(String id, {String scope = 'global'}) async {
    final supabase = SupabaseConfig.client;
    
    // Soft delete - set deleted_at timestamp
    final updateData = {'deleted_at': DateTime.now().toIso8601String()};

    if (scope == 'class') {
      await supabase.from('announcements_class').update(updateData).eq('id', id);
    } else {
      await supabase.from('announcements_global').update(updateData).eq('id', id);
    }
    ref.invalidateSelf();
  }

  /// Bulk delete multiple announcements (soft delete)
  Future<void> bulkDelete(List<AnnouncementModel> announcements) async {
    final supabase = SupabaseConfig.client;
    final now = DateTime.now().toIso8601String();
    
    final globalIds = announcements.where((a) => a.scope == 'global').map((a) => a.id).toList();
    final classIds = announcements.where((a) => a.scope == 'class').map((a) => a.id).toList();
    
    if (globalIds.isNotEmpty) {
      await supabase.from('announcements_global').update({'deleted_at': now}).inFilter('id', globalIds);
    }
    if (classIds.isNotEmpty) {
      await supabase.from('announcements_class').update({'deleted_at': now}).inFilter('id', classIds);
    }
    ref.invalidateSelf();
  }

  /// Bulk toggle pin for multiple announcements
  Future<void> bulkTogglePin(List<AnnouncementModel> announcements, bool pinned) async {
    final supabase = SupabaseConfig.client;
    
    final globalIds = announcements.where((a) => a.scope == 'global').map((a) => a.id).toList();
    final classIds = announcements.where((a) => a.scope == 'class').map((a) => a.id).toList();
    
    if (globalIds.isNotEmpty) {
      await supabase.from('announcements_global').update({'is_pinned': pinned}).inFilter('id', globalIds);
    }
    if (classIds.isNotEmpty) {
      await supabase.from('announcements_class').update({'is_pinned': pinned}).inFilter('id', classIds);
    }
    ref.invalidateSelf();
  }

  /// Bulk mark as important for multiple announcements
  Future<void> bulkToggleImportant(List<AnnouncementModel> announcements, bool important) async {
    final supabase = SupabaseConfig.client;
    
    final globalIds = announcements.where((a) => a.scope == 'global').map((a) => a.id).toList();
    final classIds = announcements.where((a) => a.scope == 'class').map((a) => a.id).toList();
    
    if (globalIds.isNotEmpty) {
      await supabase.from('announcements_global').update({'is_important': important}).inFilter('id', globalIds);
    }
    if (classIds.isNotEmpty) {
      await supabase.from('announcements_class').update({'is_important': important}).inFilter('id', classIds);
    }
    ref.invalidateSelf();
  }

  /// Toggle pin status - routes to correct table
  Future<void> togglePin(String id, bool pinned, {String scope = 'global'}) async {
    final supabase = SupabaseConfig.client;
    
    if (scope == 'class') {
      await supabase.from('announcements_class').update({'is_pinned': !pinned}).eq('id', id);
    } else {
      await supabase.from('announcements_global').update({'is_pinned': !pinned}).eq('id', id);
    }
    ref.invalidateSelf();
  }
}

final announcementsProvider = AsyncNotifierProvider<AnnouncementsNotifier, AnnouncementsState>(AnnouncementsNotifier.new);
