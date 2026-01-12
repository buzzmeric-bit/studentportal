import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.about),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          children: [
            // Logo and app name
            const SizedBox(height: AppSizes.paddingL),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),
            Text(
              'Student Portal',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingXS),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingXL),
            // Description
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    Text(
                      l10n.aboutDesc,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            // Features
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSizes.paddingS),
                        Text(
                          l10n.features,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSizes.paddingL),
                    _FeatureItem(
                      icon: Icons.campaign,
                      text: l10n.featureAnnouncements,
                    ),
                    _FeatureItem(
                      icon: Icons.grade,
                      text: l10n.featureGrades,
                    ),
                    _FeatureItem(
                      icon: Icons.event_busy,
                      text: l10n.featureAbsences,
                    ),
                    _FeatureItem(
                      icon: Icons.calendar_month,
                      text: l10n.featureTimetable,
                    ),
                    _FeatureItem(
                      icon: Icons.payment,
                      text: l10n.featurePayments,
                    ),
                    _FeatureItem(
                      icon: Icons.folder,
                      text: l10n.featureDocuments,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            // Credits
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code, color: AppColors.success, size: 20),
                        const SizedBox(width: AppSizes.paddingS),
                        Text(
                          l10n.developedBy,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSizes.paddingL),
                    const Text(
                      'ISGC Development Team',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingS),
                    Text(
                      '© 2025 ISGC. ${l10n.allRightsReserved}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),
            // Legal links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(l10n.privacyPolicy),
                ),
                const Text('•'),
                TextButton(
                  onPressed: () {},
                  child: Text(l10n.termsOfService),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingL),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSizes.paddingM),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
