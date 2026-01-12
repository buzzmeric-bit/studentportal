import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_model.dart';

class CourseRepository {
  final SupabaseClient _supabase;

  CourseRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetch courses for the current student
  /// Filters by student's class and group
  Future<List<CourseModel>> fetchCourses({
    String? subject,
    String? teacherName,
    String? searchQuery,
    bool? hasAttachments,
    String orderBy = 'published_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('courses')
          .select('''
            *,
            attachments:course_attachments(*)
          ''')
          .eq('is_published', true);

      // Apply filters
      if (subject != null && subject.isNotEmpty) {
        query = query.eq('subject', subject);
      }

      if (teacherName != null && teacherName.isNotEmpty) {
        query = query.ilike('teacher_name', '%$teacherName%');
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      // Order by - store the result
      final orderedQuery = query.order(orderBy, ascending: ascending);

      final response = await orderedQuery;
      
      final courses = (response as List)
          .map((json) => CourseModel.fromJson(json))
          .toList();

      // Filter by hasAttachments if specified
      if (hasAttachments != null) {
        return courses.where((c) => c.hasAttachments == hasAttachments).toList();
      }

      return courses;
    } catch (e) {
      throw Exception('Failed to fetch courses: $e');
    }
  }

  /// Fetch a single course by ID with all attachments
  Future<CourseModel?> fetchCourseById(String courseId) async {
    try {
      final response = await _supabase
          .from('courses')
          .select('''
            *,
            attachments:course_attachments(*)
          ''')
          .eq('id', courseId)
          .single();

      return CourseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch course: $e');
    }
  }

  /// Get list of unique subjects from all courses
  Future<List<String>> fetchSubjects() async {
    try {
      final response = await _supabase
          .from('courses')
          .select('subject')
          .eq('is_published', true);

      final subjects = (response as List)
          .map((json) => json['subject'] as String)
          .toSet()
          .toList();

      subjects.sort();
      return subjects;
    } catch (e) {
      throw Exception('Failed to fetch subjects: $e');
    }
  }

  /// Get list of unique teacher names
  Future<List<String>> fetchTeacherNames() async {
    try {
      final response = await _supabase
          .from('courses')
          .select('teacher_name')
          .eq('is_published', true);

      final teachers = (response as List)
          .map((json) => json['teacher_name'] as String)
          .toSet()
          .toList();

      teachers.sort();
      return teachers;
    } catch (e) {
      throw Exception('Failed to fetch teacher names: $e');
    }
  }

  /// Mark a course as viewed by the current student
  Future<void> markAsViewed(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('course_views').upsert({
        'course_id': courseId,
        'student_id': userId,
        'seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'course_id,student_id');
    } catch (e) {
      // Silently fail if marking as viewed fails
      // This is not critical functionality
      print('Failed to mark course as viewed: $e');
    }
  }

  /// Check if student has viewed a course
  Future<bool> hasViewed(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return false;
      }

      final response = await _supabase
          .from('course_views')
          .select('id')
          .eq('course_id', courseId)
          .eq('student_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get count of courses matching filters
  Future<int> getCourseCount({
    String? subject,
    String? teacherName,
    String? searchQuery,
  }) async {
    try {
      var count = _supabase
          .from('courses')
          .select('id')
          .eq('is_published', true);

      if (subject != null && subject.isNotEmpty) {
        count = count.eq('subject', subject);
      }

      if (teacherName != null && teacherName.isNotEmpty) {
        count = count.ilike('teacher_name', '%$teacherName%');
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        count = count.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final response = await count.count();
      return response.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Download file URL (generates a signed URL for private files)
  Future<String> getAttachmentUrl(String fileUrl) async {
    try {
      // If the URL is already a full URL, return it
      if (fileUrl.startsWith('http')) {
        return fileUrl;
      }

      // Otherwise, generate a signed URL from storage
      final signedUrl = await _supabase.storage
          .from('courses')
          .createSignedUrl(fileUrl, 3600); // 1 hour expiry

      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get attachment URL: $e');
    }
  }
}
