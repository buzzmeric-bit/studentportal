import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository {
  final SupabaseClient _client;

  AnnouncementRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch all announcements using the unified view
  Future<List<Announcement>> fetchAnnouncements({
    String? schoolId,
    String? classId,
    AnnouncementScope? scopeFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Build query with filters BEFORE ordering
      var query = _client.from('vw_announcements').select();

      // Apply filters first
      if (scopeFilter != null) {
        query = query.eq('scope', scopeFilter == AnnouncementScope.global ? 'global' : 'class');
      }

      if (schoolId != null) {
        query = query.eq('school_id', schoolId);
      }

      if (classId != null) {
        query = query.eq('class_id', classId);
      }

      // Then apply ordering and pagination
      final response = await query
          .order('is_pinned', ascending: false)
          .order('published_at', ascending: false)
          .range(offset, offset + limit - 1);

      final announcements = (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();

      // Fetch attachments for each announcement
      for (var i = 0; i < announcements.length; i++) {
        final attachments = await fetchAttachments(
          announcements[i].id,
          announcements[i].scope == AnnouncementScope.global ? 'global' : 'class',
        );
        announcements[i] = announcements[i].copyWith(attachments: attachments);
      }

      return announcements;
    } catch (e) {
      debugPrint('fetchAnnouncements error: $e - falling back to individual tables');
      // Fallback to individual tables
      final results = <Announcement>[];
      
      if (scopeFilter == null || scopeFilter == AnnouncementScope.global) {
        final global = await fetchGlobalAnnouncements(schoolId ?? '');
        results.addAll(global);
      }
      
      if (scopeFilter == null || scopeFilter == AnnouncementScope.classScope) {
        if (classId != null) {
          final classAnnouncements = await fetchClassAnnouncements(classId: classId);
          results.addAll(classAnnouncements);
        }
      }
      
      results.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
      return results.take(limit).toList();
    }
  }

  /// Fetch global announcements (Note d'info)
  Future<List<Announcement>> fetchGlobalAnnouncements(String schoolId) async {
    final response = await _client
        .from('announcements_global')
        .select()
        .eq('school_id', schoolId)
        .order('published_at', ascending: false);

    return (response as List)
        .map((json) => Announcement.fromJson({...json, 'scope': 'global'}))
        .toList();
  }

  /// Fetch class announcements (Messages)
  Future<List<Announcement>> fetchClassAnnouncements({
    required String classId,
    String? groupId,
  }) async {
    var query = _client
        .from('announcements_class')
        .select()
        .eq('class_id', classId);

    if (groupId != null) {
      query = query.eq('group_id', groupId);
    }

    final response = await query.order('published_at', ascending: false);
    return (response as List)
        .map((json) => Announcement.fromJson({...json, 'scope': 'class'}))
        .toList();
  }

  /// Create a global announcement (Note d'info)
  Future<Announcement> createGlobalAnnouncement(Announcement announcement) async {
    final response = await _client
        .from('announcements_global')
        .insert(announcement.toJsonForGlobal())
        .select()
        .single();

    return Announcement.fromJson({...response, 'scope': 'global'});
  }

  /// Create a class announcement (Messages)
  Future<Announcement> createClassAnnouncement(Announcement announcement) async {
    final response = await _client
        .from('announcements_class')
        .insert(announcement.toJsonForClass())
        .select()
        .single();

    return Announcement.fromJson({...response, 'scope': 'class'});
  }

  /// Create announcement based on scope
  Future<Announcement> createAnnouncement(Announcement announcement) async {
    if (announcement.scope == AnnouncementScope.global) {
      return createGlobalAnnouncement(announcement);
    } else {
      return createClassAnnouncement(announcement);
    }
  }

  /// Update a global announcement
  Future<Announcement> updateGlobalAnnouncement(Announcement announcement) async {
    final response = await _client
        .from('announcements_global')
        .update(announcement.toJsonForGlobal())
        .eq('id', announcement.id)
        .select()
        .single();

    return Announcement.fromJson({...response, 'scope': 'global'});
  }

  /// Update a class announcement
  Future<Announcement> updateClassAnnouncement(Announcement announcement) async {
    final response = await _client
        .from('announcements_class')
        .update(announcement.toJsonForClass())
        .eq('id', announcement.id)
        .select()
        .single();

    return Announcement.fromJson({...response, 'scope': 'class'});
  }

  /// Update announcement based on scope
  Future<Announcement> updateAnnouncement(Announcement announcement) async {
    if (announcement.scope == AnnouncementScope.global) {
      return updateGlobalAnnouncement(announcement);
    } else {
      return updateClassAnnouncement(announcement);
    }
  }

  /// Delete a global announcement
  Future<void> deleteGlobalAnnouncement(String id) async {
    // Delete attachments first
    await _client
        .from('announcement_attachments')
        .delete()
        .eq('announcement_id', id)
        .eq('scope', 'global');

    await _client
        .from('announcements_global')
        .delete()
        .eq('id', id);
  }

  /// Delete a class announcement
  Future<void> deleteClassAnnouncement(String id) async {
    // Delete attachments first
    await _client
        .from('announcement_attachments')
        .delete()
        .eq('announcement_id', id)
        .eq('scope', 'class');

    await _client
        .from('announcements_class')
        .delete()
        .eq('id', id);
  }

  /// Delete announcement based on scope
  Future<void> deleteAnnouncement(String id, AnnouncementScope scope) async {
    if (scope == AnnouncementScope.global) {
      await deleteGlobalAnnouncement(id);
    } else {
      await deleteClassAnnouncement(id);
    }
  }

  /// Toggle pin status
  Future<void> togglePinned(String id, AnnouncementScope scope, bool isPinned) async {
    final table = scope == AnnouncementScope.global 
        ? 'announcements_global' 
        : 'announcements_class';

    await _client
        .from(table)
        .update({'is_pinned': isPinned})
        .eq('id', id);
  }

  /// Upload attachment to storage
  /// Throws descriptive error if bucket is missing
  Future<String> uploadAttachment({
    required String announcementId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    const bucketName = SupabaseConfig.attachmentsBucket;
    
    // Check bucket exists
    final bucketExists = await SupabaseConfig.bucketExists(bucketName);
    if (!bucketExists) {
      throw Exception(
        'Bucket "$bucketName" introuvable dans Supabase Storage.\n'
        'Créez-le dans le dashboard Supabase: Storage > New bucket > "$bucketName" > Public'
      );
    }

    // Generate unique path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'announcements/$announcementId/${timestamp}_$safeName';
    
    await _client.storage
        .from(bucketName)
        .uploadBinary(path, fileBytes, fileOptions: FileOptions(contentType: mimeType));

    return _client.storage.from(bucketName).getPublicUrl(path);
  }

  /// Save attachment metadata
  Future<AnnouncementAttachment> saveAttachmentMetadata({
    required String scope,
    required String announcementId,
    required String fileUrl,
    required String fileName,
    String? mimeType,
    int? sizeBytes,
  }) async {
    final response = await _client
        .from('announcement_attachments')
        .insert({
          'scope': scope,
          'announcement_id': announcementId,
          'file_url': fileUrl,
          'file_name': fileName,
          'mime_type': mimeType,
          'size_bytes': sizeBytes,
        })
        .select()
        .single();

    return AnnouncementAttachment.fromJson(response);
  }

  /// Fetch attachments for an announcement
  Future<List<AnnouncementAttachment>> fetchAttachments(String announcementId, String scope) async {
    final response = await _client
        .from('announcement_attachments')
        .select()
        .eq('announcement_id', announcementId)
        .eq('scope', scope);

    return (response as List)
        .map((json) => AnnouncementAttachment.fromJson(json))
        .toList();
  }

  /// Delete attachment
  Future<void> deleteAttachment(String attachmentId) async {
    await _client
        .from('announcement_attachments')
        .delete()
        .eq('id', attachmentId);
  }
}
