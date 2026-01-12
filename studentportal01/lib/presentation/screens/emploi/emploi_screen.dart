import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/timetable_model.dart';

// Selected day provider
// Initialize to current day, but clamp to 0-5 (Mon-Sat), default to Monday if Sunday
final selectedDayProvider = StateProvider<int>((ref) {
  final weekday = DateTime.now().weekday;
  // Sunday (7) defaults to Monday (0), otherwise weekday - 1
  return weekday == 7 ? 0 : weekday - 1;
});

// Demo timetable provider
final timetableProvider = FutureProvider<List<TimetableSlotModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  return [
    // Monday
    TimetableSlotModel(
      id: '1',
      subjectOfferingId: 's1',
      dayOfWeek: 'monday',
      startTime: '08:30',
      endTime: '10:00',
      room: 'A101',
      teacherName: 'Prof. Benali',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Marketing',
      subjectCode: 'MKT101',
    ),
    TimetableSlotModel(
      id: '2',
      subjectOfferingId: 's2',
      dayOfWeek: 'monday',
      startTime: '10:15',
      endTime: '11:45',
      room: 'B205',
      teacherName: 'Prof. Mansouri',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Comptabilité Générale',
      subjectCode: 'CPT101',
    ),
    TimetableSlotModel(
      id: '3',
      subjectOfferingId: 's3',
      dayOfWeek: 'monday',
      startTime: '14:00',
      endTime: '15:30',
      room: 'Lab3',
      teacherName: 'Prof. Alami',
      sessionType: 'TP',
      createdAt: DateTime.now(),
      subjectName: 'Informatique de Gestion',
      subjectCode: 'INF101',
    ),
    // Tuesday
    TimetableSlotModel(
      id: '4',
      subjectOfferingId: 's4',
      dayOfWeek: 'tuesday',
      startTime: '08:30',
      endTime: '10:00',
      room: 'A102',
      teacherName: 'Prof. Kaddouri',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Droit des Affaires',
      subjectCode: 'DRT101',
    ),
    TimetableSlotModel(
      id: '5',
      subjectOfferingId: 's5',
      dayOfWeek: 'tuesday',
      startTime: '10:15',
      endTime: '11:45',
      room: 'C301',
      teacherName: 'Prof. Smith',
      sessionType: 'TD',
      createdAt: DateTime.now(),
      subjectName: 'Anglais Commercial',
      subjectCode: 'ANG101',
    ),
    // Wednesday
    TimetableSlotModel(
      id: '6',
      subjectOfferingId: 's2',
      dayOfWeek: 'wednesday',
      startTime: '08:30',
      endTime: '10:00',
      room: 'Lab1',
      teacherName: 'Prof. Mansouri',
      sessionType: 'TP',
      createdAt: DateTime.now(),
      subjectName: 'Comptabilité Générale',
      subjectCode: 'CPT101',
    ),
    TimetableSlotModel(
      id: '7',
      subjectOfferingId: 's1',
      dayOfWeek: 'wednesday',
      startTime: '10:15',
      endTime: '11:45',
      room: 'A101',
      teacherName: 'Prof. Benali',
      sessionType: 'TD',
      createdAt: DateTime.now(),
      subjectName: 'Marketing',
      subjectCode: 'MKT101',
    ),
    // Thursday
    TimetableSlotModel(
      id: '8',
      subjectOfferingId: 's3',
      dayOfWeek: 'thursday',
      startTime: '08:30',
      endTime: '10:00',
      room: 'A201',
      teacherName: 'Prof. Alami',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Informatique de Gestion',
      subjectCode: 'INF101',
    ),
    TimetableSlotModel(
      id: '9',
      subjectOfferingId: 's4',
      dayOfWeek: 'thursday',
      startTime: '14:00',
      endTime: '15:30',
      room: 'A102',
      teacherName: 'Prof. Kaddouri',
      sessionType: 'TD',
      createdAt: DateTime.now(),
      subjectName: 'Droit des Affaires',
      subjectCode: 'DRT101',
    ),
    // Friday
    TimetableSlotModel(
      id: '10',
      subjectOfferingId: 's5',
      dayOfWeek: 'friday',
      startTime: '08:30',
      endTime: '10:00',
      room: 'C301',
      teacherName: 'Prof. Smith',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Anglais Commercial',
      subjectCode: 'ANG101',
    ),
  ];
});

class EmploiScreen extends ConsumerWidget {
  const EmploiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedDay = ref.watch(selectedDayProvider);
    final timetableAsync = ref.watch(timetableProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.emploi),
        backgroundColor: AppColors.tileEmploi,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Day selector
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
              itemCount: 6, // Monday to Saturday
              itemBuilder: (context, index) {
                final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
                final isSelected = selectedDay == index;
                final isToday = DateTime.now().weekday - 1 == index;

                return GestureDetector(
                  onTap: () => ref.read(selectedDayProvider.notifier).state = index,
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.tileEmploi : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.tileEmploi, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          days[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : AppColors.tileEmploi,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Content
          Expanded(
            child: timetableAsync.when(
              data: (slots) {
                final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
                final selectedDayName = dayNames[selectedDay];
                final daySlots = slots.where((s) => s.dayOfWeek == selectedDayName).toList();
                daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));

                if (daySlots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        Text(
                          l10n.noCourses,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  itemCount: daySlots.length,
                  itemBuilder: (context, index) {
                    final slot = daySlots[index];
                    return _TimetableCard(slot: slot);
                  },
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
                      onPressed: () => ref.refresh(timetableProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableCard extends StatelessWidget {
  final TimetableSlotModel slot;

  const _TimetableCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    // Session type colors
    Color typeColor;
    String typeLabel;

    switch (slot.sessionType.toUpperCase()) {
      case 'CI':
        typeColor = AppColors.primary;
        typeLabel = 'CI';
        break;
      case 'TP':
        typeColor = Colors.green;
        typeLabel = 'TP';
        break;
      case 'TD':
        typeColor = Colors.orange;
        typeLabel = 'TD';
        break;
      default:
        typeColor = Colors.grey;
        typeLabel = slot.sessionType;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left time indicator
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.cardBorderRadius),
                  bottomLeft: Radius.circular(AppSizes.cardBorderRadius),
                ),
              ),
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot.startTime,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 20,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: typeColor.withOpacity(0.3),
                  ),
                  Text(
                    slot.endTime,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            slot.subjectName ?? 'N/A',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(AppSizes.radiusS),
                          ),
                          child: Text(
                            typeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (slot.subjectCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        slot.subjectCode!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textLight,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.paddingS),
                    Row(
                      children: [
                        if (slot.room != null) ...[
                          Icon(Icons.room, size: 16, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            slot.room!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingM),
                        ],
                        if (slot.teacherName != null) ...[
                          Icon(Icons.person, size: 16, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              slot.teacherName!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
