import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';

// =====================================================
// ENHANCED SUGGESTION MODEL WITH FILTERS
// =====================================================

class Suggestion {
  final String id;
  final String studentId;
  final String? studentName;
  final String? studentCode;
  final String? className;
  final String? classId;
  final String subject;
  final String content;
  final String status;
  final String suggestionType;
  final bool hasAttachment;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final List<SuggestionAttachment> attachments;

  Suggestion({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentCode,
    this.className,
    this.classId,
    required this.subject,
    required this.content,
    required this.status,
    this.suggestionType = 'general',
    this.hasAttachment = false,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.attachments = const [],
  });

  factory Suggestion.fromJson(Map<String, dynamic> json, {List<SuggestionAttachment>? attachments, Map<String, dynamic>? studentInfo}) {
    // Get student info from either denormalized fields, joined users, or provided studentInfo
    final users = json['users'] as Map<String, dynamic>?;
    final enrollment = studentInfo?['enrollment'] as Map<String, dynamic>?;
    final classes = enrollment?['classes'] as Map<String, dynamic>?;
    
    String? studentName = json['student_name']?.toString() ?? 
                          users?['full_name']?.toString() ?? 
                          studentInfo?['full_name']?.toString();
    String? studentCode = json['student_code']?.toString() ?? 
                          enrollment?['student_code']?.toString();
    String? className = json['class_name']?.toString();
    if (className == null && classes != null) {
      final level = classes['level']?.toString() ?? '';
      final name = classes['name']?.toString() ?? '';
      className = '$level $name'.trim();
    }
    
    // Content can be in 'body', 'content', or 'message' fields
    String content = json['body']?.toString() ?? 
                     json['content']?.toString() ?? 
                     json['message']?.toString() ?? '';
    
    return Suggestion(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentName: studentName,
      studentCode: studentCode,
      className: className,
      classId: json['class_id']?.toString() ?? enrollment?['class_id']?.toString(),
      subject: json['subject']?.toString() ?? '',
      content: content,
      status: json['status']?.toString() ?? 'sent',
      suggestionType: json['suggestion_type']?.toString() ?? 'general',
      hasAttachment: json['has_attachment'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? (json['status'] == 'read' || json['status'] == 'replied'),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      attachments: attachments ?? [],
    );
  }
  
  String get typeLabel {
    switch (suggestionType) {
      case 'reclamation_note': return 'Réclamation note';
      case 'absence': return 'Absence';
      case 'paiement': return 'Paiement';
      case 'emploi_temps': return 'Emploi du temps';
      case 'vie_scolaire': return 'Vie scolaire';
      case 'autre': return 'Autre';
      default: return 'Général';
    }
  }
}

class SuggestionAttachment {
  final String id;
  final String suggestionId;
  final String fileUrl;
  final String fileName;
  final String? fileType;
  final int? fileSize;

  SuggestionAttachment({
    required this.id,
    required this.suggestionId,
    required this.fileUrl,
    required this.fileName,
    this.fileType,
    this.fileSize,
  });

  factory SuggestionAttachment.fromJson(Map<String, dynamic> json) => SuggestionAttachment(
    id: json['id']?.toString() ?? '',
    suggestionId: json['suggestion_id']?.toString() ?? '',
    fileUrl: json['file_url']?.toString() ?? '',
    fileName: json['file_name']?.toString() ?? '',
    fileType: json['file_type']?.toString(),
    fileSize: json['file_size'] as int?,
  );
  
  bool get isImage {
    final type = fileType?.toLowerCase() ?? '';
    return type.startsWith('image/') || 
           fileName.toLowerCase().endsWith('.jpg') ||
           fileName.toLowerCase().endsWith('.jpeg') ||
           fileName.toLowerCase().endsWith('.png');
  }
}

class SuggestionsState {
  final List<Suggestion> suggestions;
  final String statusFilter;
  final String typeFilter;
  final String classFilter;
  final String searchQuery;
  final String sortBy;
  final bool sortAscending;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  
  SuggestionsState({
    this.suggestions = const [],
    this.statusFilter = 'all',
    this.typeFilter = 'all',
    this.classFilter = 'all',
    this.searchQuery = '',
    this.sortBy = 'date',
    this.sortAscending = false,
    this.dateFrom,
    this.dateTo,
  });

