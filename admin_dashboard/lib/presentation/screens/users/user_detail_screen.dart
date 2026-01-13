import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_sidebar.dart';

// User detail provider
final userDetailProvider = FutureProvider.family<UserDetailData?, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  
  try {
    // Get user basic info
    final userResponse = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (userResponse == null) return null;
    
    // Get enrollment info (for students)
    Map<String, dynamic>? enrollment;
    if (userResponse['role'] == 'student') {
      enrollment = await supabase
          .from('enrollments')
          .select('*, classes(name, level, academic_year)')
          .eq('student_id', userId)
          .eq('is_active', true)
          .maybeSingle();
    }
    
    // Get suggestions count
    final suggestionsCount = await supabase
        .from('suggestions')
        .select('id')
        .eq('student_id', userId)
        .count();
    
    // Get recent suggestions
    final recentSuggestions = await supabase
        .from('suggestions')
        .select('id, subject, status, suggestion_type, created_at')
        .eq('student_id', userId)
        .order('created_at', ascending: false)
        .limit(5);
    
    // Get grades summary (for students)
    List<Map<String, dynamic>>? grades;
    if (userResponse['role'] == 'student') {
      try {
        grades = await supabase
            .from('grades')
            .select('value, subjects(name)')
            .eq('student_id', userId)
            .order('created_at', ascending: false)
            .limit(10);
      } catch (_) {}
    }
    
    // Get absences count (for students)
    int absencesCount = 0;
    if (userResponse['role'] == 'student') {
      try {
        final absences = await supabase
            .from('absences')
            .select('id')
            .eq('student_id', userId)
            .count();
        absencesCount = absences.count;
      } catch (_) {}
    }
    
    // Get payments info (for students)
    List<Map<String, dynamic>>? payments;
    double totalPaid = 0;
    double totalDue = 0;
    if (userResponse['role'] == 'student') {
      try {
        payments = await supabase
            .from('payments')
            .select('amount, status, payment_date, description')
            .eq('student_id', userId)
            .order('payment_date', ascending: false)
            .limit(5);
        
        for (final p in payments) {
          if (p['status'] == 'paid') {
            totalPaid += (p['amount'] as num?)?.toDouble() ?? 0;
          } else {
            totalDue += (p['amount'] as num?)?.toDouble() ?? 0;
          }
        }
      } catch (_) {}
    }
    
    return UserDetailData(
      user: userResponse,
      enrollment: enrollment,
      suggestionsCount: suggestionsCount.count,
      recentSuggestions: (recentSuggestions as List).cast<Map<String, dynamic>>(),
      grades: grades?.cast<Map<String, dynamic>>(),
      absencesCount: absencesCount,
      payments: payments,
      totalPaid: totalPaid,
      totalDue: totalDue,
    );
  } catch (e) {
    debugPrint('Error loading user detail: $e');
    return null;
  }
});

class UserDetailData {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? enrollment;
  final int suggestionsCount;
  final List<Map<String, dynamic>> recentSuggestions;
  final List<Map<String, dynamic>>? grades;
  final int absencesCount;
  final List<Map<String, dynamic>>? payments;
  final double totalPaid;
  final double totalDue;
  
  UserDetailData({
    required this.user,
    this.enrollment,
    this.suggestionsCount = 0,
    this.recentSuggestions = const [],
    this.grades,
    this.absencesCount = 0,
    this.payments,
    this.totalPaid = 0,
    this.totalDue = 0,
  });
}

class UserDetailScreen extends ConsumerWidget {
  final String userId;
  final String? userName;
  
