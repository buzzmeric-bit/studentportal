import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        children: [
          // Language section
          _SettingsSection(
            title: l10n.language,
            icon: Icons.language,
            children: [
              _LanguageTile(
                flag: '🇫🇷',
                language: 'Français',
                isSelected: currentLocale.languageCode == 'fr',
                onTap: () => ref.read(localeProvider.notifier).setLocale('fr'),
              ),
              _LanguageTile(
                flag: '🇬🇧',
                language: 'English',
                isSelected: currentLocale.languageCode == 'en',
                onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
              ),
              _LanguageTile(
                flag: '🇸🇦',
                language: 'العربية',
                isSelected: currentLocale.languageCode == 'ar',
                onTap: () => ref.read(localeProvider.notifier).setLocale('ar'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingM),
          // Theme section
          _SettingsSection(
            title: l10n.theme,
            icon: Icons.palette,
            children: [
              _ThemeTile(
                icon: Icons.brightness_auto,
                label: l10n.systemTheme,
                isSelected: true, // TODO: Implement theme provider
                onTap: () {},
              ),
              _ThemeTile(
                icon: Icons.light_mode,
                label: l10n.lightTheme,
                isSelected: false,
                onTap: () {},
              ),
              _ThemeTile(
                icon: Icons.dark_mode,
                label: l10n.darkTheme,
                isSelected: false,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingM),
          // Notifications section
          _SettingsSection(
            title: l10n.notifications,
            icon: Icons.notifications,
            children: [
              _SwitchTile(
                icon: Icons.campaign,
                label: l10n.announcements,
                value: true,
                onChanged: (value) {},
              ),
              _SwitchTile(
                icon: Icons.message,
                label: l10n.messages,
                value: true,
                onChanged: (value) {},
              ),
              _SwitchTile(
                icon: Icons.grade,
                label: l10n.resultats,
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingL),
          // App info
          Center(
            child: Column(
              children: [
                Text(
                  'Student Portal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSizes.paddingS),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: AppSizes.paddingL),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(language),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.success)
          : Icon(Icons.circle_outlined, color: AppColors.divider),
      onTap: onTap,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.success)
          : Icon(Icons.circle_outlined, color: AppColors.divider),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary.withAlpha(128),
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}
