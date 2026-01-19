import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/suggestions_provider.dart';
import '../../providers/avatar_provider.dart';
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
          final headerHeight = screenHeight * 0.42;

          return Stack(
            children: [
              // Glassmorphism gradient background - frosted iOS style
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8D5F2), // Lavender / lilac
                      Color(0xFFD4C4E8), // Soft lilac
                      Color(0xFFC9D6F0), // Light periwinkle
                      Color(0xFFE0EAF5), // Icy blue-white
                      Color(0xFFF0F5FA), // Cool icy white
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
              // Scrollable content - hide scrollbar
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(authProvider.notifier).refreshUserData();
                  },
                  color: const Color(0xFF6366F1),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: screenHeight),
                      child: Column(
                        children: [
                          // Hero Header Section - fixed height
                          SizedBox(
                            height: headerHeight,
                            child: SafeArea(
                              bottom: false,
                              child: _buildHeader(context, ref, user, enrollment),
                            ),
                          ),

                          // Frosted glass content area with rounded top
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(40),
                                  topRight: Radius.circular(40),
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 32),
                                  // Grid Section
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      childAspectRatio: 0.90,
                                      children: _buildGridCards(
                                        context,
                                        l10n,
                                        ref,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 110), // Nav bar space
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic user, dynamic enrollment) {
    final avatarState = ref.watch(avatarProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
                        child: _buildAvatarContent(avatarState, user),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Text content
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

              const SizedBox(height: 4),

              // First name
              Builder(
                builder: (context) {
                  final fullName = user?.fullName ?? 'Ahmed Benali';
                  final nameParts = fullName.split(' ');
                  final firstName = nameParts.isNotEmpty
                      ? nameParts.first
                      : fullName;
                  final lastName = nameParts.length > 1
                      ? nameParts.sublist(1).join(' ')
                      : '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          firstName,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                            height: 1.05,
                          ),
                        ),
                      ),
                      if (lastName.isNotEmpty)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            lastName,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                              height: 1.05,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              // Niveau and Class info - plain text under the name (no pill background)
              Text(
                enrollment != null && enrollment.classInfo != null
                    ? '${enrollment.classInfo!.name}${enrollment.groupInfo != null ? ' • Groupe ${enrollment.groupInfo!.name}' : ''}'
                    : 'Classe non définie',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          // Bottom spacer
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildGridCards(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    // Get count of suggestions that have been replied or marked as seen
    final suggestionBadgeCount = ref.watch(
      repliedOrSeenSuggestionsCountProvider,
    );

    final cards = [
      _CardData(
        icon: Icons.lightbulb_rounded,
        label: l10n.suggestions,
        subtitle: 'Partagez vos suggestions',
        route: '/suggestions',
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        iconAlignment: Alignment.topLeft,
        badgeCount: suggestionBadgeCount,
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

    return cards
        .map(
          (card) => GlassCard(
            icon: card.icon,
            label: card.label,
            subtitle: card.subtitle,
            gradientColors: card.gradientColors,
            iconAlignment: card.iconAlignment,
            badgeCount: card.badgeCount,
            onTap: () => context.go(card.route),
          ),
        )
        .toList();
  }

  Widget _buildDrawer(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
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
                  // White Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.grey[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.logout,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(AvatarState avatarState, dynamic user) {
    // Priority: Custom avatar > Preset avatar > User photo > Default icon
    if (avatarState.isCustom && avatarState.customFilePath != null) {
      // Custom uploaded image
      if (kIsWeb) {
        // On web, use Image.network for blob URLs
        return Image.network(
          avatarState.customFilePath!,
          fit: BoxFit.cover,
          width: 64,
          height: 64,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person_rounded,
            color: Color(0xFF8B5CF6),
            size: 36,
          ),
        );
      } else {
        return Image.file(
          File(avatarState.customFilePath!),
          fit: BoxFit.cover,
          width: 64,
          height: 64,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person_rounded,
            color: Color(0xFF8B5CF6),
            size: 36,
          ),
        );
      }
    } else if (avatarState.presetPath != null) {
      // Preset avatar
      return Image.asset(
        avatarState.presetPath!,
        fit: BoxFit.cover,
        width: 64,
        height: 64,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          color: Color(0xFF8B5CF6),
          size: 36,
        ),
      );
    } else if (user?.photoUrl != null) {
      // User's photo URL from database
      return Image.network(
        user!.photoUrl!,
        fit: BoxFit.cover,
        width: 64,
        height: 64,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          color: Color(0xFF8B5CF6),
          size: 36,
        ),
      );
    } else {
      // Default person icon
      return const Icon(
        Icons.person_rounded,
        color: Color(0xFF8B5CF6),
        size: 36,
      );
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6366F1),
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontWeight: FontWeight.w600,
          fontSize: 15,
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
