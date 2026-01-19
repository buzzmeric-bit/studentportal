import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/models/tunisian_coefficients.dart';
import '../../../data/models/grading_config_model.dart';
import '../../widgets/admin_sidebar.dart';

// ===================== MODELS =====================

class TimetableSlotAdmin {
  final String id;
  final String subjectOfferingId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String? subjectName;
  final String? subjectCode;
  final String? className;
  final String? teacherName;

  TimetableSlotAdmin({
    required this.id,
    required this.subjectOfferingId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.subjectName,
    this.subjectCode,
    this.className,
    this.teacherName,
  });

  factory TimetableSlotAdmin.fromJson(
    Map<String, dynamic> json,
  ) => TimetableSlotAdmin(
    id: json['id']?.toString() ?? '',
    subjectOfferingId: json['subject_offering_id']?.toString() ?? '',
    dayOfWeek: json['day_of_week'] ?? 1,
    startTime: json['start_time']?.toString() ?? '08:00',
    endTime: json['end_time']?.toString() ?? '09:00',
    room: json['room']?.toString(),
    subjectName: json['subject_offerings']?['subjects']?['name']?.toString(),
    subjectCode: json['subject_offerings']?['subjects']?['code']?.toString(),
    className: json['subject_offerings']?['classes']?['name']?.toString(),
    teacherName: json['subject_offerings']?['users']?['full_name']?.toString(),
  );
}

class ClassInfo {
  final String id;
  final String name;
  final String? gradeLevelId;
  final String? gradeLevelCode;
  final String? sectionCode;
  final String? cycle; // 'base' or 'secondaire'
  final bool? hasSections;

  ClassInfo({
    required this.id,
    required this.name,
    this.gradeLevelId,
    this.gradeLevelCode,
    this.sectionCode,
    this.cycle,
    this.hasSections,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) => ClassInfo(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    gradeLevelId:
        json['niveau_id']?.toString() ?? json['grade_level_id']?.toString(),
    gradeLevelCode:
        json['niveaux']?['code']?.toString() ??
        json['grade_levels']?['code']?.toString(),
    sectionCode: json['sections']?['code']?.toString(),
    cycle: json['niveaux']?['cycle']?.toString(),
    hasSections: json['niveaux']?['has_sections'] as bool?,
  );
}

class SubjectOfferingInfo {
  final String id;
  final String subjectName;
  final String? subjectCode;
  final String? teacherName;

  SubjectOfferingInfo({
    required this.id,
    required this.subjectName,
    this.subjectCode,
    this.teacherName,
  });

