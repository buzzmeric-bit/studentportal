import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/admin_sidebar.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/models/user_model.dart';
import '../../providers/users_provider.dart';
import '../../providers/curriculum_provider.dart';
import 'user_form_dialog.dart';

// ==================== USER PROFILE DATA MODEL ====================
class UserProfileData {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? enrollment;
  final String? className;
  final String? groupName;
  final int yearsAtSchool;
  final List<Map<String, dynamic>> suggestions;
  final List<Map<String, dynamic>> monthlyAbsences;
  final int totalAbsences;
  final int justifiedAbsences;
  final List<Map<String, dynamic>> payments;
  final double paymentAccuracy;
  final int onTimePayments;
  final int latePayments;
  final double totalPaid;
  final double totalDue;
  final List<Map<String, dynamic>> grades;
  final List<Map<String, dynamic>> timetable;
  final List<Map<String, dynamic>> messages;

  UserProfileData({
    required this.user,
    this.enrollment,
    this.className,
    this.groupName,
    this.yearsAtSchool = 0,
    this.suggestions = const [],
    this.monthlyAbsences = const [],
    this.totalAbsences = 0,
    this.justifiedAbsences = 0,
    this.payments = const [],
    this.paymentAccuracy = 0,
    this.onTimePayments = 0,
    this.latePayments = 0,
    this.totalPaid = 0,
    this.totalDue = 0,
    this.grades = const [],
    this.timetable = const [],
    this.messages = const [],
  });
}

// ==================== PROFILE PROVIDER ====================
final userProfileDataProvider = FutureProvider.family<UserProfileData?, String>(
  (ref, userId) async {
    final supabase = Supabase.instance.client;

    try {
      // Get user basic info
      final userResponse = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) return null;

      // Get enrollment info with class and niveau
      Map<String, dynamic>? enrollment;
      String? className;
      String? groupName;
      String? niveauCodeFromEnrollment;

      try {
        enrollment = await supabase
            .from('enrollments')
            .select('*, classes(id, name, niveau_id, niveaux(code, name)), groups(name)')
            .eq('user_id', userId)
            .maybeSingle();

        debugPrint('Profile: Enrollment for $userId: $enrollment');
        if (enrollment != null) {
          final classInfo = enrollment['classes'] as Map<String, dynamic>?;
          className = classInfo?['name'];
          final niveauInfo = classInfo?['niveaux'] as Map<String, dynamic>?;
          niveauCodeFromEnrollment = niveauInfo?['code'];
          groupName = enrollment['groups']?['name'];
          debugPrint('Profile: className=$className, niveau=$niveauCodeFromEnrollment, groupName=$groupName');
        }
      } catch (e) {
        debugPrint('Profile: Error loading enrollment: $e');
      }

      // Update user data with niveau from enrollment if not set
      final userData = Map<String, dynamic>.from(userResponse);
      if (userData['niveau_code'] == null && niveauCodeFromEnrollment != null) {
        userData['niveau_code'] = niveauCodeFromEnrollment;
      }

      // Calculate years at school
      int yearsAtSchool = 0;
      if (userResponse['created_at'] != null) {
        final createdAt = DateTime.tryParse(userResponse['created_at']);
        if (createdAt != null) {
          yearsAtSchool = DateTime.now().difference(createdAt).inDays ~/ 365;
          if (yearsAtSchool == 0) yearsAtSchool = 1;
        }
      }

      // Get suggestions
      List<Map<String, dynamic>> suggestions = [];
      try {
        final resp = await supabase
            .from('suggestions')
            .select('id, subject, status, suggestion_type, created_at')
            .eq('student_id', userId)
            .order('created_at', ascending: false)
            .limit(10);
        suggestions = (resp as List).cast<Map<String, dynamic>>();
      } catch (_) {}

      // Get absences for current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      List<Map<String, dynamic>> monthlyAbsences = [];
      int totalAbsences = 0;
      int justifiedAbsences = 0;

      try {
        final resp = await supabase
            .from('absence_records')
            .select('date, hours_absent, justified, enrollment_id')
            .gte('date', startOfMonth.toIso8601String().split('T')[0])
            .order('date');
        monthlyAbsences = (resp as List).cast<Map<String, dynamic>>();
        totalAbsences = monthlyAbsences.length;
        justifiedAbsences = monthlyAbsences
            .where((a) => a['justified'] == true)
            .length;
      } catch (_) {}

      // Get payments and calculate accuracy
      List<Map<String, dynamic>> payments = [];
      double paymentAccuracy = 0;
      int onTimePayments = 0;
      int latePayments = 0;
      double totalPaid = 0;
      double totalDue = 0;

      try {
        final resp = await supabase
            .from('payments')
            .select(
              'amount, status, due_date, paid_at, description, created_at',
            )
            .order('created_at', ascending: false);
        payments = (resp as List).cast<Map<String, dynamic>>();

        for (final p in payments) {
          final amount = (p['amount'] as num?)?.toDouble() ?? 0;

          if (p['status'] == 'paid') {
            totalPaid += amount;
            if (p['due_date'] != null && p['paid_at'] != null) {
              final dueDate = DateTime.parse(p['due_date']);
              final paidAt = DateTime.parse(p['paid_at']);
              if (paidAt.isBefore(dueDate) ||
                  paidAt.isAtSameMomentAs(dueDate)) {
                onTimePayments++;
              } else {
                latePayments++;
              }
            } else {
              onTimePayments++;
            }
          } else {
            totalDue += amount;
            if (p['status'] == 'overdue') latePayments++;
          }
        }

        final total = onTimePayments + latePayments;
        if (total > 0) paymentAccuracy = (onTimePayments / total) * 100;
      } catch (_) {}

      // Get grades
      List<Map<String, dynamic>> grades = [];
      try {
        final resp = await supabase
            .from('grades')
            .select('grade_value, status, subjects(name)')
            .order('created_at', ascending: false)
            .limit(10);
        grades = (resp as List).cast<Map<String, dynamic>>();
      } catch (_) {}

      // Get timetable
      List<Map<String, dynamic>> timetable = [];
      try {
        final resp = await supabase
            .from('timetable_slots')
            .select('*, subjects(name)')
            .order('day_of_week')
            .order('start_time');
        timetable = (resp as List).cast<Map<String, dynamic>>();
      } catch (_) {}

      // Get class messages
      List<Map<String, dynamic>> messages = [];
      try {
        if (enrollment != null && enrollment['class_id'] != null) {
          final resp = await supabase
              .from('announcements')
              .select('id, title, body, published_at')
              .order('published_at', ascending: false)
              .limit(5);
          messages = (resp as List).cast<Map<String, dynamic>>();
        }
      } catch (_) {}

      return UserProfileData(
        user: userData,
        enrollment: enrollment,
        className: className,
        groupName: groupName,
        yearsAtSchool: yearsAtSchool,
        suggestions: suggestions,
        monthlyAbsences: monthlyAbsences,
        totalAbsences: totalAbsences,
        justifiedAbsences: justifiedAbsences,
        payments: payments,
        paymentAccuracy: paymentAccuracy,
        onTimePayments: onTimePayments,
        latePayments: latePayments,
        totalPaid: totalPaid,
        totalDue: totalDue,
        grades: grades,
        timetable: timetable,
        messages: messages,
      );
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return null;
    }
  },
);

