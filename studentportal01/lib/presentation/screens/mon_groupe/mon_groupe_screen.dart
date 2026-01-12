import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';

// Demo group members provider
final groupMembersProvider = FutureProvider<GroupData>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  return GroupData(
    className: '1ère Année Gestion',
    groupName: 'Groupe A',
    members: [
      StudentInfo(
        id: '1',
        firstName: 'Ahmed',
        lastName: 'Benali',
        email: 'ahmed.benali@student.isgc.ma',
        avatarUrl: null,
      ),
      StudentInfo(
        id: '2',
        firstName: 'Fatima',
        lastName: 'Alaoui',
        email: 'fatima.alaoui@student.isgc.ma',
        avatarUrl: null,
      ),
      StudentInfo(
        id: '3',
        firstName: 'Youssef',
        lastName: 'Mansouri',
        email: 'youssef.mansouri@student.isgc.ma',
        avatarUrl: null,
      ),
      StudentInfo(
        id: '4',
        firstName: 'Sara',
        lastName: 'Kabbaj',
        email: 'sara.kabbaj@student.isgc.ma',
        avatarUrl: null,
      ),
      StudentInfo(
        id: '5',
        firstName: 'Omar',
        lastName: 'Tazi',
        email: 'omar.tazi@student.isgc.ma',
        avatarUrl: null,
      ),
      StudentInfo(
        id: '6',
        firstName: 'Leila',
        lastName: 'Chraibi',
        email: 'leila.chraibi@student.isgc.ma',
        avatarUrl: null,
      ),
      StudentInfo(
        id: '7',
        firstName: 'Mehdi',
        lastName: 'Fassi',
        email: 'mehdi.fassi@student.isgc.ma',
        avatarUrl: null,
      ),
      StudentInfo(
        id: '8',
        firstName: 'Nadia',
        lastName: 'Bennani',
        email: 'nadia.bennani@student.isgc.ma',
        avatarUrl: null,
      ),
      StudentInfo(
        id: '9',
        firstName: 'Karim',
        lastName: 'Idrissi',
        email: 'karim.idrissi@student.isgc.ma',
        avatarUrl: null,
      ),
      StudentInfo(
        id: '10',
        firstName: 'Houda',
        lastName: 'Sekkat',
        email: 'houda.sekkat@student.isgc.ma',
        avatarUrl: null,
      ),
    ],
  );
});

class GroupData {
  final String className;
  final String groupName;
  final List<StudentInfo> members;

  GroupData({
    required this.className,
    required this.groupName,
    required this.members,
  });
}

class StudentInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;

  StudentInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}';
}

class MonGroupeScreen extends ConsumerWidget {
  const MonGroupeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groupDataAsync = ref.watch(groupMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.monGroupe),
        backgroundColor: AppColors.tileMonGroupe,
        foregroundColor: Colors.white,
      ),
      body: groupDataAsync.when(
        data: (groupData) {
          return Column(
            children: [
              // Group info header
              Container(
                margin: const EdgeInsets.all(AppSizes.paddingM),
                padding: const EdgeInsets.all(AppSizes.paddingL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tileMonGroupe,
                      AppColors.tileMonGroupe.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingM),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupData.className,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: AppSizes.fontS,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            groupData.groupName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppSizes.fontXL,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingM,
                        vertical: AppSizes.paddingS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${groupData.members.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchStudents,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingM,
                      vertical: AppSizes.paddingS,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              // Members list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                  itemCount: groupData.members.length,
                  itemBuilder: (context, index) {
                    final member = groupData.members[index];
                    return _MemberCard(member: member, index: index + 1);
                  },
                ),
              ),
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
                onPressed: () => ref.refresh(groupMembersProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final StudentInfo member;
  final int index;

  const _MemberCard({required this.member, required this.index});

  @override
  Widget build(BuildContext context) {
    // Generate a color based on index for variety
    final colors = [
      AppColors.primary,
      AppColors.tileNoteInfo,
      AppColors.tileMessages,
      AppColors.tileSuggestions,
      AppColors.tileAbsences,
      AppColors.tileResultats,
      AppColors.tileEmploi,
      AppColors.tileMonGroupe,
      AppColors.tileMonSolde,
      AppColors.tileDocuments,
    ];
    final color = colors[index % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingXS,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            member.initials,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          member.email,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontS,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.email_outlined, color: color),
          onPressed: () {
            // TODO: Open email client
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Email: ${member.email}')),
            );
          },
        ),
      ),
    );
  }
}
