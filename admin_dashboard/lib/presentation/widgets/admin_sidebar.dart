import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/settings/password_reset_requests_screen.dart';

class AdminSidebar extends ConsumerWidget {
  final String currentRoute;
  const AdminSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch pending password reset count
    final pendingCountAsync = ref.watch(pendingPasswordResetCountProvider);
    final pendingCount = pendingCountAsync.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'PRINCIPAL'),
                  _NavItem(
                    icon: Icons.dashboard,
                    label: 'Tableau de bord',
                    route: '/dashboard',
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.people,
                    label: 'Utilisateurs',
                    route: '/users',
                    currentRoute: currentRoute,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'ACADÉMIQUE'),
                  _NavItem(
                    icon: Icons.school,
                    label: 'Niveaux',
                    route: '/grade-levels',
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.class_,
                    label: 'Classes',
                    route: '/classes',
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.calendar_today,
                    label: 'Semestres',
                    route: '/semesters',
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.book,
                    label: 'Matières',
                    route: '/subjects',
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.schedule,
                    label: 'Emplois du temps',
                    route: '/timetables',
                    currentRoute: currentRoute,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'SUIVI'),
                  _NavItem(
                    icon: Icons.event_busy,
                    label: 'Absences',
                    route: '/absences',
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.grade,
                    label: 'Notes',
                    route: '/grades',
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.analytics_outlined,
                    label: 'Résultats',
                    route: '/results',
                    currentRoute: currentRoute,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'COMMUNICATION'),
                  _NavItem(
                    icon: Icons.campaign,
                    label: 'Annonces',
                    route: '/announcements',
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.feedback,
                    label: 'Suggestions',
                    route: '/suggestions',
                    currentRoute: currentRoute,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'INFRASTRUCTURE'),
                  _NavItem(
                    icon: Icons.business,
                    label: 'Structure',
                    route: '/structure',
                    currentRoute: currentRoute,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'GESTION'),
                  _NavItem(
                    icon: Icons.payment,
                    label: 'Paiements',
                    route: '/payments',
                    currentRoute: currentRoute,
                  ),
                  _NavItem(
                    icon: Icons.description,
                    label: 'Documents',
                    route: '/documents',
                    currentRoute: currentRoute,
                  ),
                  _NavItemWithBadge(
                    icon: Icons.lock_reset,
                    label: 'Mot de passe',
                    route: '/password-resets',
                    currentRoute: currentRoute,
                    badgeCount: pendingCount,
                  ),
                  _NavItem(
                    icon: Icons.settings,
                    label: 'Paramètres',
                    route: '/settings',
                    currentRoute: currentRoute,
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70, size: 20),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            onTap: () => context.go('/login'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isActive =
        currentRoute == route || (route == '/dashboard' && currentRoute == '/');

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.white70,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.white70,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => context.go(route),
      ),
    );
  }
}

/// Nav item with notification badge
class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final int badgeCount;

  const _NavItemWithBadge({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.white70,
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.white70,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => context.go(route),
      ),
    );
  }
}