// ==================== MAIN PROFILE SCREEN ====================
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;

  const UserProfileScreen({super.key, required this.userId, this.userName});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isUploadingPhoto = false;
  bool _showPassword = false;
  bool _isResettingPassword = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileDataProvider(widget.userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/users'),
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (data) {
                if (data == null) {
                  return _buildNotFound();
                }
                return _buildProfile(context, data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Utilisateur non trouvé',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, UserProfileData data) {
    final user = data.user;
    final isStudent = user['role'] == 'student';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Profil Utilisateur',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildActionButtons(user),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Header Card
          _buildProfileHeader(data),
          const SizedBox(height: 24),

          // Main content grid
          if (isStudent) ...[
            // Stats Row
            _buildStatsRow(data),
            const SizedBox(height: 24),

            // Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildAbsenceGraph(data),
                      const SizedBox(height: 24),
                      _buildRecentGrades(data),
                      const SizedBox(height: 24),
                      _buildTimetableCard(data),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right column
                Expanded(
                  child: Column(
                    children: [
                      _buildPaymentCard(data),
                      const SizedBox(height: 24),
                      _buildSuggestionsCard(data),
                      const SizedBox(height: 24),
                      _buildMessagesCard(data),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Non-student profile (admin/staff)
            _buildStaffProfile(data),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> user) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showEditDialog(user),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Modifier'),
        ),
        OutlinedButton.icon(
          onPressed: _isResettingPassword ? null : () => _resetPassword(user),
          icon: _isResettingPassword
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_reset, size: 18),
          label: const Text('Reset mot de passe'),
        ),
        if (user['role'] == 'student')
          ElevatedButton.icon(
            onPressed: () => _loginAsStudent(user),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Se connecter en tant que'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    // Convert map to UserModel for editing
    final userModel = UserModel(
      id: user['id'] ?? widget.userId,
      schoolId: user['school_id'],
      role: user['role'] ?? 'student',
      fullName: user['full_name'] ?? '',
      email: user['email'] ?? '',
      phone: user['phone'],
      photoUrl: user['photo_url'],
      studentCode: user['student_code'],
      dateOfBirth: user['date_of_birth'] != null
          ? DateTime.tryParse(user['date_of_birth'].toString())
          : null,
      address: user['address'],
      gender: user['gender'],
      nationality: user['nationality'],
      niveau: user['niveau'],
      niveauCode: user['niveau_code'],
      sectionCode: user['section_code'],
      initialPassword: user['initial_password'],
      createdAt: user['created_at'] != null
          ? DateTime.parse(user['created_at'])
          : DateTime.now(),
      updatedAt: user['updated_at'] != null
          ? DateTime.parse(user['updated_at'])
          : DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (ctx) => UserFormDialog(user: userModel),
    ).then((_) {
      // Refresh profile after dialog closes
      ref.invalidate(userProfileDataProvider(widget.userId));
    });
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Text(
          'Voulez-vous générer un nouveau mot de passe pour ${user['full_name']} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isResettingPassword = true);

    try {
      final newPassword = await ref
          .read(usersProvider.notifier)
          .resetUserPassword(widget.userId);

      if (newPassword != null && mounted) {
        ref.invalidate(userProfileDataProvider(widget.userId));
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 12),
                const Text('Mot de passe réinitialisé'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouveau mot de passe :'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          newPassword,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: newPassword));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mot de passe copié !'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }

  Future<void> _setPasswordManually(Map<String, dynamic> user) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Définir le mot de passe'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrez le mot de passe actuel de ${user['full_name']} pour le sauvegarder.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    final generated = _generateRandomPassword();
                    passwordController.text = generated;
                  },
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Générer automatiquement'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, passwordController.text);
                }
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      // Save the password to initial_password field
      await Supabase.instance.client
          .from('users')
          .update({
            'initial_password': result,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.userId);

      // Refresh the profile
      ref.invalidate(userProfileDataProvider(widget.userId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe sauvegardé avec succès'),
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

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(10, (i) => chars[(random + i * 7) % chars.length]).join();
  }

  Future<void> _loginAsStudent(Map<String, dynamic> user) async {
    final email = user['email'] as String?;
    final initialPassword = user['initial_password'] as String?;
    final fullName = user['full_name'] as String? ?? 'cet étudiant';

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cet utilisateur n\'a pas d\'email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If we have the password saved, show credentials directly
    if (initialPassword != null) {
      _showLoginCredentialsDialog(email, initialPassword, fullName);
      return;
    }

    // Otherwise, ask if they want to reset the password
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mot de passe non enregistré'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le mot de passe de $fullName n\'est pas enregistré.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Voulez-vous réinitialiser son mot de passe pour pouvoir vous connecter ?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text('Réinitialiser et connecter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Reset password
    setState(() => _isResettingPassword = true);
    try {
      final newPassword = await ref
          .read(usersProvider.notifier)
          .resetUserPassword(widget.userId);

      if (newPassword != null && mounted) {
        ref.invalidate(userProfileDataProvider(widget.userId));
        _showLoginCredentialsDialog(email, newPassword, fullName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }

  void _showLoginCredentialsDialog(String email, String password, String fullName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.login, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Text('Connexion en tant qu\'étudiant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Utilisez ces identifiants pour vous connecter à l\'application étudiant en tant que $fullName :',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildCredentialRow('Email', email),
            const SizedBox(height: 8),
            _buildCredentialRow('Mot de passe', password),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ouvrez l\'application mobile PythaOne et connectez-vous avec ces identifiants.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Email: $email\nMot de passe: $password',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Identifiants copiés !'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copier tout'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copié !'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copié !'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfileData data) {
    final user = data.user;
    final photoUrl = user['photo_url'] as String?;
    final role = user['role'] as String? ?? 'student';
    final initialPassword = user['initial_password'] as String?;
    final niveauCode = user['niveau_code'] as String?;
    final sectionCode = user['section_code'] as String?;
    final legacyNiveau = user['niveau'] as String?;
    final gender = user['gender'] as String?;
    final nationality = user['nationality'] as String?;
    final dateOfBirth = user['date_of_birth'] as String?;

    // Calculate age
    int? age;
    if (dateOfBirth != null) {
      final dob = DateTime.tryParse(dateOfBirth);
      if (dob != null) {
        final now = DateTime.now();
        age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
      }
    }

    // Format niveau display text
    String? niveauDisplay;
    if (niveauCode != null) {
      niveauDisplay = getNiveauFullName(niveauCode);
      if (sectionCode != null) {
        niveauDisplay = '$niveauDisplay - ${getSectionFullName(sectionCode)}';
      }
    } else if (legacyNiveau != null) {
      niveauDisplay = legacyNiveau;
    }

    // Derive niveau from class name if not set
    if (niveauDisplay == null && data.className != null) {
      final cn = data.className!;
      if (cn.contains('1ère'))
        niveauDisplay = '1ère Année';
      else if (cn.contains('2ème'))
        niveauDisplay = '2ème Année';
      else if (cn.contains('3ème'))
        niveauDisplay = '3ème Année';
      else if (cn.contains('4ème'))
        niveauDisplay = '4ème Année';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile photo with upload capability
              Stack(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getRoleColor(role).withOpacity(0.1),
                        border: Border.all(
                          color: _getRoleColor(role),
                          width: 3,
                        ),
                        image: photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoUrl == null
                          ? Center(
                              child: Text(
                                _getInitials(user['full_name'] ?? ''),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: _getRoleColor(role),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getRoleColor(role),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _isUploadingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['full_name'] ?? 'Nom inconnu',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copier le nom',
                          onPressed: () =>
                              _copyToClipboard(user['full_name'] ?? '', 'Nom'),
                        ),
                        const SizedBox(width: 12),
                        _buildRoleBadge(role),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Niveau and Class badges for students
                    if (role == 'student') ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (niveauDisplay != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 14,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    niveauDisplay,
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (data.className != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.class_,
                                    size: 14,
                                    color: Colors.purple.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    data.className!,
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (data.groupName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.group,
                                    size: 14,
                                    color: Colors.teal.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Groupe ${data.groupName}',
                                    style: TextStyle(
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Gender, Age, Nationality badges
                    if (gender != null ||
                        age != null ||
                        nationality != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (gender != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: gender == 'M'
                                    ? Colors.blue.shade50
                                    : Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: gender == 'M'
                                      ? Colors.blue.shade200
                                      : Colors.pink.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    gender == 'M' ? Icons.male : Icons.female,
                                    size: 16,
                                    color: gender == 'M'
                                        ? Colors.blue.shade700
                                        : Colors.pink.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    gender == 'M' ? 'Masculin' : 'Féminin',
                                    style: TextStyle(
                                      color: gender == 'M'
                                          ? Colors.blue.shade700
                                          : Colors.pink.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (age != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cake,
                                    size: 16,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$age ans',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (nationality != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: 16,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    nationality,
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Copyable contact info
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildCopyableInfo(
                          Icons.email_outlined,
                          user['email'] ?? '',
                          'Email',
                        ),
                        if (user['phone'] != null)
                          _buildCopyableInfo(
                            Icons.phone_outlined,
                            user['phone'],
                            'Téléphone',
                          ),
                        if (user['address'] != null)
                          _buildCopyableInfo(
                            Icons.location_on_outlined,
                            user['address'],
                            'Adresse',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (user['student_code'] != null)
                          _infoChip(
                            Icons.badge_outlined,
                            'ID: ${user['student_code']}',
                          ),
                        if (user['date_of_birth'] != null)
                          _infoChip(
                            Icons.cake_outlined,
                            'Né le ${_formatDate(user['date_of_birth'])}',
                          ),
                        _infoChip(
                          Icons.school_outlined,
                          '${data.yearsAtSchool} an(s) à l\'école',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right side - Created date and ID
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Créé le',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  Text(
                    _formatDate(user['created_at']),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.userId.substring(0, 8)}...',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        tooltip: 'Copier l\'ID',
                        onPressed: () => _copyToClipboard(widget.userId, 'ID'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Password section - always show for managers
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: initialPassword != null
                  ? Colors.amber.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: initialPassword != null
                    ? Colors.amber.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.key,
                  color: initialPassword != null
                      ? Colors.amber.shade700
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mot de passe initial',
                      style: TextStyle(
                        fontSize: 12,
                        color: initialPassword != null
                            ? Colors.amber.shade800
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          initialPassword != null
                              ? (_showPassword
                                    ? initialPassword
                                    : '••••••••••••')
                              : 'Non enregistré',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: initialPassword != null
                                ? Colors.amber.shade900
                                : Colors.grey.shade500,
                            fontStyle: initialPassword == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                if (initialPassword != null) ...[
                  IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    tooltip: _showPassword ? 'Masquer' : 'Afficher',
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copier le mot de passe',
                    onPressed: () =>
                        _copyToClipboard(initialPassword, 'Mot de passe'),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      'Créé avant l\'enregistrement',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _setPasswordManually(data.user),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Définir'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableInfo(IconData icon, String text, String label) {
    return InkWell(
      onTap: () => _copyToClipboard(text, label),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(width: 4),
            Icon(Icons.copy, size: 12, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserProfileData data) {
    return Row(
      children: [
        _buildStatCard(
          'Absences ce mois',
          '${data.totalAbsences}',
          Icons.event_busy,
          Colors.red,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Justifiées',
          '${data.justifiedAbsences}',
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Suggestions',
          '${data.suggestions.length}',
          Icons.lightbulb,
          Colors.amber,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Notes récentes',
          '${data.grades.length}',
          Icons.grade,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceGraph(UserProfileData data) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Create daily absence data
    final dailyAbsences = List.generate(daysInMonth, (i) => 0.0);
    for (final absence in data.monthlyAbsences) {
      final date = DateTime.tryParse(absence['date'] ?? '');
      if (date != null && date.day <= daysInMonth) {
        dailyAbsences[date.day - 1] +=
            (absence['hours_absent'] as num?)?.toDouble() ?? 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Présence ce mois',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateFormat('MMMM yyyy', 'fr_FR').format(now),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 8,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 == 0) {
                          return Text(
                            '${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(daysInMonth, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dailyAbsences[i],
                        color: dailyAbsences[i] > 0
                            ? Colors.red.shade400
                            : Colors.green.shade200,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(Colors.green.shade200, 'Présent'),
              const SizedBox(width: 24),
              _legendItem(Colors.red.shade400, 'Absent'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(UserProfileData data) {
    final accuracy = data.paymentAccuracy;
    final color = accuracy >= 80
        ? Colors.green
        : (accuracy >= 50 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Paiements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${accuracy.toStringAsFixed(0)}% à temps',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Payment accuracy circle
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: accuracy / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${accuracy.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        'Précision',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _paymentStat('À temps', '${data.onTimePayments}', Colors.green),
              _paymentStat('En retard', '${data.latePayments}', Colors.red),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total payé', style: TextStyle(color: Colors.grey.shade600)),
              Text(
                '${data.totalPaid.toStringAsFixed(0)} DA',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reste dû', style: TextStyle(color: Colors.grey.shade600)),
              Text(
                '${data.totalDue.toStringAsFixed(0)} DA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: data.totalDue > 0 ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to payments
              },
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('Voir historique'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSuggestionsCard(UserProfileData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'Suggestions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${data.suggestions.length}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.suggestions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Aucune suggestion',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...data.suggestions
                .take(5)
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getSuggestionStatusColor(s['status']),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s['subject'] ?? 'Sans sujet',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMessagesCard(UserProfileData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.message_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Messages de classe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.messages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Aucun message',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...data.messages
                .take(3)
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatDate(m['published_at']),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRecentGrades(UserProfileData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grade, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Notes récentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to grades
                },
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.grades.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Aucune note',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: data.grades.take(8).map((g) {
                final value = (g['grade_value'] as num?)?.toDouble() ?? 0;
                final subject = g['subjects']?['name'] ?? 'Matière';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _getGradeColor(value).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getGradeColor(value).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getGradeColor(value),
                        ),
                      ),
                      Text(
                        subject,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTimetableCard(UserProfileData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                'Emploi du temps',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to timetable
                },
                child: const Text('Voir complet'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.timetable.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Aucun emploi du temps',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            Text(
              '${data.timetable.length} cours programmés',
              style: TextStyle(color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _buildStaffProfile(UserProfileData data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du compte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _infoRow('Rôle', _getRoleLabel(data.user['role'])),
          _infoRow('Email', data.user['email'] ?? '-'),
          _infoRow('Téléphone', data.user['phone'] ?? '-'),
          _infoRow('Créé le', _formatDate(data.user['created_at'])),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getRoleLabel(role),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final fileName =
          'profile_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';

      // Upload to Supabase Storage
      await SupabaseConfig.client.storage
          .from('profile-photos')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final url = SupabaseConfig.client.storage
          .from('profile-photos')
          .getPublicUrl(fileName);

      // Update user record
      await SupabaseConfig.client
          .from('users')
          .update({'photo_url': url})
          .eq('id', widget.userId);

      // Refresh
      ref.invalidate(userProfileDataProvider(widget.userId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo mise à jour !'),
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
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'staff':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Manager';
      default:
        return 'Étudiant';
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _getSuggestionStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in_review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getGradeColor(double value) {
    if (value >= 16) return Colors.green;
    if (value >= 12) return Colors.blue;
    if (value >= 10) return Colors.orange;
    return Colors.red;
  }
}
