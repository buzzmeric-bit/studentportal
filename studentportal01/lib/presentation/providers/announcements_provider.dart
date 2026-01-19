import 'package:flutter/foundation.dart';
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

  // Check if still loading - wait for auth to complete
  if (authState.isLoading) {
    debugPrint('globalAnnouncementsProvider: Auth still loading, waiting...');
    // Return empty for now, will be re-triggered when auth state changes
    return [];
  }

  // Check authentication - also check Supabase session directly as fallback
  final session = supabase.auth.currentSession;
  if (!authState.isAuthenticated && session == null) {
    debugPrint('globalAnnouncementsProvider: Not authenticated (no session)');
    return [];
  }

  // If we have a session but auth state not loaded yet, fetch school_id directly
  String? schoolId = authState.user?.schoolId;
  
  // Fallback: get school_id from enrollment's class
  if (schoolId == null && authState.enrollment?.classInfo != null) {
    schoolId = authState.enrollment!.classInfo!.schoolId;
    debugPrint('globalAnnouncementsProvider: Got schoolId from enrollment class: $schoolId');
  }
  
  // Last resort: use RPC to bypass RLS
  if (schoolId == null && session != null) {
    debugPrint('globalAnnouncementsProvider: Using RPC to fetch school_id...');
    try {
      // Try get_my_school_id RPC first
      final rpcResult = await supabase.rpc('get_my_school_id');
      if (rpcResult != null) {
        schoolId = rpcResult as String;
        debugPrint('globalAnnouncementsProvider: Got schoolId from RPC: $schoolId');
      }
    } catch (e) {
      debugPrint('globalAnnouncementsProvider: RPC get_my_school_id failed: $e');
    }
    
    // Fallback: try get_my_enrollment_data RPC
    if (schoolId == null) {
      try {
        final enrollmentData = await supabase.rpc('get_my_enrollment_data');
        if (enrollmentData != null) {
          schoolId = enrollmentData['classes']?['school_id'] as String?;
          debugPrint('globalAnnouncementsProvider: Got schoolId from enrollment RPC: $schoolId');
        }
      } catch (e) {
        debugPrint('globalAnnouncementsProvider: RPC get_my_enrollment_data failed: $e');
      }
    }
  }
  
  if (schoolId == null) {
    debugPrint('globalAnnouncementsProvider: No school_id available');
    return [];
  }

  debugPrint('globalAnnouncementsProvider: Fetching for school_id=$schoolId');

  try {
    final response = await supabase
        .from('announcements_global')
        .select()
        .eq('school_id', schoolId)
        .isFilter('deleted_at', null)
        .order('is_pinned', ascending: false)
        .order('published_at', ascending: false)
        .limit(50);

    final announcements = response as List;
    debugPrint('globalAnnouncementsProvider: Fetched ${announcements.length} global announcements');
    
    final announcementIds = announcements.map((a) => a['id'] as String).toList();

    // Fetch attachments for all announcements
    Map<String, List<AnnouncementAttachment>> attachmentsMap = {};
    if (announcementIds.isNotEmpty) {
      try {
        attachmentsMap = await _fetchAttachments(
          supabase,
          announcementIds,
          'global',
        );
      } catch (e) {
        debugPrint('globalAnnouncementsProvider: Error fetching attachments: $e');
      }
    }

    return announcements
        .map(
          (json) => StudentAnnouncement.fromJson(
            json,
            attachments: attachmentsMap[json['id']] ?? [],
          ),
        )
        .toList();
  } catch (e) {
    debugPrint('globalAnnouncementsProvider error: $e');
    return [];
  }
});

/// Provider for class messages
final classMessagesProvider = FutureProvider<List<StudentAnnouncement>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final authState = ref.watch(authProvider);

  // Check if still loading - wait for auth to complete
  if (authState.isLoading) {
    debugPrint('classMessagesProvider: Auth still loading, waiting...');
    return [];
  }

  // Check authentication - also check Supabase session directly as fallback
  final session = supabase.auth.currentSession;
  if (!authState.isAuthenticated && session == null) {
    debugPrint('classMessagesProvider: Not authenticated (no session)');
    return [];
  }

  // Get class_id and group_id from enrollment or fetch directly
  String? classId = authState.enrollment?.classId;
  String? groupId = authState.enrollment?.groupId;
  
  // Fallback: use RPC to bypass RLS
  if (classId == null && session != null) {
    debugPrint('classMessagesProvider: Using RPC to fetch enrollment...');
    try {
      // Try get_my_class_id RPC first
      final rpcResult = await supabase.rpc('get_my_class_id');
      if (rpcResult != null) {
        classId = rpcResult as String;
        debugPrint('classMessagesProvider: Got classId from RPC: $classId');
      }
    } catch (e) {
      debugPrint('classMessagesProvider: RPC get_my_class_id failed: $e');
    }
    
    // Fallback: try get_my_enrollment_data RPC
    if (classId == null) {
      try {
        final enrollmentData = await supabase.rpc('get_my_enrollment_data');
        if (enrollmentData != null) {
          classId = enrollmentData['class_id'] as String?;
          groupId = enrollmentData['group_id'] as String?;
          debugPrint('classMessagesProvider: Got classId from enrollment RPC: $classId');
        }
      } catch (e) {
        debugPrint('classMessagesProvider: RPC get_my_enrollment_data failed: $e');
      }
    }
  }
  
  if (classId == null) {
    debugPrint('classMessagesProvider: No class_id available');
    return [];
  }

  debugPrint('classMessagesProvider: Fetching for class_id=$classId, group_id=$groupId');

  try {
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
    debugPrint('classMessagesProvider: Fetched ${announcements.length} class messages');
    
    final announcementIds = announcements.map((a) => a['id'] as String).toList();

    // Fetch attachments for all announcements
    Map<String, List<AnnouncementAttachment>> attachmentsMap = {};
    if (announcementIds.isNotEmpty) {
      try {
        attachmentsMap = await _fetchAttachments(
          supabase,
          announcementIds,
          'class',
        );
      } catch (e) {
        debugPrint('classMessagesProvider: Error fetching attachments: $e');
      }
    }

    return announcements
        .map(
          (json) => StudentAnnouncement.fromJson(
            json,
            attachments: attachmentsMap[json['id']] ?? [],
          ),
        )
        .toList();
  } catch (e) {
    debugPrint('classMessagesProvider error: $e');
    return [];
  }
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
