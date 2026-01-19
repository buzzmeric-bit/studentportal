import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/supabase_config.dart';
import '../../widgets/admin_sidebar.dart';

/// Provider for loading students in a specific class
final classStudentsProvider = FutureProvider.family<ClassDetailData, String>((ref, classId) async {
  final supabase = SupabaseConfig.adminClient;
  
  debugPrint('ClassDetail: Loading class with ID: $classId');
  
  // Get class info
  final classResp = await supabase
      .from('classes')
      .select('id, name, room, capacity, niveau_id, section_id, niveaux(code, name), sections(name)')
      .eq('id', classId)
      .single();
  
  debugPrint('ClassDetail: Class found: ${classResp['name']} (ID: ${classResp['id']})');
  
  // DEBUG: Check all enrollments to see if they exist
  final allEnrollments = await supabase
      .from('enrollments')
      .select('id, user_id, class_id, is_active')
      .limit(50);
  debugPrint('ClassDetail: Total enrollments in DB: ${(allEnrollments as List).length}');
  for (final e in allEnrollments.take(10)) {
    debugPrint('  - enrollment: class_id=${e['class_id']}, user_id=${e['user_id']}, active=${e['is_active']}');
  }
  
  // Get students enrolled in this class - using simple query then join manually
  final enrollmentsResp = await supabase
      .from('enrollments')
      .select('id, student_code, user_id, is_active, class_id')
      .eq('class_id', classId);
  
  debugPrint('ClassDetail: Enrollments with class_id=$classId: ${(enrollmentsResp as List).length}');
  
  // Also try without is_active filter
  final activeEnrollments = enrollmentsResp.where((e) => e['is_active'] == true).toList();
  debugPrint('ClassDetail: Active enrollments: ${activeEnrollments.length}');
  
  final students = <StudentInClass>[];
  
  // Get user details for each enrollment
  for (final e in enrollmentsResp) {
    final userId = e['user_id'] as String?;
    if (userId == null) continue;
    
    try {
      final userResp = await supabase
          .from('users')
          .select('id, full_name, email, phone, photo_url, date_of_birth, gender, is_active, student_code')
          .eq('id', userId)
          .single();
      
      students.add(StudentInClass(
        id: userResp['id'] ?? '',
        fullName: userResp['full_name'] ?? 'N/A',
        email: userResp['email'] ?? '',
        phone: userResp['phone'],
        avatarUrl: userResp['photo_url'],
        studentCode: e['student_code'] ?? userResp['student_code'],
        dateOfBirth: userResp['date_of_birth'],
        gender: userResp['gender'],
        status: (userResp['is_active'] == true) ? 'active' : 'inactive',
        enrollmentId: e['id'],
      ));
    } catch (err) {
      debugPrint('ClassDetail: Error fetching user $userId: $err');
    }
  }
  
  // Sort by name
  students.sort((a, b) => a.fullName.compareTo(b.fullName));
  
  debugPrint('ClassDetail: Loaded ${students.length} students');
  
  final niveauInfo = classResp['niveaux'] as Map<String, dynamic>?;
  final sectionInfo = classResp['sections'] as Map<String, dynamic>?;
  
  return ClassDetailData(
    classId: classResp['id'],
    className: classResp['name'] ?? 'Classe',
    room: classResp['room'],
    capacity: classResp['capacity'],
    niveauCode: niveauInfo?['code'],
    niveauName: niveauInfo?['name'],
    sectionName: sectionInfo?['name'],
    students: students,
  );
});

class ClassDetailData {
  final String classId;
  final String className;
  final String? room;
  final int? capacity;
  final String? niveauCode;
  final String? niveauName;
  final String? sectionName;
  final List<StudentInClass> students;

  ClassDetailData({
    required this.classId,
    required this.className,
    this.room,
    this.capacity,
    this.niveauCode,
    this.niveauName,
    this.sectionName,
    required this.students,
  });
}

class StudentInClass {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? studentCode;
  final String? dateOfBirth;
  final String? gender;
  final String status;
  final String enrollmentId;

  StudentInClass({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.studentCode,
    this.dateOfBirth,
    this.gender,
    required this.status,
    required this.enrollmentId,
  });
}

class ClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;
  
  const ClassDetailScreen({super.key, required this.classId});
  
  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'code', 'status'
  bool _sortAsc = true;
  
  @override
  Widget build(BuildContext context) {
    debugPrint('ClassDetailScreen.build: classId = "${widget.classId}"');
    final dataAsync = ref.watch(classStudentsProvider(widget.classId));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/classes'),
          Expanded(
            child: dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(e),
              data: (data) => _buildContent(context, data),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Erreur: $error', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(classStudentsProvider(widget.classId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, ClassDetailData data) {
    // Filter and sort students
    var filteredStudents = data.students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          (s.studentCode?.toLowerCase().contains(q) ?? false) ||
          s.email.toLowerCase().contains(q);
    }).toList();
    
    // Sort
    filteredStudents.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'code':
          cmp = (a.studentCode ?? '').compareTo(b.studentCode ?? '');
          break;
        case 'status':
          cmp = a.status.compareTo(b.status);
          break;
        default:
          cmp = a.fullName.compareTo(b.fullName);
      }
      return _sortAsc ? cmp : -cmp;
    });
    
    return Column(
      children: [
        _buildTopBar(context, data),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards
                _buildStatsRow(data, filteredStudents.length),
                const SizedBox(height: 24),
                
                // Students list
                _buildStudentsList(context, filteredStudents, data),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTopBar(BuildContext context, ClassDetailData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/classes'),
            tooltip: 'Retour aux classes',
          ),
          const SizedBox(width: 16),
          
          // Class info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.class_, color: Colors.blue.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.className, 
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          if (data.niveauName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                data.niveauName!,
                                style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (data.sectionName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                data.sectionName!,
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          const Spacer(),
          
          // Search
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un étudiant...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(classStudentsProvider(widget.classId)),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsRow(ClassDetailData data, int filteredCount) {
    final capacity = data.capacity ?? 0;
    final studentCount = data.students.length;
    final fillRate = capacity > 0 ? (studentCount / capacity * 100).toStringAsFixed(0) : '-';
    
    return Row(
      children: [
        _buildStatCard(
          Icons.people,
          'Étudiants',
          '$studentCount',
          Colors.blue,
          subtitle: capacity > 0 ? 'sur $capacity places' : null,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          Icons.percent,
          'Taux de remplissage',
          '$fillRate%',
          capacity > 0 && studentCount >= capacity ? Colors.red : Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          Icons.meeting_room,
          'Salle',
          data.room ?? '-',
          Colors.orange,
        ),
        const SizedBox(width: 16),
        if (_searchQuery.isNotEmpty)
          _buildStatCard(
            Icons.filter_list,
            'Résultats filtrés',
            '$filteredCount',
            Colors.purple,
          ),
      ],
    );
  }
  
  Widget _buildStatCard(IconData icon, String label, String value, Color color, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStudentsList(BuildContext context, List<StudentInClass> students, ClassDetailData data) {
    if (students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty 
                    ? 'Aucun étudiant trouvé pour "$_searchQuery"'
                    : 'Aucun étudiant inscrit dans cette classe',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ajoutez des étudiants via l\'import ou individuellement',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Liste des étudiants (${students.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                // Sort options
                _buildSortButton('Nom', 'name'),
                _buildSortButton('Code', 'code'),
                _buildSortButton('Statut', 'status'),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const SizedBox(width: 50), // Avatar
                const Expanded(flex: 3, child: Text('Nom', style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(flex: 2, child: Text('Code', style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(flex: 3, child: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(flex: 2, child: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(width: 80, child: Text('Statut', style: TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(width: 50), // Actions
              ],
            ),
          ),
          
          // Students rows
          ...students.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            return _buildStudentRow(context, student, index);
          }),
        ],
      ),
    );
  }
  
  Widget _buildSortButton(String label, String field) {
    final isActive = _sortBy == field;
    return TextButton.icon(
      onPressed: () {
        setState(() {
          if (_sortBy == field) {
            _sortAsc = !_sortAsc;
          } else {
            _sortBy = field;
            _sortAsc = true;
          }
        });
      },
      icon: isActive 
          ? Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14)
          : const SizedBox.shrink(),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? Colors.blue : Colors.grey.shade600,
      ),
    );
  }
  
  Widget _buildStudentRow(BuildContext context, StudentInClass student, int index) {
    final isEven = index % 2 == 0;
    
    return InkWell(
      onTap: () => context.push('/users/${student.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isEven ? Colors.white : Colors.grey.shade50,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: student.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        student.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            _getInitials(student.fullName),
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(student.fullName),
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
            
            // Name
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (student.gender != null) ...[
                    Icon(
                      student.gender == 'male' ? Icons.male : Icons.female,
                      size: 16,
                      color: student.gender == 'male' ? Colors.blue : Colors.pink,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      student.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Code
            Expanded(
              flex: 2,
              child: Text(
                student.studentCode ?? '-',
                style: TextStyle(color: Colors.grey.shade700, fontFamily: 'monospace'),
              ),
            ),
            
            // Email
            Expanded(
              flex: 3,
              child: Text(
                student.email,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            
            // Phone
            Expanded(
              flex: 2,
              child: Text(
                student.phone ?? '-',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            
            // Status
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: student.status == 'active' ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  student.status == 'active' ? 'Actif' : 'Inactif',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: student.status == 'active' ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ),
            
            // Actions
            SizedBox(
              width: 50,
              child: IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: () => context.push('/users/${student.id}'),
                tooltip: 'Voir le profil',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
