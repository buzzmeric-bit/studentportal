import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/curriculum_models.dart';

/// Provider for Tunisian education curriculum data
final curriculumProvider =
    AsyncNotifierProvider<CurriculumNotifier, CurriculumState>(
      CurriculumNotifier.new,
    );

class CurriculumState {
  final List<NiveauModel> niveaux;
  final List<SectionModel> sections;
  final List<SubjectModel> subjects;
  final List<CurriculumModel> curriculum;
  final bool isLoading;

  CurriculumState({
    this.niveaux = const [],
    this.sections = const [],
    this.subjects = const [],
    this.curriculum = const [],
    this.isLoading = false,
  });

  CurriculumState copyWith({
    List<NiveauModel>? niveaux,
    List<SectionModel>? sections,
    List<SubjectModel>? subjects,
    List<CurriculumModel>? curriculum,
    bool? isLoading,
  }) {
    return CurriculumState(
      niveaux: niveaux ?? this.niveaux,
      sections: sections ?? this.sections,
      subjects: subjects ?? this.subjects,
      curriculum: curriculum ?? this.curriculum,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get college niveaux (7ème, 8ème, 9ème)
  List<NiveauModel> get collegeNiveaux =>
      niveaux.where((n) => n.isCollege).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  /// Get lycée niveaux
  List<NiveauModel> get lyceeNiveaux =>
      niveaux.where((n) => n.isLycee).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  /// Get niveaux that require section selection
  List<NiveauModel> get niveauxWithSections =>
      niveaux.where((n) => n.hasSections).toList();

  /// Get subjects for a specific niveau and section
  List<CurriculumModel> getSubjectsFor(
    String niveauCode, [
    String? sectionCode,
  ]) {
    return curriculum
        .where(
          (c) =>
              c.niveauCode == niveauCode &&
              (sectionCode == null || c.sectionCode == sectionCode),
        )
        .toList()
      ..sort((a, b) => (b.coefficient).compareTo(a.coefficient));
  }

  /// Find niveau by code
  NiveauModel? getNiveauByCode(String? code) {
    if (code == null) return null;
    try {
      return niveaux.firstWhere((n) => n.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Find section by code
  SectionModel? getSectionByCode(String? code) {
    if (code == null) return null;
    try {
      return sections.firstWhere((s) => s.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Find subject by code
  SubjectModel? getSubjectByCode(String? code) {
    if (code == null) return null;
    try {
      return subjects.firstWhere((s) => s.code == code);
    } catch (_) {
      return null;
    }
  }
}

class CurriculumNotifier extends AsyncNotifier<CurriculumState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<CurriculumState> build() async {
    return await loadAll();
  }

  Future<CurriculumState> loadAll() async {
    try {
      // Load all data in parallel
      final results = await Future.wait([
        _supabase.from('niveaux').select().order('display_order'),
        _supabase.from('sections').select().order('display_order'),
        _supabase.from('subjects').select(),
        _supabase.from('curriculum').select('*, subjects(*)'),
      ]);

      final niveaux = (results[0] as List)
          .map((json) => NiveauModel.fromJson(json))
          .toList();
      final sections = (results[1] as List)
          .map((json) => SectionModel.fromJson(json))
          .toList();
      final subjects = (results[2] as List)
          .map((json) => SubjectModel.fromJson(json))
          .toList();
      final curriculum = (results[3] as List)
          .map((json) => CurriculumModel.fromJson(json))
          .toList();

      return CurriculumState(
        niveaux: niveaux,
        sections: sections,
        subjects: subjects,
        curriculum: curriculum,
      );
    } catch (e) {
      // Return fallback static data if database tables don't exist yet
      return _getFallbackData();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await loadAll());
  }

  /// Fallback static data for when DB tables don't exist
  CurriculumState _getFallbackData() {
    return CurriculumState(
      niveaux: [
        NiveauModel(
          id: '1',
          code: '7B',
          name: '7ème Année de Base',
          cycle: 'base',
          orderIndex: 1,
        ),
        NiveauModel(
          id: '2',
          code: '8B',
          name: '8ème Année de Base',
          cycle: 'base',
          orderIndex: 2,
        ),
        NiveauModel(
          id: '3',
          code: '9B',
          name: '9ème Année de Base',
          cycle: 'base',
          orderIndex: 3,
        ),
        NiveauModel(
          id: '4',
          code: '1S',
          name: '1ère Année Secondaire (Tronc Commun)',
          cycle: 'secondaire',
          orderIndex: 4,
        ),
        NiveauModel(
          id: '5',
          code: '2S',
          name: '2ème Année Secondaire',
          cycle: 'secondaire',
          orderIndex: 5,
          hasSections: true,
        ),
        NiveauModel(
          id: '6',
          code: '3S',
          name: '3ème Année Secondaire',
          cycle: 'secondaire',
          orderIndex: 6,
          hasSections: true,
        ),
        NiveauModel(
          id: '7',
          code: '4S',
          name: '4ème Année (Bac)',
          cycle: 'secondaire',
          orderIndex: 7,
          hasSections: true,
        ),
      ],
      sections: [
        SectionModel(
          id: '1',
          code: 'M',
          name: 'Mathématiques',
          shortName: 'Math',
          color: '#EF4444',
        ),
        SectionModel(
          id: '2',
          code: 'SE',
          name: 'Sciences Expérimentales',
          shortName: 'Sc.Exp',
          color: '#22C55E',
        ),
        SectionModel(
          id: '3',
          code: 'T',
          name: 'Sciences Techniques',
          shortName: 'Tech',
          color: '#F59E0B',
        ),
        SectionModel(
          id: '4',
          code: 'I',
          name: 'Sciences de l\'Informatique',
          shortName: 'Info',
          color: '#6366F1',
        ),
        SectionModel(
          id: '5',
          code: 'E',
          name: 'Économie et Gestion',
          shortName: 'Éco',
          color: '#8B5CF6',
        ),
        SectionModel(
          id: '6',
          code: 'L',
          name: 'Lettres',
          shortName: 'Lettres',
          color: '#EC4899',
        ),
      ],
      subjects: [],
      curriculum: [],
    );
  }
}

/// Static list of niveaux for use in dropdowns before DB is loaded
/// Tunisian Education: 3 niveaux de base + 4 niveaux secondaire
const List<Map<String, dynamic>> niveauxList = [
  // Collège - niveaux de base (pas de sections)
  {
    'code': '7B',
    'name': '7ème Année de Base',
    'cycle': 'base',
    'has_sections': false,
  },
  {
    'code': '8B',
    'name': '8ème Année de Base',
    'cycle': 'base',
    'has_sections': false,
  },
  {
    'code': '9B',
    'name': '9ème Année de Base',
    'cycle': 'base',
    'has_sections': false,
  },
  // Lycée - secondaire
  {
    'code': '1S',
    'name': '1ère Année Secondaire (Tronc Commun)',
    'cycle': 'secondaire',
    'has_sections': false,
  },
  {
    'code': '2S',
    'name': '2ème Année Secondaire',
    'cycle': 'secondaire',
    'has_sections': true,
  },
  {
    'code': '3S',
    'name': '3ème Année Secondaire',
    'cycle': 'secondaire',
    'has_sections': true,
  },
  {
    'code': '4S',
    'name': '4ème Année (Bac)',
    'cycle': 'secondaire',
    'has_sections': true,
  },
];

/// Static list of sections for use in dropdowns (only 6 sections for 2ème, 3ème, 4ème)
const List<Map<String, dynamic>> sectionsList = [
  {'code': 'M', 'name': 'Mathématiques', 'short': 'Math', 'color': '#EF4444'},
  {
    'code': 'SE',
    'name': 'Sciences Expérimentales',
    'short': 'Sc.Exp',
    'color': '#22C55E',
  },
  {
    'code': 'T',
    'name': 'Sciences Techniques',
    'short': 'Tech',
    'color': '#F59E0B',
  },
  {
    'code': 'I',
    'name': 'Sciences de l\'Informatique',
    'short': 'Info',
    'color': '#6366F1',
  },
  {
    'code': 'E',
    'name': 'Économie et Gestion',
    'short': 'Éco',
    'color': '#8B5CF6',
  },
  {'code': 'L', 'name': 'Lettres', 'short': 'Lettres', 'color': '#EC4899'},
];

/// Check if a niveau requires section selection (2ème, 3ème, 4ème only)
bool niveauRequiresSection(String? niveauCode) {
  return niveauCode == '2S' || niveauCode == '3S' || niveauCode == '4S';
}

/// Get short display name for niveau
String getNiveauShortName(String? code) {
  switch (code) {
    case '7B':
      return '7ème';
    case '8B':
      return '8ème';
    case '9B':
      return '9ème';
    case '1S':
      return '1ère';
    case '2S':
      return '2ème';
    case '3S':
      return '3ème';
    case '4S':
      return 'Bac';
    default:
      return code ?? '';
  }
}

/// Get full name for niveau
String getNiveauFullName(String? code) {
  final niveau = niveauxList.firstWhere(
    (n) => n['code'] == code,
    orElse: () => {'name': code ?? ''},
  );
  return niveau['name'] as String;
}

/// Get section short name
String getSectionShortName(String? code) {
  final section = sectionsList.firstWhere(
    (s) => s['code'] == code,
    orElse: () => {'short': code ?? ''},
  );
  return section['short'] as String;
}

/// Get section full name
String getSectionFullName(String? code) {
  final section = sectionsList.firstWhere(
    (s) => s['code'] == code,
    orElse: () => {'name': code ?? ''},
  );
  return section['name'] as String;
}
