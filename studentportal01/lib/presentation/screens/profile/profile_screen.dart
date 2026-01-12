import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/enrollment_model.dart';
import '../../providers/auth_provider.dart';

// Demo profile provider
final profileProvider = FutureProvider<({UserModel user, EnrollmentModel enrollment})>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  final user = UserModel(
    id: 'user1',
    schoolId: 'school1',
    role: 'student',
    fullName: 'Ahmed Benali',
    email: 'ahmed.benali@student.univ.dz',
    phone: '+213 555 123 456',
    photoUrl: null,
    studentCode: '20241234',
    dateOfBirth: DateTime(2000, 5, 15),
    address: '123 Rue de l\'Université, Alger',
    createdAt: DateTime(2024, 9, 1),
    updatedAt: DateTime.now(),
  );

  final enrollment = EnrollmentModel(
    id: 'enroll1',
    userId: 'user1',
    classId: 'class1',
    groupId: 'group1',
    academicYearId: 'year1',
    createdAt: DateTime(2024, 9, 1),
    classInfo: ClassModel(
      id: 'class1',
      schoolId: 'school1',
      name: '2ème Année Licence - Gestion',
      level: 'L2',
      year: 2,
      section: 'A',
      createdAt: DateTime(2024, 9, 1),
    ),
    groupInfo: GroupModel(
      id: 'group1',
      classId: 'class1',
      name: 'Groupe 1',
      createdAt: DateTime(2024, 9, 1),
    ),
    academicYear: AcademicYearModel(
      id: 'year1',
      schoolId: 'school1',
      name: '2024-2025',
      startDate: DateTime(2024, 9, 1),
      endDate: DateTime(2025, 7, 31),
      isCurrent: true,
      createdAt: DateTime(2024, 1, 1),
    ),
  );

  return (user: user, enrollment: enrollment);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.monProfil),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: profileAsync.when(
        data: (data) {
          final user = data.user;
          final enrollment = data.enrollment;

          return ListView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            children: [
              // Profile header
              _ProfileHeader(user: user),
              const SizedBox(height: AppSizes.paddingL),
              // Personal info section
              _SectionTitle(title: l10n.personalInfo),
              const SizedBox(height: AppSizes.paddingS),
              _InfoCard(
                items: [
                  _InfoItem(
                    icon: Icons.person,
                    label: l10n.fullName,
                    value: user.fullName,
                  ),
                  _InfoItem(
                    icon: Icons.email,
                    label: l10n.email,
                    value: user.email,
                  ),
                  if (user.phone != null)
                    _InfoItem(
                      icon: Icons.phone,
                      label: l10n.phone,
                      value: user.phone!,
                    ),
                  if (user.dateOfBirth != null)
                    _InfoItem(
                      icon: Icons.cake,
                      label: l10n.dateOfBirth,
                      value: DateFormat('dd/MM/yyyy').format(user.dateOfBirth!),
                    ),
                  if (user.address != null)
                    _InfoItem(
                      icon: Icons.location_on,
                      label: l10n.address,
                      value: user.address!,
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingL),
              // Academic info section
              _SectionTitle(title: l10n.academicInfo),
              const SizedBox(height: AppSizes.paddingS),
              _InfoCard(
                items: [
                  if (user.studentCode != null)
                    _InfoItem(
                      icon: Icons.badge,
                      label: l10n.studentCode,
                      value: user.studentCode!,
                    ),
                  if (enrollment.classInfo != null)
                    _InfoItem(
                      icon: Icons.school,
                      label: l10n.currentClass,
                      value: enrollment.classInfo!.name,
                    ),
                  if (enrollment.groupInfo != null)
                    _InfoItem(
                      icon: Icons.group,
                      label: l10n.group,
                      value: enrollment.groupInfo!.name,
                    ),
                  if (enrollment.academicYear != null)
                    _InfoItem(
                      icon: Icons.calendar_today,
                      label: l10n.academicYear,
                      value: enrollment.academicYear!.name,
                    ),
                ],
              ),
              
              const SizedBox(height: AppSizes.paddingL),
              // Settings section
              _SectionTitle(title: 'Paramètres'),
              const SizedBox(height: AppSizes.paddingS),
              
              // Settings options
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.settings_outlined,
                      title: l10n.settings,
                      onTap: () => context.push('/settings'),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.contact_support_outlined,
                      title: l10n.contactUs,
                      onTap: () => context.push('/contact'),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: l10n.about,
                      onTap: () => context.push('/about'),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: l10n.logout,
                      onTap: () => _showLogoutDialog(context, ref),
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSizes.paddingXL),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.paddingM),
              Text(l10n.error),
              TextButton(
                onPressed: () => ref.refresh(profileProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingS),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Text(l10n.logout),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(authProvider.notifier).signOut();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              backgroundImage: user.photoUrl != null 
                  ? NetworkImage(user.photoUrl!) 
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: AppSizes.paddingM),
            // Name
            Text(
              user.fullName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              user.email,
              style: TextStyle(
                color: AppColors.textLight,
              ),
            ),
            if (user.studentCode != null) ...[
              const SizedBox(height: AppSizes.paddingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                child: Text(
                  user.studentCode!,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          children: items.map((item) {
            final isLast = items.last == item;
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: AppSizes.paddingS),
                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.paddingS),
                ],
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    final iconBgColor = isDestructive 
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.primary.withValues(alpha: 0.1);
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
