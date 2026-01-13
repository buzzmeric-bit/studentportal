import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

/// Model for attachment
class AnnouncementAttachment {
  final String id;
  final String fileUrl;
  final String fileName;
  final String? fileType;
  final String? displayName; // Custom display name

  AnnouncementAttachment({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    this.fileType,
    this.displayName,
  });

  /// Returns the display name if available, otherwise the file name
  String get effectiveName => displayName ?? fileName;

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) {
    return AnnouncementAttachment(
      id: json['id'] as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String?,
      displayName: json['display_name'] as String?,
    );
  }
}

/// Model for announcements in student app
class StudentAnnouncement {
  final String id;
  final String title;
  final String body;
  final String? announcementType;
  final bool isImportant;
  final bool isPinned;
  final bool hasAttachment;
  final String? attachmentUrl;
  final String? attachmentName;
  final List<AnnouncementAttachment> attachments;
  final String? senderLabel;
  final String? senderType;
  final DateTime publishedAt;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  StudentAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.announcementType,
    this.isImportant = false,
    this.isPinned = false,
    this.hasAttachment = false,
    this.attachmentUrl,
    this.attachmentName,
    this.attachments = const [],
    this.senderLabel,
    this.senderType,
    required this.publishedAt,
    required this.createdAt,
    this.payload = const {},
  });

  factory StudentAnnouncement.fromJson(
    Map<String, dynamic> json, {
    List<AnnouncementAttachment> attachments = const [],
  }) {
    // Get first attachment URL if available
    String? attachmentUrl;
    String? attachmentName;
    if (attachments.isNotEmpty) {
      attachmentUrl = attachments.first.fileUrl;
      attachmentName = attachments.first.fileName;
    }

    return StudentAnnouncement(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      announcementType: json['announcement_type'] as String?,
      isImportant: json['is_important'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      hasAttachment: json['has_attachment'] as bool? ?? false,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachments: attachments,
      senderLabel: json['sender_label'] as String?,
      senderType: json['sender_type'] as String?,
      publishedAt: DateTime.parse(
        json['published_at'] as String? ?? json['created_at'] as String,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Helper to fetch attachments for announcements
Future<Map<String, List<AnnouncementAttachment>>> _fetchAttachments(
  SupabaseClient supabase,
  List<String> announcementIds,
  String scope,
) async {
  if (announcementIds.isEmpty) return {};

  final response = await supabase
      .from('announcement_attachments')
      .select()
      .eq('scope', scope)
      .inFilter('announcement_id', announcementIds);

  final Map<String, List<AnnouncementAttachment>> attachmentsMap = {};

  for (final att in response as List) {
    final announcementId = att['announcement_id'] as String;
    final attachment = AnnouncementAttachment.fromJson(att);
    attachmentsMap.putIfAbsent(announcementId, () => []).add(attachment);
  }

  return attachmentsMap;
}

/// Provider for global announcements (Notifications)
final globalAnnouncementsProvider = FutureProvider<List<StudentAnnouncement>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated) {
    return [];
  }

  final schoolId = authState.user?.schoolId;
  if (schoolId == null) {
    return [];
  }

  final response = await supabase
      .from('announcements_global')
      .select()
      .eq('school_id', schoolId)
      .isFilter('deleted_at', null)
      .order('is_pinned', ascending: false)
      .order('published_at', ascending: false)
      .limit(50);

  final announcements = response as List;
  final announcementIds = announcements.map((a) => a['id'] as String).toList();

  // Fetch attachments for all announcements
  final attachmentsMap = await _fetchAttachments(
    supabase,
    announcementIds,
    'global',
  );

  return announcements
      .map(
        (json) => StudentAnnouncement.fromJson(
          json,
          attachments: attachmentsMap[json['id']] ?? [],
        ),
      )
      .toList();
});

/// Provider for class messages
final classMessagesProvider = FutureProvider<List<StudentAnnouncement>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated || authState.enrollment == null) {
    return [];
  }

  final classId = authState.enrollment!.classId;
  final groupId = authState.enrollment!.groupId;

  // Build query - get messages for user's class
  var query = supabase
      .from('announcements_class')
      .select()
      .eq('class_id', classId)
      .isFilter('deleted_at', null);

  // Also filter by group if specified, or get class-wide messages (null group_id)
  if (groupId != null) {
    query = query.or('group_id.eq.$groupId,group_id.is.null');
  }

  final response = await query
      .order('is_pinned', ascending: false)
      .order('published_at', ascending: false)
      .limit(50);

  final announcements = response as List;
  final announcementIds = announcements.map((a) => a['id'] as String).toList();

  // Fetch attachments for all announcements
  final attachmentsMap = await _fetchAttachments(
    supabase,
    announcementIds,
    'class',
  );

  return announcements
      .map(
        (json) => StudentAnnouncement.fromJson(
          json,
          attachments: attachmentsMap[json['id']] ?? [],
        ),
      )
      .toList();
});

/// Combined provider for all announcements (for unified feed if needed)
final allAnnouncementsProvider = FutureProvider<List<StudentAnnouncement>>((
  ref,
) async {
  final global = await ref.watch(globalAnnouncementsProvider.future);
  final classMessages = await ref.watch(classMessagesProvider.future);

  final all = [...global, ...classMessages];
  all.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

  return all;
});

/// Provider for global announcements count (Notifications badge)
final globalAnnouncementsCountProvider = Provider<int>((ref) {
  final announcements = ref.watch(globalAnnouncementsProvider);
  return announcements.when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for class messages count (Messages badge)
final classMessagesCountProvider = Provider<int>((ref) {
  final messages = ref.watch(classMessagesProvider);
  return messages.when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
