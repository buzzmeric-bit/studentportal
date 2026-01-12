import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.contact),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  Text(
                    l10n.needHelp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppSizes.fontXL,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                  Text(
                    l10n.contactDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: AppSizes.fontM,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),
            // Contact options
            _ContactCard(
              icon: Icons.email,
              color: AppColors.tileMessages,
              title: l10n.emailUs,
              subtitle: 'contact@isgc.ma',
              onTap: () {
                // TODO: Open email client
              },
            ),
            _ContactCard(
              icon: Icons.phone,
              color: AppColors.success,
              title: l10n.callUs,
              subtitle: '+212 5XX XX XX XX',
              onTap: () {
                // TODO: Open phone dialer
              },
            ),
            _ContactCard(
              icon: Icons.location_on,
              color: AppColors.error,
              title: l10n.visitUs,
              subtitle: 'Rue de l\'école, Casablanca',
              onTap: () {
                // TODO: Open maps
              },
            ),
            _ContactCard(
              icon: Icons.access_time,
              color: AppColors.tileEmploi,
              title: l10n.officeHours,
              subtitle: l10n.officeHoursValue,
              onTap: null,
            ),
            const SizedBox(height: AppSizes.paddingL),
            // Social media
            Text(
              l10n.followUs,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(
                  icon: Icons.facebook,
                  color: const Color(0xFF1877F2),
                  onTap: () {},
                ),
                const SizedBox(width: AppSizes.paddingM),
                _SocialButton(
                  icon: Icons.camera_alt,
                  color: const Color(0xFFE4405F),
                  onTap: () {},
                ),
                const SizedBox(width: AppSizes.paddingM),
                _SocialButton(
                  icon: Icons.link,
                  color: const Color(0xFF0A66C2),
                  onTap: () {},
                ),
                const SizedBox(width: AppSizes.paddingM),
                _SocialButton(
                  icon: Icons.public,
                  color: AppColors.primary,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSizes.paddingM),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        trailing: onTap != null
            ? Icon(Icons.chevron_right, color: AppColors.textLight)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
