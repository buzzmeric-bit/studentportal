import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';

// Course Repository Provider
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

// Courses List Provider with filters
final coursesProvider = FutureProvider.family<List<CourseModel>, CoursesFilter>(
  (ref, filter) async {
    final repository = ref.watch(courseRepositoryProvider);
    return repository.fetchCourses(
      subject: filter.subject,
      teacherName: filter.teacherName,
      searchQuery: filter.searchQuery,
      hasAttachments: filter.hasAttachments,
      orderBy: filter.orderBy,
      ascending: filter.ascending,
    );
  },
);

// Single Course Provider
final courseDetailProvider = FutureProvider.family<CourseModel?, String>(
  (ref, courseId) async {
    final repository = ref.watch(courseRepositoryProvider);
    return repository.fetchCourseById(courseId);
  },
);

// Subjects Provider (for filter dropdown)
final subjectsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.fetchSubjects();
});

// Teachers Provider (for filter dropdown)
final teachersProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.fetchTeacherNames();
});

// Course Count Provider
final courseCountProvider = FutureProvider.family<int, CoursesFilter>(
  (ref, filter) async {
    final repository = ref.watch(courseRepositoryProvider);
    return repository.getCourseCount(
      subject: filter.subject,
      teacherName: filter.teacherName,
      searchQuery: filter.searchQuery,
    );
  },
);

// State notifier for managing course filters
class CoursesFilterNotifier extends StateNotifier<CoursesFilter> {
  CoursesFilterNotifier() : super(CoursesFilter());

  void setSubject(String? subject) {
    state = state.copyWith(subject: subject);
  }

  void setTeacherName(String? teacherName) {
    state = state.copyWith(teacherName: teacherName);
  }

  void setSearchQuery(String? searchQuery) {
    state = state.copyWith(searchQuery: searchQuery);
  }

  void setHasAttachments(bool? hasAttachments) {
    state = state.copyWith(hasAttachments: hasAttachments);
  }

  void setOrderBy(String orderBy, bool ascending) {
    state = state.copyWith(orderBy: orderBy, ascending: ascending);
  }

  void reset() {
    state = CoursesFilter();
  }
}

final coursesFilterProvider = StateNotifierProvider<CoursesFilterNotifier, CoursesFilter>(
  (ref) => CoursesFilterNotifier(),
);

// Filtered Courses Provider (uses current filter state)
final filteredCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  final filter = ref.watch(coursesFilterProvider);
  final repository = ref.watch(courseRepositoryProvider);
  
  return repository.fetchCourses(
    subject: filter.subject,
    teacherName: filter.teacherName,
    searchQuery: filter.searchQuery,
    hasAttachments: filter.hasAttachments,
    orderBy: filter.orderBy,
    ascending: filter.ascending,
  );
});

// Mark course as viewed action
final markCourseAsViewedProvider = Provider<Future<void> Function(String)>((ref) {
  return (courseId) async {
    final repository = ref.read(courseRepositoryProvider);
    await repository.markAsViewed(courseId);
    // Invalidate the course detail to refresh the viewed status
    ref.invalidate(courseDetailProvider(courseId));
  };
});

// Courses Filter Model
class CoursesFilter {
  final String? subject;
  final String? teacherName;
  final String? searchQuery;
  final bool? hasAttachments;
  final String orderBy;
  final bool ascending;

  CoursesFilter({
    this.subject,
    this.teacherName,
    this.searchQuery,
    this.hasAttachments,
    this.orderBy = 'published_at',
    this.ascending = false,
  });

  CoursesFilter copyWith({
    String? subject,
    String? teacherName,
    String? searchQuery,
    bool? hasAttachments,
    String? orderBy,
    bool? ascending,
  }) {
    return CoursesFilter(
      subject: subject ?? this.subject,
      teacherName: teacherName ?? this.teacherName,
      searchQuery: searchQuery ?? this.searchQuery,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      orderBy: orderBy ?? this.orderBy,
      ascending: ascending ?? this.ascending,
    );
  }

  bool get hasActiveFilters {
    return subject != null ||
        teacherName != null ||
        (searchQuery != null && searchQuery!.isNotEmpty) ||
        hasAttachments != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CoursesFilter &&
        other.subject == subject &&
        other.teacherName == teacherName &&
        other.searchQuery == searchQuery &&
        other.hasAttachments == hasAttachments &&
        other.orderBy == orderBy &&
        other.ascending == ascending;
  }

  @override
  int get hashCode {
    return Object.hash(
      subject,
      teacherName,
      searchQuery,
      hasAttachments,
      orderBy,
      ascending,
    );
  }
}
