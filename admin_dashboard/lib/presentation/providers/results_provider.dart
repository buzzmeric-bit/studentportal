import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/grading_config_model.dart';
import '../../data/models/student_result_model.dart';
import '../../data/models/tunisian_coefficients.dart';
import '../../repositories/results_repository.dart';

/// Filter options for results
enum ResultsFilterType {
  byStudent, // Single student
  byClass, // By class
  byGradeLevel, // By grade level (all classes)
  bySchool, // Entire school
}

/// View mode for results
enum ResultsViewMode {
  table, // Table view
  cards, // Card view
  bulletin, // Report card view
}

/// Provider for managing results/grades
class ResultsProvider extends ChangeNotifier {
  final ResultsRepository _repository;

  ResultsProvider(SupabaseClient client)
    : _repository = ResultsRepository(client);

  // State
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _selectedAcademicYearId;
  String? _selectedSemesterId;
  String? _selectedClassId;
  String? _selectedGroupId;
  String _searchQuery = '';
  ResultsFilterType _filterType = ResultsFilterType.byClass;
  ResultsViewMode _viewMode = ResultsViewMode.table;

  // Data
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _semesters = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _subjectOfferings = [];
  List<Map<String, dynamic>> _enrolledStudents = [];

  // Results
  ClassResult? _classResult;
  StudentResult? _selectedStudentResult;
  GradingConfiguration? _gradingConfig;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get selectedAcademicYearId => _selectedAcademicYearId;
  String? get selectedSemesterId => _selectedSemesterId;
  String? get selectedClassId => _selectedClassId;
  String? get selectedGroupId => _selectedGroupId;
  String get searchQuery => _searchQuery;
  ResultsFilterType get filterType => _filterType;
  ResultsViewMode get viewMode => _viewMode;

  List<Map<String, dynamic>> get academicYears => _academicYears;
  List<Map<String, dynamic>> get semesters => _semesters;
  List<Map<String, dynamic>> get classes => _classes;
  List<Map<String, dynamic>> get groups => _groups;
  List<Map<String, dynamic>> get subjectOfferings => _subjectOfferings;
  List<Map<String, dynamic>> get enrolledStudents => _enrolledStudents;

  ClassResult? get classResult => _classResult;
  StudentResult? get selectedStudentResult => _selectedStudentResult;
  GradingConfiguration? get gradingConfig => _gradingConfig;

  /// Get current academic year name
  String get currentAcademicYearName {
    if (_selectedAcademicYearId == null) return '';
    final year = _academicYears.firstWhere(
      (y) => y['id'] == _selectedAcademicYearId,
      orElse: () => {},
    );
    return year['name'] ?? '';
  }

  /// Get current class name
  String get currentClassName {
    if (_selectedClassId == null) return '';
    final cls = _classes.firstWhere(
      (c) => c['id'] == _selectedClassId,
      orElse: () => {},
    );
    return cls['name'] ?? '';
  }

  /// Get current group name
  String get currentGroupName {
    if (_selectedGroupId == null) return 'Tous les groupes';
    final group = _groups.firstWhere(
      (g) => g['id'] == _selectedGroupId,
      orElse: () => {},
    );
    return group['name'] ?? '';
  }

  /// Get filtered students based on search
  List<StudentResult> get filteredStudents {
    if (_classResult == null) return [];

    if (_searchQuery.isEmpty) {
      return _classResult!.students;
    }

    final query = _searchQuery.toLowerCase();
    return _classResult!.students.where((s) {
      return s.studentName.toLowerCase().contains(query) ||
          s.studentCode.toLowerCase().contains(query);
    }).toList();
  }

  /// Initialize provider
  Future<void> initialize() async {
    await loadAcademicYears();
    await loadClasses();
  }

  /// Load academic years
  Future<void> loadAcademicYears() async {
    try {
      _academicYears = await _repository.getAcademicYears();

      // Select current year by default
      final current = _academicYears.firstWhere(
        (y) => y['is_current'] == true,
        orElse: () => _academicYears.isNotEmpty ? _academicYears.first : {},
      );

      if (current.isNotEmpty) {
        _selectedAcademicYearId = current['id'];
        await loadSemesters();
      }

      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des années: $e';
      notifyListeners();
    }
  }

  /// Load semesters for selected academic year
  Future<void> loadSemesters() async {
    if (_selectedAcademicYearId == null) return;

    try {
      _semesters = await _repository.getSemesters(_selectedAcademicYearId!);

      // Select first semester by default
      if (_semesters.isNotEmpty) {
        _selectedSemesterId = _semesters.first['id'];
      }

      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des semestres: $e';
      notifyListeners();
    }
  }