  List<Suggestion> get filtered {
    var list = suggestions.where((s) {
      // Status filter
      if (statusFilter == 'unread' && s.isRead) return false;
      if (statusFilter == 'read' && !s.isRead) return false;
      if (statusFilter != 'all' && statusFilter != 'unread' && statusFilter != 'read' && s.status != statusFilter) return false;
      
      // Type filter
      if (typeFilter != 'all' && s.suggestionType != typeFilter) return false;
      
      // Class filter
      if (classFilter != 'all' && s.classId != classFilter) return false;
      
      // Date range filter
      if (dateFrom != null && s.createdAt.isBefore(dateFrom!)) return false;
      if (dateTo != null && s.createdAt.isAfter(dateTo!.add(const Duration(days: 1)))) return false;
      
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final searchFields = [
          s.subject,
          s.content,
          s.studentName ?? '',
          s.studentCode ?? '',
          s.className ?? '',
          s.typeLabel,
        ].join(' ').toLowerCase();
        if (!searchFields.contains(query)) return false;
      }
      
      return true;
    }).toList();
    
    // Sort
    list.sort((a, b) {
      int result;
      switch (sortBy) {
        case 'class':
          result = (a.className ?? '').compareTo(b.className ?? '');
          break;
        case 'type':
          result = a.suggestionType.compareTo(b.suggestionType);
          break;
        case 'status':
          result = a.status.compareTo(b.status);
          break;
        default: // date
          result = a.createdAt.compareTo(b.createdAt);
      }
      return sortAscending ? result : -result;
    });
    
    return list;
  }
  
  // Get unique classes for filter dropdown
  List<String> get uniqueClasses {
    final classes = suggestions
        .where((s) => s.classId != null && s.classId!.isNotEmpty)
        .map((s) => s.classId!)
        .toSet()
        .toList();
    return classes;
  }
  
  // Get unique class names map
  Map<String, String> get classNames {
    final map = <String, String>{};
    for (final s in suggestions) {
      if (s.classId != null && s.className != null) {
        map[s.classId!] = s.className!;
      }
    }
    return map;
  }
  
  // Statistics
  int get unreadCount => suggestions.where((s) => !s.isRead).length;
  int get pendingCount => suggestions.where((s) => s.status == 'pending').length;

