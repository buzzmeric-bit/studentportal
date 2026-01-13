import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../providers/announcements_provider.dart';

class BottomNavDrawer extends ConsumerWidget {
  const BottomNavDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Get real counts from providers
    final messagesAsync = ref.watch(classMessagesProvider);
    final notificationsAsync = ref.watch(globalAnnouncementsProvider);

    final messagesCount = messagesAsync.whenOrNull(data: (m) => m.length) ?? 0;
    final notificationsCount =
        notificationsAsync.whenOrNull(data: (n) => n.length) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: AppSizes.paddingM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: l10n.home,
                  onTap: () => context.go('/'),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.mail_rounded,
                  label: l10n.messages,
                  onTap: () => context.push('/messages'),
                  badgeCount: messagesCount > 0 ? messagesCount : null,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.notifications_rounded,
                  label: l10n.notifications,
                  onTap: () => context.push('/note-info'),
                  badgeCount: notificationsCount > 0
                      ? notificationsCount
                      : null,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_rounded,
                  label: l10n.profile,
                  onTap: () => context.push('/profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXS,
          vertical: AppSizes.paddingS,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 26, color: AppColors.textSecondary),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            // Badge
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: -4,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeCount! > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
