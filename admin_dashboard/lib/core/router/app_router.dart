import 'package:go_router/go_router.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/users/users_screen.dart';
import '../../presentation/screens/classes/classes_screen.dart';
import '../../presentation/screens/groups/groups_screen.dart';
import '../../presentation/screens/semesters/semesters_screen.dart';
import '../../presentation/screens/subjects/subjects_screen.dart';
import '../../presentation/screens/timetables/timetables_screen.dart';
import '../../presentation/screens/announcements/announcements_screen.dart';
import '../../presentation/screens/absences/absences_screen.dart';
import '../../presentation/screens/grades/grades_screen.dart';
import '../../presentation/screens/suggestions/suggestions_screen.dart';
import '../../presentation/screens/payments/payments_screen.dart';
import '../../presentation/screens/documents/documents_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/contact_info_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
    GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
    GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
    GoRoute(path: '/classes', builder: (_, _) => const ClassesScreen()),
    GoRoute(path: '/groups', builder: (_, _) => const GroupsScreen()),
    GoRoute(path: '/semesters', builder: (_, _) => const SemestersScreen()),
    GoRoute(path: '/subjects', builder: (_, _) => const SubjectsScreen()),
    GoRoute(path: '/timetables', builder: (_, _) => const TimetablesScreen()),
    GoRoute(path: '/announcements', builder: (_, _) => const AnnouncementsScreen()),
    GoRoute(path: '/absences', builder: (_, _) => const AbsencesScreen()),
    GoRoute(path: '/grades', builder: (_, _) => const GradesScreen()),
    GoRoute(path: '/suggestions', builder: (_, _) => const SuggestionsScreen()),
    GoRoute(path: '/payments', builder: (_, _) => const PaymentsScreen()),
    GoRoute(path: '/documents', builder: (_, _) => const DocumentsScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/settings/contact-info', builder: (_, _) => const ContactInfoScreen()),
  ],
);