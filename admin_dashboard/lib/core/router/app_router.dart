import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/users/users_screen.dart';
import '../../presentation/screens/users/user_profile_screen.dart';
import '../../presentation/screens/users/bulk_photo_upload_screen.dart';
import '../../presentation/screens/users/simple_bulk_import_screen.dart';
import '../../presentation/screens/classes/classes_screen.dart';
import '../../presentation/screens/classes/class_detail_screen.dart';
import '../../presentation/screens/grade_levels/grade_levels_screen.dart';
import '../../presentation/screens/semesters/semesters_screen.dart';
import '../../presentation/screens/subjects/subjects_management_screen.dart';
import '../../presentation/screens/timetables/timetables_screen.dart';
import '../../presentation/screens/announcements/announcements_screen.dart';
import '../../presentation/screens/absences/absences_screen.dart';
import '../../presentation/screens/grades/grades_screen.dart';
import '../../presentation/screens/results_screen.dart';
import '../../presentation/screens/suggestions/suggestions_screen.dart';
import '../../presentation/screens/payments/payments_screen.dart';
import '../../presentation/screens/documents/documents_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/contact_info_screen.dart';
import '../../presentation/screens/settings/password_reset_requests_screen.dart';
import '../../presentation/screens/structure/building_structure_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  debugLogDiagnostics: true, // Enable debug logging
  errorBuilder: (context, state) {
    debugPrint('GoRouter ERROR: ${state.error}');
    debugPrint('GoRouter ERROR path: ${state.uri}');
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Route non trouvée: ${state.uri}'),
            const SizedBox(height: 8),
            Text('${state.error}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
    GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
    GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
    GoRoute(path: '/users/bulk-photos', builder: (_, _) => const BulkPhotoUploadScreen()),
    GoRoute(path: '/users/bulk-import', builder: (_, _) => const SimpleBulkImportScreen()),
    GoRoute(path: '/classes', builder: (_, _) => const ClassesScreen()),
    GoRoute(
      path: '/classes/:classId', 
      builder: (context, state) => ClassDetailScreen(
        classId: state.pathParameters['classId']!,
      ),
    ),
    GoRoute(path: '/grade-levels', builder: (_, _) => const GradeLevelsScreen()),
    GoRoute(path: '/semesters', builder: (_, _) => const SemestersScreen()),
    GoRoute(path: '/subjects', builder: (_, _) => const SubjectsManagementScreen()),
    GoRoute(path: '/timetables', builder: (_, _) => const TimetablesScreen()),
    GoRoute(path: '/announcements', builder: (_, _) => const AnnouncementsScreen()),
    GoRoute(path: '/absences', builder: (_, _) => const AbsencesScreen()),
    GoRoute(path: '/grades', builder: (_, _) => const GradesScreen()),
    GoRoute(path: '/results', builder: (_, _) => const ResultsScreen()),
    GoRoute(path: '/suggestions', builder: (_, _) => const SuggestionsScreen()),
    GoRoute(path: '/payments', builder: (_, _) => const PaymentsScreen()),
    GoRoute(path: '/documents', builder: (_, _) => const DocumentsScreen()),
    GoRoute(path: '/structure', builder: (_, _) => const BuildingStructureScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/settings/contact-info', builder: (_, _) => const ContactInfoScreen()),
    GoRoute(path: '/password-resets', builder: (_, _) => const PasswordResetRequestsScreen()),
    GoRoute(
      path: '/users/:userId', 
      builder: (context, state) => UserProfileScreen(
        userId: state.pathParameters['userId']!,
      ),
    ),
  ],
);