  /// Load classes
  Future<void> loadClasses() async {
    try {
      _classes = await _repository.getClasses();
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des classes: $e';
      notifyListeners();
    }
  }

  /// Load groups for selected class
  Future<void> loadGroups() async {
    if (_selectedClassId == null) {
      _groups = [];
      notifyListeners();
      return;
    }

    try {
      _groups = await _repository.getGroups(_selectedClassId!);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des groupes: $e';
      notifyListeners();
    }
  }

  /// Load subject offerings
  Future<void> loadSubjectOfferings() async {
    if (_selectedClassId == null || _selectedSemesterId == null) {
      _subjectOfferings = [];
      notifyListeners();
      return;
    }

    try {
      _subjectOfferings = await _repository.getSubjectOfferings(
        classId: _selectedClassId!,
        semesterId: _selectedSemesterId!,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des matières: $e';
      notifyListeners();
    }
  }

  /// Load enrolled students
  Future<void> loadEnrolledStudents() async {
    if (_selectedAcademicYearId == null) return;

    try {
      _enrolledStudents = await _repository.getEnrolledStudents(
        academicYearId: _selectedAcademicYearId!,
        classId: _selectedClassId,
        groupId: _selectedGroupId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des élèves: $e';
      notifyListeners();
    }
  }

  /// Load grading configuration
  Future<void> loadGradingConfig() async {
    if (_selectedClassId == null) {
      _gradingConfig = TunisianCoefficientTables.getDefaultConfiguration(
        EducationLevel.lycee1,
      );
      notifyListeners();
      return;
    }

    try {
      _gradingConfig = await _repository.getConfigurationForClass(
        _selectedClassId!,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement de la configuration: $e';
      notifyListeners();
    }
  }

  /// Calculate results for current selection
  Future<void> calculateResults() async {
    if (_selectedClassId == null || _selectedAcademicYearId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Ensure config is loaded
      if (_gradingConfig == null) {
        await loadGradingConfig();
      }

      _classResult = await _repository.calculateClassResult(
        classId: _selectedClassId!,
        academicYearId: _selectedAcademicYearId!,
        groupId: _selectedGroupId,
        config: _gradingConfig!,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du calcul des résultats: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate result for a single student
  Future<void> calculateStudentResult(String enrollmentId) async {
    if (_gradingConfig == null) {
      await loadGradingConfig();
    }

    _isLoading = true;
    notifyListeners();

    try {
      _selectedStudentResult = await _repository.calculateStudentResult(
        enrollmentId: enrollmentId,
        config: _gradingConfig!,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du calcul: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save a grade
  Future<void> saveGrade({
    required String enrollmentId,
    required String studentId,
    required String subjectOfferingId,
    required String componentId,
    required double? value,
    String status = 'graded',
  }) async {
    try {
      await _repository.saveGrade(
        enrollmentId: enrollmentId,
        studentId: studentId,
        subjectOfferingId: subjectOfferingId,
        componentId: componentId,
        value: value,
        status: status,
      );

      // Recalculate results
      await calculateResults();
    } catch (e) {
      _error = 'Erreur lors de l\'enregistrement: $e';
      notifyListeners();
    }
  }

  /// Save multiple grades
  Future<void> saveBulkGrades(List<GradeEntry> grades) async {
    _isLoading = true;
    notifyListeners();

    try {
      final gradesData = grades.map((g) => g.toJson()).toList();
      await _repository.saveBulkGrades(gradesData);
      await calculateResults();
    } catch (e) {
      _error = 'Erreur lors de l\'enregistrement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save grading configuration
  Future<void> saveGradingConfig(GradingConfiguration config) async {
    try {
      await _repository.saveGradingConfiguration(config);
      _gradingConfig = config;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de l\'enregistrement: $e';
      notifyListeners();
    }
  }

  // Setters
  void setAcademicYear(String? yearId) {
    _selectedAcademicYearId = yearId;
    _classResult = null;
    loadSemesters();
  }

  void setSemester(String? semesterId) {
    _selectedSemesterId = semesterId;
    loadSubjectOfferings();
  }

  void setClass(String? classId) {
    _selectedClassId = classId;
    _selectedGroupId = null;
    _classResult = null;
    loadGroups();
    loadGradingConfig();
    loadSubjectOfferings();
  }

  void setGroup(String? groupId) {
    _selectedGroupId = groupId;
    _classResult = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(ResultsFilterType type) {
    _filterType = type;
    notifyListeners();
  }

  void setViewMode(ResultsViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void selectStudent(StudentResult student) {
    _selectedStudentResult = student;
    notifyListeners();
  }

  void clearSelectedStudent() {
    _selectedStudentResult = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