  factory SubjectOfferingInfo.fromJson(Map<String, dynamic> json) =>
      SubjectOfferingInfo(
        id: json['id']?.toString() ?? '',
        subjectName: json['subjects']?['name']?.toString() ?? 'N/A',
        subjectCode: json['subjects']?['code']?.toString(),
        teacherName: json['users']?['full_name']?.toString(),
      );
}

// ===================== PROVIDERS =====================

// Selected class provider
final selectedClassProvider = StateProvider<ClassInfo?>((ref) => null);

// Classes list provider
final classesListProvider = FutureProvider<List<ClassInfo>>((ref) async {
  final supabase = SupabaseConfig.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final profile = await supabase
      .from('users')
      .select('school_id')
      .eq('id', user.id)
      .single();
  final schoolId = profile['school_id'];
  if (schoolId == null) return [];

  try {
    final data = await supabase
        .from('classes')
        .select(
          'id, name, niveau_id, niveaux(code, cycle, has_sections), sections(code)',
        )
        .eq('school_id', schoolId)
        .order('name');

    return (data as List).map((e) => ClassInfo.fromJson(e)).toList();
  } catch (e) {
    // Fallback query without relations
    final data = await supabase
        .from('classes')
        .select('id, name')
        .eq('school_id', schoolId)
        .order('name');
    return (data as List).map((e) => ClassInfo.fromJson(e)).toList();
  }
});

// Subject offerings for selected class
final classSubjectOfferingsProvider =
    FutureProvider.family<List<SubjectOfferingInfo>, String>((
      ref,
      classId,
    ) async {
      final supabase = SupabaseConfig.client;

      try {
        // Try with nested relations
        final data = await supabase
            .from('subject_offerings')
            .select(
              'id, subject_id, teacher_id, subjects(name, code), users(full_name)',
            )
            .eq('class_id', classId)
            .eq('is_active', true);

        return (data as List)
            .map((e) => SubjectOfferingInfo.fromJson(e))
            .toList();
      } catch (e) {
        // Fallback: fetch without nested relations and join manually
        debugPrint('classSubjectOfferingsProvider error: $e - using fallback');
        try {
          final offerings = await supabase
              .from('subject_offerings')
              .select('id, subject_id, teacher_id')
              .eq('class_id', classId)
              .eq('is_active', true);

          if ((offerings as List).isEmpty) return [];

          // Fetch subjects separately
          final subjectIds = offerings
              .map((o) => o['subject_id'])
              .where((id) => id != null)
              .toSet()
              .toList();
          final teacherIds = offerings
              .map((o) => o['teacher_id'])
              .where((id) => id != null)
              .toSet()
              .toList();

          Map<String, dynamic> subjectsMap = {};
          Map<String, dynamic> teachersMap = {};

          if (subjectIds.isNotEmpty) {
            final subjects = await supabase
                .from('subjects')
                .select('id, name, code')
                .inFilter('id', subjectIds);
            for (var s in (subjects as List)) {
              subjectsMap[s['id']] = s;
            }
          }

          if (teacherIds.isNotEmpty) {
            final teachers = await supabase
                .from('users')
                .select('id, full_name')
                .inFilter('id', teacherIds);
            for (var t in (teachers as List)) {
              teachersMap[t['id']] = t;
            }
          }

          return offerings.map((o) {
            final subject = subjectsMap[o['subject_id']];
            final teacher = teachersMap[o['teacher_id']];
            return SubjectOfferingInfo(
              id: o['id']?.toString() ?? '',
              subjectName: subject?['name']?.toString() ?? 'N/A',
              subjectCode: subject?['code']?.toString(),
              teacherName: teacher?['full_name']?.toString(),
            );
          }).toList();
        } catch (e2) {
          debugPrint('classSubjectOfferingsProvider fallback error: $e2');
          return [];
        }
      }
    });

// Timetable slots for selected class
final classTimetableSlotsProvider =
    FutureProvider.family<List<TimetableSlotAdmin>, String>((
      ref,
      classId,
    ) async {
      final supabase = SupabaseConfig.client;

      try {
        // Try with nested relations
        final data = await supabase
            .from('timetable_slots')
            .select(
              '*, subject_offerings!inner(subject_id, class_id, teacher_id, subjects(name, code), classes(id, name), users(full_name))',
            )
            .eq('subject_offerings.class_id', classId)
            .order('day_of_week')
            .order('start_time');

        return (data as List)
            .map((e) => TimetableSlotAdmin.fromJson(e))
            .toList();
      } catch (e) {
        // Fallback: fetch slots and join manually
        debugPrint('classTimetableSlotsProvider error: $e - using fallback');
        try {
          // First get all subject_offerings for this class
          final offerings = await supabase
              .from('subject_offerings')
              .select('id, subject_id, teacher_id')
              .eq('class_id', classId);

          if ((offerings as List).isEmpty) return [];

          final offeringIds = offerings.map((o) => o['id'] as String).toList();

          // Get timetable slots for these offerings
          final slots = await supabase
              .from('timetable_slots')
              .select('*')
              .inFilter('subject_offering_id', offeringIds)
              .order('day_of_week')
              .order('start_time');

          if ((slots as List).isEmpty) return [];

          // Get subjects and teachers
          final subjectIds = offerings
              .map((o) => o['subject_id'])
              .where((id) => id != null)
              .toSet()
              .toList();
          final teacherIds = offerings
              .map((o) => o['teacher_id'])
              .where((id) => id != null)
              .toSet()
              .toList();

          Map<String, dynamic> subjectsMap = {};
          Map<String, dynamic> teachersMap = {};
          Map<String, dynamic> offeringsMap = {};

          for (var o in offerings) {
            offeringsMap[o['id']] = o;
          }

          if (subjectIds.isNotEmpty) {
            final subjects = await supabase
                .from('subjects')
                .select('id, name, code')
                .inFilter('id', subjectIds);
            for (var s in (subjects as List)) {
              subjectsMap[s['id']] = s;
            }
          }

          if (teacherIds.isNotEmpty) {
            final teachers = await supabase
                .from('users')
                .select('id, full_name')
                .inFilter('id', teacherIds);
            for (var t in (teachers as List)) {
              teachersMap[t['id']] = t;
            }
          }

          // Get class info
          final classData = await supabase
              .from('classes')
              .select('id, name')
              .eq('id', classId)
              .maybeSingle();

          return slots.map((slot) {
            final offering = offeringsMap[slot['subject_offering_id']];
            final subject = offering != null
                ? subjectsMap[offering['subject_id']]
                : null;
            final teacher = offering != null
                ? teachersMap[offering['teacher_id']]
                : null;

            return TimetableSlotAdmin(
              id: slot['id']?.toString() ?? '',
              subjectOfferingId: slot['subject_offering_id']?.toString() ?? '',
              dayOfWeek: slot['day_of_week'] ?? 1,
              startTime: slot['start_time']?.toString() ?? '08:00',
              endTime: slot['end_time']?.toString() ?? '09:00',
              room: slot['room']?.toString(),
              subjectName: subject?['name']?.toString(),
              subjectCode: subject?['code']?.toString(),
              className: classData?['name']?.toString(),
              teacherName: teacher?['full_name']?.toString(),
            );
          }).toList();
        } catch (e2) {
          debugPrint('classTimetableSlotsProvider fallback error: $e2');
          return [];
        }
      }
    });

// ===================== CONSTANTS =====================

const List<String> _dayLabels = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];
const List<String> _dayLabelsShort = [
  'Lun',
  'Mar',
  'Mer',
  'Jeu',
  'Ven',
  'Sam',
  'Dim',
];

const List<String> _timeSlots = [
  '08:00',
  '08:30',
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '12:00',
  '12:30',
  '13:00',
  '13:30',
  '14:00',
  '14:30',
  '15:00',
  '15:30',
  '16:00',
  '16:30',
  '17:00',
];

// Subject colors
final Map<String, Color> _subjectColors = {};
Color _getSubjectColor(String code) {
  if (!_subjectColors.containsKey(code)) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
      const Color(0xFF3B82F6),
      const Color(0xFF84CC16),
      const Color(0xFFE11D48),
    ];
    _subjectColors[code] = colors[_subjectColors.length % colors.length];
  }
  return _subjectColors[code]!;
}

