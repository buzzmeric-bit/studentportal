import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/messages/messages_screen_new.dart';
import '../../presentation/screens/suggestions/suggestions_screen_new.dart';
import '../../presentation/screens/suggestions/write_suggestion_screen.dart';
import '../../presentation/screens/absences/absences_screen.dart';
import '../../presentation/screens/resultats/resultats_screen.dart';
import '../../presentation/screens/emploi/emploi_screen.dart';
import '../../presentation/screens/courses/courses_screen.dart';
import '../../presentation/screens/courses/course_detail_screen.dart';
import '../../presentation/screens/mon_solde/mon_solde_screen.dart';
import '../../presentation/screens/documents/documents_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/contact/contact_screen.dart';
import '../../presentation/screens/about/about_screen.dart';
import '../../presentation/screens/stats/stats_screen.dart';
import '../../presentation/widgets/bubble_nav_bar.dart';

// Helper to determine the nav bar index based on current location
int _getNavBarIndex(String location) {
  if (location == '/') return 0;
  if (location == '/messages') return 1;
  if (location == '/notifications') return 2;
  if (location == '/stats') return 3;
  if (location.startsWith('/courses')) return 4;
  if (location == '/suggestions') return 0; // Suggestions should highlight home
  if (location == '/write-suggestion') return 0; // Write suggestion should highlight home
  return 0;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoginRoute = state.matchedLocation == '/login';
      
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }
      
      if (isLoggedIn && isLoginRoute) {
        return '/';
      }
      
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Shell Route with persistent bottom nav
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            extendBody: true,
            body: child,
            bottomNavigationBar: BubbleNavBar(
              currentIndex: _getNavBarIndex(state.matchedLocation),
            ),
          );
        },
        routes: [
          // Main Nav Bar Routes
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const MessagesScreen(),
            ),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/stats',
            name: 'stats',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const StatsScreen(),
            ),
          ),
          GoRoute(
            path: '/courses',
            name: 'courses',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const CoursesScreen(),
            ),
          ),
          GoRoute(
            path: '/suggestions',
            name: 'suggestions',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SuggestionsScreen(),
            ),
          ),
          GoRoute(
            path: '/write-suggestion',
            name: 'write-suggestion',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const WriteSuggestionScreen(),
            ),
          ),
        ],
      ),
      
      // Feature Routes (outside nav bar)
      GoRoute(
        path: '/courses/:courseId',
        name: 'course-detail',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return CourseDetailScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/absences',
        name: 'absences',
        builder: (context, state) => const AbsencesScreen(),
      ),
      GoRoute(
        path: '/resultats',
        name: 'resultats',
        builder: (context, state) => const ResultatsScreen(),
      ),
      GoRoute(
        path: '/emploi',
        name: 'emploi',
        builder: (context, state) => const EmploiScreen(),
      ),
      GoRoute(
        path: '/mon-solde',
        name: 'mon-solde',
        builder: (context, state) => const MonSoldeScreen(),
      ),
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/contact',
        name: 'contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
