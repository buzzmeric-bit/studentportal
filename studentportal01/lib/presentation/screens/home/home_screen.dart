import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final enrollment = authState.enrollment;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBody: true,
      drawer: _buildDrawer(context, l10n, ref),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final headerHeight = screenHeight * 0.38;
          
          return Stack(
            children: [
              // Purple gradient background - full screen
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFB794F6),
                      Color(0xFF9B87F5),
                      Color(0xFF7C9AF5),
                      Color(0xFF6BBAFF),
                    ],
                  ),
                ),
              ),
              // Scrollable content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Hero Header Section - fixed height
                    SizedBox(
                      height: headerHeight,
                      child: SafeArea(
                        bottom: false,
                        child: _buildHeader(context, user, enrollment),
                      ),
                    ),
                    
                    // White content area with rounded top
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          // Grid Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.90,
                              children: _buildGridCards(context, l10n),
                            ),
                          ),
                          const SizedBox(height: 110), // Nav bar space
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, dynamic enrollment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Menu and Profile
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu Icon
                Builder(
                  builder: (context) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 20,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Profile Picture
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/profile'),
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: user?.photoUrl != null
                            ? Image.network(
                                user!.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF8B5CF6),
                                  size: 36,
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF8B5CF6),
                                size: 36,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Text content - centered vertically in remaining space
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small greeting
              Text(
                'Bonjour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // HUGE name
              Text(
                user?.fullName ?? 'Ahmed Benali',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.5,
                  height: 1.05,
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Floating chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  enrollment != null
                      ? '${enrollment.classInfo?.name ?? '1ère Année Licence'}'
                          '${enrollment.groupInfo != null ? ' • Groupe ${enrollment.groupInfo!.name}' : ' • Groupe A'}'
                      : '1ère Année Licence • Groupe A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          
          // Bottom spacer
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildGridCards(BuildContext context, AppLocalizations l10n) {
    final cards = [
      _CardData(
        icon: Icons.lightbulb_rounded,
        label: l10n.suggestions,
        subtitle: 'Partagez vos suggestions',
        route: '/suggestions',
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        iconAlignment: Alignment.topLeft,
        badgeCount: 1,
      ),
      _CardData(
        icon: Icons.event_busy_rounded,
        label: l10n.absences,
        subtitle: 'Consultez vos absences',
        route: '/absences',
        gradientColors: const [Color(0xFFEC4899), Color(0xFFF43F5E)],
        iconAlignment: Alignment.topLeft,
      ),
      _CardData(
        icon: Icons.bar_chart_rounded,
        label: l10n.resultats,
        subtitle: 'Vérifiez vos résultats',
        route: '/resultats',
        gradientColors: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
        iconAlignment: Alignment.topLeft,
      ),
      _CardData(
        icon: Icons.calendar_month_rounded,
        label: l10n.emploi,
        subtitle: 'Votre emploi du temps',
        route: '/emploi',
        gradientColors: const [Color(0xFF10B981), Color(0xFF14B8A6)],
        iconAlignment: Alignment.topLeft,
      ),
      _CardData(
        icon: Icons.payment_rounded,
        label: l10n.monSolde,
        subtitle: 'Gérez vos paiements',
        route: '/mon-solde',
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFF97316)],
        iconAlignment: Alignment.topLeft,
      ),
      _CardData(
        icon: Icons.folder_rounded,
        label: l10n.documents,
        subtitle: 'Accédez aux documents',
        route: '/documents',
        gradientColors: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
        iconAlignment: Alignment.topLeft,
      ),
    ];

    return cards.map((card) => GlassCard(
      icon: card.icon,
      label: card.label,
      subtitle: card.subtitle,
      gradientColors: card.gradientColors,
      iconAlignment: card.iconAlignment,
      badgeCount: card.badgeCount,
      onTap: () => context.push(card.route),
    )).toList();
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB794F6),
              Color(0xFF9B87F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _DrawerItem(
                icon: Icons.settings_rounded,
                label: l10n.settings,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
              _DrawerItem(
                icon: Icons.contact_support_rounded,
                label: l10n.contactUs,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/contact');
                },
              ),
              _DrawerItem(
                icon: Icons.info_rounded,
                label: l10n.about,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/about');
                },
              ),
              const Spacer(),
              _DrawerItem(
                icon: Icons.logout_rounded,
                label: l10n.logout,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                isDestructive: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? const Color(0xFFF43F5E) : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? const Color(0xFFF43F5E) : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _CardData {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final List<Color> gradientColors;
  final Alignment iconAlignment;
  final int? badgeCount;

  _CardData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
    required this.gradientColors,
    this.iconAlignment = Alignment.topLeft,
    this.badgeCount,
  });
}