  SuggestionsState copyWith({
    List<Suggestion>? suggestions,
    String? statusFilter,
    String? typeFilter,
    String? classFilter,
    String? searchQuery,
    String? sortBy,
    bool? sortAscending,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) =>
    SuggestionsState(
      suggestions: suggestions ?? this.suggestions,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      classFilter: classFilter ?? this.classFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
}

class SuggestionsNotifier extends AsyncNotifier<SuggestionsState> {
  @override
  Future<SuggestionsState> build() async => _load();

  Future<SuggestionsState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final schoolId = profile['school_id'];
    
    // Fetch suggestions with user join
    final data = await supabase
        .from('suggestions')
        .select('*, users!suggestions_student_id_fkey(full_name, school_id)')
        .order('created_at', ascending: false);

    final suggestionsData = (data as List).where((e) {
      // Filter by school
      final userSchool = e['users']?['school_id'];
      final suggestionSchool = e['school_id'];
      return userSchool == schoolId || suggestionSchool == schoolId;
    }).toList();
    
    // Get student IDs to fetch enrollment info
    final studentIds = suggestionsData
        .map((s) => s['student_id'] as String?)
        .where((id) => id != null)
        .toSet()
        .toList();
    
    // Fetch enrollment info for students (to get class info)
    Map<String, Map<String, dynamic>> studentInfoMap = {};
    if (studentIds.isNotEmpty) {
      try {
        final enrollments = await supabase
            .from('enrollments')
            .select('student_id, student_code, class_id, classes(name, level)')
            .inFilter('student_id', studentIds)
            .eq('is_active', true);
        
        for (final e in (enrollments as List)) {
          final studentId = e['student_id'] as String?;
          if (studentId != null) {
            studentInfoMap[studentId] = {'enrollment': e};
          }
        }
      } catch (_) {
        // enrollments table might not exist or have different schema
      }
    }
    
    // Get suggestion IDs to fetch ALL attachments (don't rely on has_attachment flag)
    final allIds = suggestionsData.map((s) => s['id'] as String).toList();
    
    // Fetch attachments for all suggestions
    Map<String, List<SuggestionAttachment>> attachmentsMap = {};
    if (allIds.isNotEmpty) {
      try {
        final attachmentsResponse = await supabase
            .from('suggestion_attachments')
            .select()
            .inFilter('suggestion_id', allIds);
        
        for (final att in (attachmentsResponse as List)) {
          final attachment = SuggestionAttachment.fromJson(att);
          attachmentsMap.putIfAbsent(attachment.suggestionId, () => []).add(attachment);
        }
      } catch (_) {
        // suggestion_attachments table might not exist
      }
    }
    
    final suggestions = suggestionsData.map((e) {
      final id = e['id'] as String;
      final studentId = e['student_id'] as String?;
      return Suggestion.fromJson(
        e, 
        attachments: attachmentsMap[id] ?? [],
        studentInfo: studentId != null ? studentInfoMap[studentId] : null,
      );
    }).toList();
    
    return SuggestionsState(suggestions: suggestions);
  }

  void setStatusFilter(String status) {
    state.whenData((s) => state = AsyncData(s.copyWith(statusFilter: status)));
  }
  
  void setTypeFilter(String type) {
    state.whenData((s) => state = AsyncData(s.copyWith(typeFilter: type)));
  }
  
  void setClassFilter(String classId) {
    state.whenData((s) => state = AsyncData(s.copyWith(classFilter: classId)));
  }
  
  void setSearchQuery(String query) {
    state.whenData((s) => state = AsyncData(s.copyWith(searchQuery: query)));
  }
  
  void setSortBy(String field) {
    state.whenData((s) {
      final ascending = s.sortBy == field ? !s.sortAscending : false;
      state = AsyncData(s.copyWith(sortBy: field, sortAscending: ascending));
    });
  }
  
  void setDateRange(DateTime? from, DateTime? to) {
    state.whenData((s) => state = AsyncData(s.copyWith(dateFrom: from, dateTo: to)));
  }
  
  void clearFilters() {
    state.whenData((s) => state = AsyncData(SuggestionsState(suggestions: s.suggestions)));
  }

  Future<void> updateStatus(String id, String status) async {
    await SupabaseConfig.client.from('suggestions').update({'status': status}).eq('id', id);
    ref.invalidateSelf();
  }
  
  Future<void> markAsRead(String id) async {
    await SupabaseConfig.client.from('suggestions').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    ref.invalidateSelf();
  }
  
  Future<void> markAsUnread(String id) async {
    await SupabaseConfig.client.from('suggestions').update({
      'is_read': false,
      'read_at': null,
    }).eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> reply(String suggestionId, String content) async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    
    // Get admin name
    final profile = await supabase.from('users').select('full_name').eq('id', user.id).maybeSingle();
    final adminName = profile?['full_name'] ?? 'Administration';

    try {
      await supabase.from('suggestion_replies').insert({
        'suggestion_id': suggestionId,
        'admin_id': user.id,
        'reply_text': content,
      });
    } catch (_) {
      // Table might not exist, just update status
    }
    await updateStatus(suggestionId, 'replied');
  }
  
  Future<void> delete(String id) async {
    await SupabaseConfig.client.from('suggestions').delete().eq('id', id);
    ref.invalidateSelf();
  }
  
  Future<void> deleteMultiple(List<String> ids) async {
    await SupabaseConfig.client.from('suggestions').delete().inFilter('id', ids);
    ref.invalidateSelf();
  }
  
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final suggestionsProvider = AsyncNotifierProvider<SuggestionsNotifier, SuggestionsState>(SuggestionsNotifier.new);