// ===================== MAIN SCREEN =====================

// Search/filter provider for classes
final classSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedCycleFilterProvider = StateProvider<String?>(
  (ref) => null,
); // 'base' or 'secondaire'
final selectedNiveauFilterProvider = StateProvider<String?>((ref) => null);
final selectedSectionFilterProvider = StateProvider<String?>((ref) => null);

// Student count per class provider
final classStudentCountProvider = FutureProvider.family<int, String>((
  ref,
  classId,
) async {
  final supabase = SupabaseConfig.client;
  try {
    final result = await supabase
        .from('enrollments')
        .select('id')
        .eq('class_id', classId)
        .eq('is_active', true);
    return (result as List).length;
  } catch (e) {
    return 0;
  }
});

// Timetable search/filter providers
final timetableSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedDayFilterProvider = StateProvider<int?>(
  (ref) => null,
); // 1-6 for Mon-Sat
final selectedSubjectFilterProvider = StateProvider<String?>((ref) => null);

// Filtered classes provider
final filteredClassesProvider = Provider<AsyncValue<List<ClassInfo>>>((ref) {
  final classesAsync = ref.watch(classesListProvider);
  final searchQuery = ref.watch(classSearchQueryProvider).toLowerCase();
  final cycleFilter = ref.watch(selectedCycleFilterProvider);
  final niveauFilter = ref.watch(selectedNiveauFilterProvider);
  final sectionFilter = ref.watch(selectedSectionFilterProvider);

  return classesAsync.whenData((classes) {
    var filtered = classes;

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (c) =>
                c.name.toLowerCase().contains(searchQuery) ||
                (c.gradeLevelCode?.toLowerCase().contains(searchQuery) ??
                    false) ||
                (c.sectionCode?.toLowerCase().contains(searchQuery) ?? false),
          )
          .toList();
    }

    // Filter by cycle (base or secondaire)
    if (cycleFilter != null && cycleFilter.isNotEmpty) {
      filtered = filtered.where((c) => c.cycle == cycleFilter).toList();
    }

    // Filter by niveau
    if (niveauFilter != null && niveauFilter.isNotEmpty) {
      filtered = filtered
          .where((c) => c.gradeLevelCode == niveauFilter)
          .toList();
    }

    // Filter by section (only for secondaire 2eme, 3eme, 4eme)
    if (sectionFilter != null && sectionFilter.isNotEmpty) {
      filtered = filtered.where((c) => c.sectionCode == sectionFilter).toList();
    }

    return filtered;
  });
});

// Filtered timetable slots provider
final filteredTimetableSlotsProvider =
    Provider.family<AsyncValue<List<TimetableSlotAdmin>>, String>((
      ref,
      classId,
    ) {
      final slotsAsync = ref.watch(classTimetableSlotsProvider(classId));
      final searchQuery = ref.watch(timetableSearchQueryProvider).toLowerCase();
      final dayFilter = ref.watch(selectedDayFilterProvider);
      final subjectFilter = ref.watch(selectedSubjectFilterProvider);

      return slotsAsync.whenData((slots) {
        var filtered = slots;

        // Filter by search query (subject name, teacher name, room)
        if (searchQuery.isNotEmpty) {
          filtered = filtered
              .where(
                (s) =>
                    (s.subjectName?.toLowerCase().contains(searchQuery) ??
                        false) ||
                    (s.subjectCode?.toLowerCase().contains(searchQuery) ??
                        false) ||
                    (s.teacherName?.toLowerCase().contains(searchQuery) ??
                        false) ||
                    (s.room?.toLowerCase().contains(searchQuery) ?? false),
              )
              .toList();
        }

        // Filter by day
        if (dayFilter != null) {
          filtered = filtered.where((s) => s.dayOfWeek == dayFilter).toList();
        }

        // Filter by subject
        if (subjectFilter != null && subjectFilter.isNotEmpty) {
          filtered = filtered
              .where(
                (s) =>
                    s.subjectCode == subjectFilter ||
                    s.subjectName == subjectFilter,
              )
              .toList();
        }

        return filtered;
      });
    });