  const UserDetailScreen({super.key, required this.userId, this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDetailAsync = ref.watch(userDetailProvider(userId));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/users'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: userDetailAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Erreur: $e'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(userDetailProvider(userId)),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                    data: (data) {
                      if (data == null) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_off, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Utilisateur non trouvé', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        );
                      }
                      return _buildContent(context, data);
                    },
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
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Retour',
          ),
          const SizedBox(width: 12),
          Text(
            'Détails Utilisateur${userName != null ? ' - $userName' : ''}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Open edit user dialog
            },
            tooltip: 'Modifier',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserDetailData data) {
    final user = data.user;
    final isStudent = user['role'] == 'student';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile card
          _buildProfileCard(context, data),
          const SizedBox(height: 24),
          // Statistics cards for students
          if (isStudent) ...[
            _buildStatisticsRow(context, data),
            const SizedBox(height: 24),
          ],
          // Tabs/Sections
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (isStudent && data.enrollment != null)
                      _buildEnrollmentCard(context, data.enrollment!),
                    if (isStudent && data.enrollment != null)
                      const SizedBox(height: 16),
                    _buildSuggestionsCard(context, data),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right column
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    if (isStudent) ...[
                      _buildGradesCard(context, data),
                      const SizedBox(height: 16),
                      _buildPaymentsCard(context, data),
                    ],
                    if (!isStudent)
                      _buildActivityCard(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserDetailData data) {
    final user = data.user;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: user['photo_url'] != null ? NetworkImage(user['photo_url']) : null,
            child: user['photo_url'] == null
                ? Text(
                    (user['full_name'] ?? 'A').substring(0, 1).toUpperCase(),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  )
                : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['full_name'] ?? 'N/A',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    _RoleBadge(role: user['role'] ?? 'student'),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _InfoChip(icon: Icons.email, label: user['email'] ?? 'N/A'),
                    if (user['phone'] != null)
                      _InfoChip(icon: Icons.phone, label: user['phone']),
                    if (user['student_code'] != null)
                      _InfoChip(icon: Icons.badge, label: 'Code: ${user['student_code']}'),
                    if (user['date_of_birth'] != null)
                      _InfoChip(
                        icon: Icons.cake,
                        label: DateFormat('dd/MM/yyyy').format(DateTime.parse(user['date_of_birth'])),
                      ),
                  ],
                ),
                if (user['address'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(user['address'], style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Créé le ${DateFormat('dd/MM/yyyy').format(DateTime.parse(user['created_at']))}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${user['id'].toString().substring(0, 8)}...',
                style: TextStyle(color: Colors.grey[400], fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(BuildContext context, UserDetailData data) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.message,
          label: 'Suggestions',
          value: '${data.suggestionsCount}',
          color: Colors.blue,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.event_busy,
          label: 'Absences',
          value: '${data.absencesCount}',
          color: Colors.red,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.check_circle,
          label: 'Payé',
          value: '${data.totalPaid.toStringAsFixed(0)} DZD',
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.pending,
          label: 'En attente',
          value: '${data.totalDue.toStringAsFixed(0)} DZD',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildEnrollmentCard(BuildContext context, Map<String, dynamic> enrollment) {
    final classInfo = enrollment['classes'] as Map<String, dynamic>?;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Inscription Active', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DetailItem(label: 'Classe', value: '${classInfo?['level'] ?? ''} ${classInfo?['name'] ?? ''}'.trim()),
              ),
              Expanded(
                child: _DetailItem(label: 'Année académique', value: classInfo?['academic_year'] ?? 'N/A'),
              ),
              Expanded(
                child: _DetailItem(label: 'Code étudiant', value: enrollment['student_code'] ?? 'N/A'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(BuildContext context, UserDetailData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Suggestions Récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${data.suggestionsCount} total', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const Divider(),
          if (data.recentSuggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('Aucune suggestion', style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else
            ...data.recentSuggestions.map((s) => _SuggestionListItem(suggestion: s)),
        ],
      ),
    );
  }

  Widget _buildGradesCard(BuildContext context, UserDetailData data) {
    final grades = data.grades ?? [];
    double average = 0;
    if (grades.isNotEmpty) {
      final values = grades.map((g) => (g['value'] as num?)?.toDouble() ?? 0).toList();
      average = values.reduce((a, b) => a + b) / values.length;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grade, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          if (grades.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('Aucune note', style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Moyenne: ', style: TextStyle(color: Colors.blue.shade700)),
                  Text(
                    average.toStringAsFixed(2),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                  Text('/20', style: TextStyle(color: Colors.blue.shade700)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...grades.take(5).map((g) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(g['subjects']?['name'] ?? 'N/A', overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getGradeColor(g['value'] as num?),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${g['value']?.toStringAsFixed(1) ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Color _getGradeColor(num? grade) {
    if (grade == null) return Colors.grey;
    if (grade >= 16) return Colors.green;
    if (grade >= 14) return Colors.lightGreen;
    if (grade >= 12) return Colors.amber;
    if (grade >= 10) return Colors.orange;
    return Colors.red;
  }

  Widget _buildPaymentsCard(BuildContext context, UserDetailData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Paiements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Payé', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                      Text(
                        '${data.totalPaid.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('En attente', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                      Text(
                        '${data.totalDue.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (data.payments != null && data.payments!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...data.payments!.take(3).map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    p['status'] == 'paid' ? Icons.check_circle : Icons.schedule,
                    size: 16,
                    color: p['status'] == 'paid' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p['description'] ?? 'Paiement', overflow: TextOverflow.ellipsis)),
                  Text('${p['amount']} DZD', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.purple.shade600),
              const SizedBox(width: 8),
              const Text('Activité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text('Historique d\'activité', style: TextStyle(color: Colors.grey[500])),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (role) {
      case 'admin':
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade800;
        label = 'Admin';
        break;
      case 'staff':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        label = 'Staff';
        break;
      case 'teacher':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        label = 'Enseignant';
        break;
      default:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        label = 'Étudiant';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SuggestionListItem extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  
  const _SuggestionListItem({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final status = suggestion['status'] as String? ?? 'pending';
    final type = suggestion['suggestion_type'] as String? ?? 'general';
    final createdAt = suggestion['created_at'] != null 
        ? DateTime.tryParse(suggestion['created_at'])
        : null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _TypeIcon(type: type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion['subject'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
                if (createdAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
              ],
            ),
          ),
          _StatusBadge(status: status),
        ],
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final String type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'reclamation_note':
        icon = Icons.grade;
        color = Colors.red;
        break;
      case 'absence':
        icon = Icons.event_busy;
        color = Colors.purple;
        break;
      case 'paiement':
        icon = Icons.payment;
        color = Colors.indigo;
        break;
      case 'emploi_temps':
        icon = Icons.schedule;
        color = Colors.teal;
        break;
      case 'vie_scolaire':
        icon = Icons.people;
        color = Colors.pink;
        break;
      default:
        icon = Icons.message;
        color = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    
    switch (status) {
      case 'replied':
        bg = Colors.green;
        label = 'Répondu';
        break;
      case 'in_review':
        bg = Colors.blue;
        label = 'En cours';
        break;
      case 'closed':
        bg = Colors.grey;
        label = 'Fermé';
        break;
      default:
        bg = Colors.orange;
        label = 'En attente';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: bg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