// Get unique niveaux for filter dropdown (filtered by cycle if selected)
final niveauxListProvider = Provider<List<String>>((ref) {
  final classesAsync = ref.watch(classesListProvider);
  final cycleFilter = ref.watch(selectedCycleFilterProvider);

  return classesAsync.when(
    data: (classes) {
      var filtered = classes;
      // Filter by cycle if selected
      if (cycleFilter != null && cycleFilter.isNotEmpty) {
        filtered = filtered.where((c) => c.cycle == cycleFilter).toList();
      }
      final niveaux = filtered
          .map((c) => c.gradeLevelCode)
          .whereType<String>()
          .toSet()
          .toList();
      niveaux.sort();
      return niveaux;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Get unique sections for filter dropdown (only for niveaux with sections)
final sectionsListProvider = Provider<List<String>>((ref) {
  final classesAsync = ref.watch(classesListProvider);
  final niveauFilter = ref.watch(selectedNiveauFilterProvider);

  return classesAsync.when(
    data: (classes) {
      var filtered = classes;
      // Only show sections for classes with niveau that has sections
      filtered = filtered.where((c) => c.hasSections == true).toList();
      // Also filter by niveau if selected
      if (niveauFilter != null && niveauFilter.isNotEmpty) {
        filtered = filtered
            .where((c) => c.gradeLevelCode == niveauFilter)
            .toList();
      }
      final sections = filtered
          .map((c) => c.sectionCode)
          .whereType<String>()
          .toSet()
          .toList();
      sections.sort();
      return sections;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Get unique subjects from current class offerings
final uniqueSubjectsProvider = Provider.family<List<String>, String>((
  ref,
  classId,
) {
  final offeringsAsync = ref.watch(classSubjectOfferingsProvider(classId));
  return offeringsAsync.when(
    data: (offerings) =>
        offerings.map((o) => o.subjectName).toSet().toList()..sort(),
    loading: () => [],
    error: (_, __) => [],
  );
});

class TimetablesScreen extends ConsumerStatefulWidget {
  const TimetablesScreen({super.key});

  @override
  ConsumerState<TimetablesScreen> createState() => _TimetablesScreenState();
}

class _TimetablesScreenState extends ConsumerState<TimetablesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _timetableSearchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _timetableSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(filteredClassesProvider);
    final selectedClass = ref.watch(selectedClassProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/timetables'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left sidebar - Class selector
                        SizedBox(
                          width: 280,
                          child: _buildClassSelector(
                            classesAsync,
                            selectedClass,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Main content - Timetable grid
                        Expanded(
                          child: selectedClass != null
                              ? _buildTimetableEditor(selectedClass)
                              : _buildNoClassSelected(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final selectedClass = ref.watch(selectedClassProvider);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Gestion des emplois du temps',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (selectedClass != null)
                Text(
                  'Classe: ${selectedClass.name}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
            ],
          ),
          const Spacer(),
          // Get suggested subjects button
          if (selectedClass != null)
            ElevatedButton.icon(
              onPressed: () => _showSuggestedSubjects(selectedClass),
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: const Text('Matières suggérées'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassSelector(
    AsyncValue<List<ClassInfo>> classesAsync,
    ClassInfo? selectedClass,
  ) {
    final niveaux = ref.watch(niveauxListProvider);
    final sections = ref.watch(sectionsListProvider);
    final selectedCycle = ref.watch(selectedCycleFilterProvider);
    final selectedNiveau = ref.watch(selectedNiveauFilterProvider);
    final selectedSection = ref.watch(selectedSectionFilterProvider);
    final searchQuery = ref.watch(classSearchQueryProvider);

    // Check if sections should be shown (only when niveau has sections)
    final showSections = sections.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sélectionner une classe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      ref.read(classSearchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                      .read(classSearchQueryProvider.notifier)
                                      .state =
                                  '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                // Cycle filter dropdown (Base / Secondaire)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.indigo.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedCycle,
                      isExpanded: true,
                      hint: Text(
                        'Tous les cycles',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.indigo[400],
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.indigo[400],
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.indigo[700],
                        fontWeight: FontWeight.w500,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Tous les cycles',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'base',
                          child: Row(
                            children: [
                              Icon(
                                Icons.looks_one_rounded,
                                size: 16,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Base (7ème - 9ème)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'secondaire',
                          child: Row(
                            children: [
                              Icon(
                                Icons.looks_two_rounded,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Secondaire (1ère - 4ème)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        ref.read(selectedCycleFilterProvider.notifier).state =
                            v;
                        // Reset niveau and section when cycle changes
                        ref.read(selectedNiveauFilterProvider.notifier).state =
                            null;
                        ref.read(selectedSectionFilterProvider.notifier).state =
                            null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Niveau filter dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedNiveau,
                      isExpanded: true,
                      hint: Text(
                        'Tous les niveaux',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[500],
                      ),
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Tous les niveaux',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        ...niveaux.map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text(
                              n,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          ref
                                  .read(selectedNiveauFilterProvider.notifier)
                                  .state =
                              v,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Section filter dropdown - only show if sections exist for selected niveau
                if (showSections)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedSection,
                        isExpanded: true,
                        hint: Text(
                          'Toutes les sections',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[400],
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.orange[400],
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Toutes les sections',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          ...sections.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            ref
                                    .read(
                                      selectedSectionFilterProvider.notifier,
                                    )
                                    .state =
                                v,
                      ),
                    ),
                  ),
                // Active filters chip
                if (searchQuery.isNotEmpty ||
                    selectedCycle != null ||
                    selectedNiveau != null ||
                    selectedSection != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (selectedCycle != null)
                        _buildFilterChip(
                          label:
                              'Cycle: ${selectedCycle == 'base' ? 'Base' : 'Secondaire'}',
                          onRemove: () {
                            ref
                                    .read(selectedCycleFilterProvider.notifier)
                                    .state =
                                null;
                            ref
                                    .read(selectedNiveauFilterProvider.notifier)
                                    .state =
                                null;
                            ref
                                    .read(
                                      selectedSectionFilterProvider.notifier,
                                    )
                                    .state =
                                null;
                          },
                          color: Colors.indigo,
                        ),
                      if (selectedNiveau != null)
                        _buildFilterChip(
                          label: 'Niveau: $selectedNiveau',
                          onRemove: () =>
                              ref
                                      .read(
                                        selectedNiveauFilterProvider.notifier,
                                      )
                                      .state =
                                  null,
                        ),
                      if (selectedSection != null)
                        _buildFilterChip(
                          label: 'Section: $selectedSection',
                          onRemove: () =>
                              ref
                                      .read(
                                        selectedSectionFilterProvider.notifier,
                                      )
                                      .state =
                                  null,
                          color: Colors.orange,
                        ),
                      if (searchQuery.isNotEmpty)
                        _buildFilterChip(
                          label: 'Recherche: $searchQuery',
                          onRemove: () {
                            _searchController.clear();
                            ref.read(classSearchQueryProvider.notifier).state =
                                '';
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: classesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (classes) {
                if (classes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.class_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          searchQuery.isNotEmpty ||
                                  selectedCycle != null ||
                                  selectedNiveau != null ||
                                  selectedSection != null
                              ? 'Aucun résultat'
                              : 'Aucune classe',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        if (searchQuery.isNotEmpty ||
                            selectedCycle != null ||
                            selectedNiveau != null ||
                            selectedSection != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              ref
                                      .read(classSearchQueryProvider.notifier)
                                      .state =
                                  '';
                              ref
                                      .read(
                                        selectedCycleFilterProvider.notifier,
                                      )
                                      .state =
                                  null;
                              ref
                                      .read(
                                        selectedNiveauFilterProvider.notifier,
                                      )
                                      .state =
                                  null;
                              ref
                                      .read(
                                        selectedSectionFilterProvider.notifier,
                                      )
                                      .state =
                                  null;
                            },
                            child: const Text('Effacer les filtres'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Group by grade level
                final groupedClasses = <String, List<ClassInfo>>{};
                for (final cls in classes) {
                  final key = cls.gradeLevelCode ?? 'Autre';
                  groupedClasses.putIfAbsent(key, () => []).add(cls);
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: groupedClasses.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...entry.value.map((cls) {
                          final isSelected = selectedClass?.id == cls.id;
                          return Consumer(
                            builder: (context, ref, _) {
                              final studentCountAsync = ref.watch(
                                classStudentCountProvider(cls.id),
                              );
                              final studentCount = studentCountAsync.when(
                                data: (count) => count,
                                loading: () => null,
                                error: (_, __) => 0,
                              );

                              return GestureDetector(
                                onTap: () =>
                                    ref
                                            .read(
                                              selectedClassProvider.notifier,
                                            )
                                            .state =
                                        cls,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF8B5CF6),
                                              Color(0xFF7C3AED),
                                            ],
                                          )
                                        : null,
                                    color: isSelected ? null : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            cls.name.substring(0, 1),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cls.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[800],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                if (cls.sectionCode != null)
                                                  Text(
                                                    cls.sectionCode!,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isSelected
                                                          ? Colors.white70
                                                          : Colors.grey[500],
                                                    ),
                                                  ),
                                                if (cls.sectionCode != null &&
                                                    studentCount != null)
                                                  Text(
                                                    ' • ',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isSelected
                                                          ? Colors.white70
                                                          : Colors.grey[400],
                                                    ),
                                                  ),
                                                if (studentCount != null)
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.people_outline,
                                                        size: 12,
                                                        color: isSelected
                                                            ? Colors.white70
                                                            : Colors.grey[500],
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '$studentCount élèves',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isSelected
                                                              ? Colors.white70
                                                              : Colors
                                                                    .grey[500],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
    Color? color,
  }) {
    final chipColor = color ?? const Color(0xFF8B5CF6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: chipColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoClassSelected() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 64,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sélectionnez une classe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez une classe dans la liste pour gérer son emploi du temps',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableEditor(ClassInfo selectedClass) {
    final slotsAsync = ref.watch(
      filteredTimetableSlotsProvider(selectedClass.id),
    );
    final allSlotsAsync = ref.watch(
      classTimetableSlotsProvider(selectedClass.id),
    );
    final offeringsAsync = ref.watch(
      classSubjectOfferingsProvider(selectedClass.id),
    );
    final subjects = ref.watch(uniqueSubjectsProvider(selectedClass.id));
    final searchQuery = ref.watch(timetableSearchQueryProvider);
    final dayFilter = ref.watch(selectedDayFilterProvider);
    final subjectFilter = ref.watch(selectedSubjectFilterProvider);
    final hasFilters =
        searchQuery.isNotEmpty || dayFilter != null || subjectFilter != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emploi du temps: ${selectedClass.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Cliquez sur une cellule vide pour ajouter un cours',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bulk upload button
                    OutlinedButton.icon(
                      onPressed: () => _showBulkUploadDialog(
                        selectedClass,
                        offeringsAsync.value ?? [],
                      ),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Import CSV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        side: const BorderSide(color: Color(0xFF8B5CF6)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add course button
                    ElevatedButton.icon(
                      onPressed: () {
                        final offerings = offeringsAsync.hasValue
                            ? offeringsAsync.value!
                            : <SubjectOfferingInfo>[];
                        _showAddSlotDialog(selectedClass, offerings);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter un cours'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Smart search row
                Row(
                  children: [
                    // Search field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _timetableSearchController,
                        onChanged: (v) =>
                            ref
                                    .read(timetableSearchQueryProvider.notifier)
                                    .state =
                                v,
                        decoration: InputDecoration(
                          hintText: 'Rechercher matière, prof, salle...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey[400],
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _timetableSearchController.clear();
                                    ref
                                            .read(
                                              timetableSearchQueryProvider
                                                  .notifier,
                                            )
                                            .state =
                                        '';
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Day filter
                    Container(
                      width: 130,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: dayFilter,
                          isExpanded: true,
                          hint: Text(
                            'Jour',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'Tous',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            ...List.generate(
                              6,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(
                                  _dayLabelsShort[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              ref
                                      .read(selectedDayFilterProvider.notifier)
                                      .state =
                                  v,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Subject filter
                    Container(
                      width: 160,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: subjectFilter,
                          isExpanded: true,
                          hint: Text(
                            'Matière',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Toutes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            ...subjects.map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.length > 15
                                      ? '${s.substring(0, 15)}...'
                                      : s,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              ref
                                      .read(
                                        selectedSubjectFilterProvider.notifier,
                                      )
                                      .state =
                                  v,
                        ),
                      ),
                    ),
                  ],
                ),
                // Active filters
                if (hasFilters) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Filtres actifs:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      if (dayFilter != null)
                        _buildTimetableFilterChip(
                          label: _dayLabels[dayFilter - 1],
                          onRemove: () =>
                              ref
                                      .read(selectedDayFilterProvider.notifier)
                                      .state =
                                  null,
                        ),
                      if (subjectFilter != null) ...[
                        const SizedBox(width: 6),
                        _buildTimetableFilterChip(
                          label: subjectFilter.length > 12
                              ? '${subjectFilter.substring(0, 12)}...'
                              : subjectFilter,
                          onRemove: () =>
                              ref
                                      .read(
                                        selectedSubjectFilterProvider.notifier,
                                      )
                                      .state =
                                  null,
                        ),
                      ],
                      if (searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildTimetableFilterChip(
                          label: '"$searchQuery"',
                          onRemove: () {
                            _timetableSearchController.clear();
                            ref
                                    .read(timetableSearchQueryProvider.notifier)
                                    .state =
                                '';
                          },
                        ),
                      ],
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          _timetableSearchController.clear();
                          ref
                                  .read(timetableSearchQueryProvider.notifier)
                                  .state =
                              '';
                          ref.read(selectedDayFilterProvider.notifier).state =
                              null;
                          ref
                                  .read(selectedSubjectFilterProvider.notifier)
                                  .state =
                              null;
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Effacer'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Timetable grid
          Expanded(
            child: allSlotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (allSlots) {
                final filteredSlots = slotsAsync.hasValue
                    ? slotsAsync.value!
                    : allSlots;
                final offerings = offeringsAsync.hasValue
                    ? offeringsAsync.value!
                    : <SubjectOfferingInfo>[];
                return _buildGrid(
                  hasFilters ? filteredSlots : allSlots,
                  selectedClass,
                  offerings,
                  highlightSlots: hasFilters ? filteredSlots : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: const Color(0xFF10B981).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    List<TimetableSlotAdmin> slots,
    ClassInfo selectedClass,
    List<SubjectOfferingInfo> offerings, {
    List<TimetableSlotAdmin>? highlightSlots,
  }) {
    const timeColumnWidth = 60.0;
    const cellHeight = 60.0;
    const dayHeaderHeight = 50.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - timeColumnWidth - 32;
        final cellWidth = availableWidth / 6; // 6 days (Mon-Sat)

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day headers
                Row(
                  children: [
                    SizedBox(width: timeColumnWidth, height: dayHeaderHeight),
                    ...List.generate(
                      6,
                      (dayIndex) => Container(
                        width: cellWidth,
                        height: dayHeaderHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: dayIndex == 0
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                )
                              : dayIndex == 5
                              ? const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                )
                              : null,
                        ),
                        child: Text(
                          _dayLabelsShort[dayIndex],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Time rows
                ...List.generate(_timeSlots.length - 1, (timeIndex) {
                  final timeStart = _timeSlots[timeIndex];

                  return Row(
                    children: [
                      // Time label
                      Container(
                        width: timeColumnWidth,
                        height: cellHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Text(
                          timeStart,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // Day cells
                      ...List.generate(6, (dayIndex) {
                        final slot = _findSlot(slots, dayIndex + 1, timeStart);
                        final isSlotStart =
                            slot != null && slot.startTime == timeStart;

                        if (slot != null && !isSlotStart) {
                          return const SizedBox.shrink();
                        }

                        if (isSlotStart) {
                          final spanCount = _calculateSpan(slot);
                          final color = _getSubjectColor(
                            slot.subjectCode ?? 'default',
                          );

                          return GestureDetector(
                            onTap: () => _showSlotOptions(slot),
                            child: Container(
                              width: cellWidth - 4,
                              height: cellHeight * spanCount - 4,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [color, color.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.subjectCode ?? 'N/A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (spanCount > 1) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      slot.room ?? '',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        // Empty cell - clickable to add
                        return GestureDetector(
                          onTap: () => _showAddSlotDialogForCell(
                            selectedClass,
                            offerings,
                            dayIndex + 1,
                            timeStart,
                          ),
                          child: Container(
                            width: cellWidth - 4,
                            height: cellHeight - 4,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  TimetableSlotAdmin? _findSlot(
    List<TimetableSlotAdmin> slots,
    int dayOfWeek,
    String time,
  ) {
    for (final slot in slots) {
      if (slot.dayOfWeek == dayOfWeek) {
        final slotStart = _timeToMinutes(slot.startTime);
        final slotEnd = _timeToMinutes(slot.endTime);
        final cellTime = _timeToMinutes(time);

        if (cellTime >= slotStart && cellTime < slotEnd) {
          return slot;
        }
      }
    }
    return null;
  }

  int _calculateSpan(TimetableSlotAdmin slot) {
    final start = _timeToMinutes(slot.startTime);
    final end = _timeToMinutes(slot.endTime);
    return ((end - start) / 30).ceil();
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _showSlotOptions(TimetableSlotAdmin slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSubjectColor(
                  slot.subjectCode ?? 'default',
                ).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: _getSubjectColor(slot.subjectCode ?? 'default'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.subjectName ?? 'N/A',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${_dayLabels[slot.dayOfWeek - 1]} ${slot.startTime} - ${slot.endTime}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot.room != null)
              _buildInfoRow(Icons.room, 'Salle', slot.room!),
            if (slot.teacherName != null)
              _buildInfoRow(Icons.person, 'Professeur', slot.teacherName!),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteSlot(slot);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _deleteSlot(TimetableSlotAdmin slot) async {
    try {
      await SupabaseConfig.client
          .from('timetable_slots')
          .delete()
          .eq('id', slot.id);
      ref.invalidate(classTimetableSlotsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddSlotDialog(
    ClassInfo selectedClass,
    List<SubjectOfferingInfo> offerings,
  ) {
    _showAddSlotDialogForCell(selectedClass, offerings, 1, '08:00');
  }

  void _showAddSlotDialogForCell(
    ClassInfo selectedClass,
    List<SubjectOfferingInfo> offerings,
    int dayOfWeek,
    String startTime,
  ) {
    if (offerings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucune matière configurée pour cette classe. Configurez d\'abord les offres de matières.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    SubjectOfferingInfo? selectedOffering;
    String selectedDay = _dayLabels[dayOfWeek - 1];
    String selectedStartTime = startTime;
    String selectedEndTime = _getNextTimeSlot(startTime, 2);
    String? room;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Ajouter un cours'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subject dropdown
                DropdownButtonFormField<SubjectOfferingInfo>(
                  value: selectedOffering,
                  decoration: InputDecoration(
                    labelText: 'Matière',
                    prefixIcon: const Icon(Icons.book_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: offerings
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Text('${o.subjectCode} - ${o.subjectName}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedOffering = v),
                ),
                const SizedBox(height: 16),
                // Day dropdown
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: InputDecoration(
                    labelText: 'Jour',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _dayLabels
                      .take(6)
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedDay = v!),
                ),
                const SizedBox(height: 16),
                // Time row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStartTime,
                        decoration: InputDecoration(
                          labelText: 'Début',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: _timeSlots
                            .take(_timeSlots.length - 1)
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setDialogState(() {
                          selectedStartTime = v!;
                          selectedEndTime = _getNextTimeSlot(v, 2);
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedEndTime,
                        decoration: InputDecoration(
                          labelText: 'Fin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: _timeSlots
                            .skip(1)
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedEndTime = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Room
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Salle (optionnel)',
                    prefixIcon: const Icon(Icons.room_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) => room = v.isEmpty ? null : v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedOffering == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _createSlot(
                        selectedOffering!.id,
                        _dayLabels.indexOf(selectedDay) + 1,
                        selectedStartTime,
                        selectedEndTime,
                        room,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  String _getNextTimeSlot(String time, int slotsAhead) {
    final index = _timeSlots.indexOf(time);
    if (index >= 0 && index + slotsAhead < _timeSlots.length) {
      return _timeSlots[index + slotsAhead];
    }
    return _timeSlots.last;
  }

  Future<void> _createSlot(
    String subjectOfferingId,
    int dayOfWeek,
    String startTime,
    String endTime,
    String? room,
  ) async {
    try {
      await SupabaseConfig.client.from('timetable_slots').insert({
        'subject_offering_id': subjectOfferingId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'room': room,
      });
      ref.invalidate(classTimetableSlotsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours ajouté'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuggestedSubjects(ClassInfo selectedClass) {
    // Get suggested subjects based on niveau (grade level code)
    List<SubjectCoefficient> suggested = [];
    final code = selectedClass.gradeLevelCode?.toUpperCase() ?? '';

    if (code.contains('7') || code.contains('8') || code.contains('9')) {
      suggested = TunisianCoefficientTables.collegeSubjects;
    } else if (code.contains('1') &&
        (code.contains('S') || code.contains('L'))) {
      suggested = TunisianCoefficientTables.lycee1Subjects;
    } else if (code.contains('2')) {
      if (code.contains('M') || code.contains('MATH')) {
        suggested = TunisianCoefficientTables.lycee2MathSubjects;
      } else if (code.contains('SC') || code.contains('EXP')) {
        suggested = TunisianCoefficientTables.lycee2SciencesSubjects;
      } else if (code.contains('T') || code.contains('TECH')) {
        suggested = TunisianCoefficientTables.lycee2TechSubjects;
      } else if (code.contains('E') || code.contains('ECO')) {
        suggested = TunisianCoefficientTables.lycee2EcoSubjects;
      } else if (code.contains('L') || code.contains('LET')) {
        suggested = TunisianCoefficientTables.lycee2LettresSubjects;
      } else {
        suggested = TunisianCoefficientTables.lycee1Subjects;
      }
    } else {
      suggested = TunisianCoefficientTables.collegeSubjects;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lightbulb, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Matières suggérées'),
                Text(
                  'Niveau: ${selectedClass.gradeLevelCode ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView.builder(
            itemCount: suggested.length,
            itemBuilder: (context, index) {
              final subject = suggested[index];
              final color = _getSubjectColor(subject.subjectCode);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          subject.subjectCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.subjectName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Coef: ${subject.coefficient}${subject.hasPractical ? ' • TP' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showBulkUploadDialog(
    ClassInfo selectedClass,
    List<SubjectOfferingInfo> offerings,
  ) {
    final csvController = TextEditingController();
    List<Map<String, dynamic>> parsedRows = [];
    String? parseError;
    bool isParsed = false;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.upload_file, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 12),
              const Text('Import CSV - Emploi du temps'),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Format CSV',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Colonnes: matiere_code, jour (1-6), debut (HH:MM), fin (HH:MM), salle\n'
                        'Exemple: MATH,1,08:00,09:30,Salle A1',
                        style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Available subjects
                ExpansionTile(
                  title: const Text(
                    'Matières disponibles',
                    style: TextStyle(fontSize: 13),
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  children: [
                    Container(
                      height: 100,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        children: offerings
                            .map(
                              (o) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${o.subjectCode} - ${o.subjectName}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // CSV input
                TextField(
                  controller: csvController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        'Collez vos données CSV ici...\nMATH,1,08:00,09:30,Salle A1\nPHYS,1,09:30,11:00,Labo 2',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                // Parse button
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        final result = _parseCSV(csvController.text, offerings);
                        setDialogState(() {
                          parsedRows =
                              result['rows'] as List<Map<String, dynamic>>;
                          parseError = result['error'] as String?;
                          isParsed = parsedRows.isNotEmpty;
                        });
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Valider'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (parseError != null)
                      Expanded(
                        child: Text(
                          parseError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (isParsed && parseError == null)
                      Expanded(
                        child: Text(
                          '✓ ${parsedRows.length} cours prêts à importer',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                // Preview table
                if (isParsed && parsedRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 32,
                        dataRowMinHeight: 28,
                        dataRowMaxHeight: 32,
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Matière',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          DataColumn(
                            label: Text('Jour', style: TextStyle(fontSize: 11)),
                          ),
                          DataColumn(
                            label: Text(
                              'Début',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          DataColumn(
                            label: Text('Fin', style: TextStyle(fontSize: 11)),
                          ),
                          DataColumn(
                            label: Text(
                              'Salle',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                        rows: parsedRows
                            .map(
                              (row) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      row['subject_name'] ?? '',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _dayLabelsShort[(row['day'] as int) - 1],
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      row['start'] ?? '',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      row['end'] ?? '',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      row['room'] ?? '-',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: (!isParsed || parsedRows.isEmpty || isUploading)
                  ? null
                  : () async {
                      setDialogState(() => isUploading = true);
                      await _bulkCreateSlots(parsedRows);
                      if (context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Importer ${parsedRows.length} cours'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _parseCSV(
    String csv,
    List<SubjectOfferingInfo> offerings,
  ) {
    final rows = <Map<String, dynamic>>[];
    final lines = csv
        .trim()
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return {'rows': rows, 'error': 'Aucune donnée'};
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final parts = line.split(',').map((p) => p.trim()).toList();

      if (parts.length < 4) {
        return {
          'rows': <Map<String, dynamic>>[],
          'error': 'Ligne ${i + 1}: format invalide (4 colonnes minimum)',
        };
      }

      final subjectCode = parts[0].toUpperCase();
      final dayStr = parts[1];
      final start = parts[2];
      final end = parts[3];
      final room = parts.length > 4 ? parts[4] : null;

      // Find matching offering
      final offering = offerings.firstWhere(
        (o) =>
            o.subjectCode?.toUpperCase() == subjectCode ||
            o.subjectName.toUpperCase() == subjectCode,
        orElse: () => SubjectOfferingInfo(id: '', subjectName: ''),
      );

      if (offering.id.isEmpty) {
        return {
          'rows': <Map<String, dynamic>>[],
          'error': 'Ligne ${i + 1}: matière "$subjectCode" non trouvée',
        };
      }

      final day = int.tryParse(dayStr);
      if (day == null || day < 1 || day > 6) {
        return {
          'rows': <Map<String, dynamic>>[],
          'error': 'Ligne ${i + 1}: jour invalide "$dayStr" (1-6)',
        };
      }

      // Validate time format
      if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(start)) {
        return {
          'rows': <Map<String, dynamic>>[],
          'error': 'Ligne ${i + 1}: heure début invalide "$start"',
        };
      }
      if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(end)) {
        return {
          'rows': <Map<String, dynamic>>[],
          'error': 'Ligne ${i + 1}: heure fin invalide "$end"',
        };
      }

      rows.add({
        'offering_id': offering.id,
        'subject_name': offering.subjectName,
        'day': day,
        'start': start,
        'end': end,
        'room': room?.isEmpty == true ? null : room,
      });
    }

    return {'rows': rows, 'error': null};
  }

  Future<void> _bulkCreateSlots(List<Map<String, dynamic>> rows) async {
    try {
      final inserts = rows
          .map(
            (row) => {
              'subject_offering_id': row['offering_id'],
              'day_of_week': row['day'],
              'start_time': row['start'],
              'end_time': row['end'],
              'room': row['room'],
            },
          )
          .toList();

      await SupabaseConfig.client.from('timetable_slots').insert(inserts);
      ref.invalidate(classTimetableSlotsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${rows.length} cours importés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
