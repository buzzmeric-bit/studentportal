import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/timetable_model.dart';
import '../../providers/student_context_provider.dart';
import '../../widgets/semester_navigator.dart';

// Selected semester for timetable
final emploiSemesterProvider = StateProvider<int>((ref) => 1);

// Subject colors map - each subject gets a unique color
final Map<String, Color> _subjectColors = {};

Color _getSubjectColor(String subjectCode) {
  if (!_subjectColors.containsKey(subjectCode)) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
      const Color(0xFF3B82F6), // Blue
    ];
    _subjectColors[subjectCode] = colors[_subjectColors.length % colors.length];
  }
  return _subjectColors[subjectCode]!;
}

// Time slots from 8am to 5pm (8:00 - 17:00)
const List<String> _timeSlots = [
  '08:00', '08:30',
  '09:00', '09:30',
  '10:00', '10:30',
  '11:00', '11:30',
  '12:00', '12:30',
  '13:00', '13:30',
  '14:00', '14:30',
  '15:00', '15:30',
  '16:00', '16:30',
  '17:00',
];

// Days of the week (7 days)
const List<String> _dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
const List<String> _dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

// Demo timetable provider
final timetableProvider = FutureProvider<List<TimetableSlotModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  return [
    // Monday
    TimetableSlotModel(
      id: '1',
      subjectOfferingId: 's1',
      dayOfWeek: 'monday',
      startTime: '08:00',
      endTime: '09:30',
      room: 'A101',
      teacherName: 'Prof. Benali',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Mathématiques',
      subjectCode: 'MATH',
    ),
    TimetableSlotModel(
      id: '2',
      subjectOfferingId: 's2',
      dayOfWeek: 'monday',
      startTime: '10:00',
      endTime: '11:30',
      room: 'B205',
      teacherName: 'Prof. Mansouri',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Physique',
      subjectCode: 'PHYS',
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
      subjectName: 'Informatique',
      subjectCode: 'INFO',
    ),
    // Tuesday
    TimetableSlotModel(
      id: '4',
      subjectOfferingId: 's4',
      dayOfWeek: 'tuesday',
      startTime: '08:00',
      endTime: '09:30',
      room: 'A102',
      teacherName: 'Prof. Kaddouri',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Français',
      subjectCode: 'FR',
    ),
    TimetableSlotModel(
      id: '5',
      subjectOfferingId: 's5',
      dayOfWeek: 'tuesday',
      startTime: '10:00',
      endTime: '11:30',
      room: 'C301',
      teacherName: 'Prof. Smith',
      sessionType: 'TD',
      createdAt: DateTime.now(),
      subjectName: 'Anglais',
      subjectCode: 'ANG',
    ),
    TimetableSlotModel(
      id: '6',
      subjectOfferingId: 's1',
      dayOfWeek: 'tuesday',
      startTime: '14:00',
      endTime: '15:30',
      room: 'A101',
      teacherName: 'Prof. Benali',
      sessionType: 'TD',
      createdAt: DateTime.now(),
      subjectName: 'Mathématiques',
      subjectCode: 'MATH',
    ),
    // Wednesday
    TimetableSlotModel(
      id: '7',
      subjectOfferingId: 's2',
      dayOfWeek: 'wednesday',
      startTime: '08:00',
      endTime: '09:30',
      room: 'Lab1',
      teacherName: 'Prof. Mansouri',
      sessionType: 'TP',
      createdAt: DateTime.now(),
      subjectName: 'Physique',
      subjectCode: 'PHYS',
    ),
    TimetableSlotModel(
      id: '8',
      subjectOfferingId: 's6',
      dayOfWeek: 'wednesday',
      startTime: '10:00',
      endTime: '11:30',
      room: 'A101',
      teacherName: 'Prof. Hadj',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Arabe',
      subjectCode: 'ARB',
    ),
    // Thursday
    TimetableSlotModel(
      id: '9',
      subjectOfferingId: 's3',
      dayOfWeek: 'thursday',
      startTime: '08:00',
      endTime: '09:30',
      room: 'A201',
      teacherName: 'Prof. Alami',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Informatique',
      subjectCode: 'INFO',
    ),
    TimetableSlotModel(
      id: '10',
      subjectOfferingId: 's7',
      dayOfWeek: 'thursday',
      startTime: '10:00',
      endTime: '11:30',
      room: 'Gym',
      teacherName: 'Prof. Bouzid',
      sessionType: 'TP',
      createdAt: DateTime.now(),
      subjectName: 'Sport',
      subjectCode: 'EPS',
    ),
    TimetableSlotModel(
      id: '11',
      subjectOfferingId: 's4',
      dayOfWeek: 'thursday',
      startTime: '14:00',
      endTime: '15:30',
      room: 'A102',
      teacherName: 'Prof. Kaddouri',
      sessionType: 'TD',
      createdAt: DateTime.now(),
      subjectName: 'Français',
      subjectCode: 'FR',
    ),
    // Friday
    TimetableSlotModel(
      id: '12',
      subjectOfferingId: 's5',
      dayOfWeek: 'friday',
      startTime: '08:00',
      endTime: '09:30',
      room: 'C301',
      teacherName: 'Prof. Smith',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Anglais',
      subjectCode: 'ANG',
    ),
    TimetableSlotModel(
      id: '13',
      subjectOfferingId: 's8',
      dayOfWeek: 'friday',
      startTime: '10:00',
      endTime: '11:30',
      room: 'A105',
      teacherName: 'Prof. Slim',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Histoire-Géo',
      subjectCode: 'HG',
    ),
    // Saturday
    TimetableSlotModel(
      id: '14',
      subjectOfferingId: 's1',
      dayOfWeek: 'saturday',
      startTime: '08:00',
      endTime: '10:00',
      room: 'A101',
      teacherName: 'Prof. Benali',
      sessionType: 'CI',
      createdAt: DateTime.now(),
      subjectName: 'Mathématiques',
      subjectCode: 'MATH',
    ),
  ];
});

class EmploiScreen extends ConsumerStatefulWidget {
  const EmploiScreen({super.key});

  @override
  ConsumerState<EmploiScreen> createState() => _EmploiScreenState();
}

class _EmploiScreenState extends ConsumerState<EmploiScreen> {
  static const Color _accentColor = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedSemester = ref.watch(emploiSemesterProvider);
    final timetableAsync = ref.watch(timetableProvider);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8D5F2),
              Color(0xFFD4C4E8),
              Color(0xFFC9D6F0),
              Color(0xFFE0EAF5),
              Color(0xFFF0F5FA),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: _buildHeader(l10n),
              ),
              // Semester Navigator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: DynamicSemesterNav(
                  selectedSemesterNumber: selectedSemester,
                  onChanged: (v) => ref.read(emploiSemesterProvider.notifier).state = v,
                ),
              ),
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: timetableAsync.when(
                  data: (slots) => _buildScrollableTimetable(context, slots),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Erreur: $error'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.emploi,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Emploi du temps 7/7',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableTimetable(BuildContext context, List<TimetableSlotModel> slots) {
    // Group slots by day
    final slotsByDay = <String, List<TimetableSlotModel>>{};
    for (final day in _dayKeys) {
      slotsByDay[day] = slots.where((s) => s.dayOfWeek == day).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Day header spacer
                const SizedBox(height: 50),
                // Time slots
                ...List.generate(_timeSlots.length, (index) {
                  return Container(
                    height: 30,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _timeSlots[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Days columns
          ...List.generate(7, (dayIndex) {
            final dayKey = _dayKeys[dayIndex];
            final daySlots = slotsByDay[dayKey] ?? [];
            final isToday = _isToday(dayIndex);

            return _buildDayColumn(dayIndex, dayKey, daySlots, isToday);
          }),
        ],
      ),
    );
  }

  bool _isToday(int dayIndex) {
    final now = DateTime.now();
    return now.weekday == dayIndex + 1;
  }

  Widget _buildDayColumn(int dayIndex, String dayKey, List<TimetableSlotModel> daySlots, bool isToday) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          // Day header
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isToday
                    ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)])
                    : null,
                color: isToday ? null : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _dayLabels[dayIndex],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
          // Time slots grid
          SizedBox(
            height: _timeSlots.length * 30.0,
            child: Stack(
              children: [
                // Background grid
                Column(
                  children: List.generate(_timeSlots.length, (i) {
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Slots
                ...daySlots.map((slot) => _buildSlotWidget(slot)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotWidget(TimetableSlotModel slot) {
    final startMinutes = _timeToMinutes(slot.startTime);
    final endMinutes = _timeToMinutes(slot.endTime);
    final duration = endMinutes - startMinutes;

    final baseMinutes = _timeToMinutes(_timeSlots.first);
    final topOffset = ((startMinutes - baseMinutes) / 30.0) * 30.0;
    final height = (duration / 30.0) * 30.0;

    final color = _getSubjectColor(slot.subjectCode ?? 'DEFAULT');

    return Positioned(
      top: topOffset,
      left: 2,
      right: 2,
      height: height,
      child: GestureDetector(
        onTap: () => _showSlotDetail(slot),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slot.subjectCode ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (height > 40)
                Text(
                  slot.room ?? '',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _showSlotDetail(TimetableSlotModel slot) {
    final color = _getSubjectColor(slot.subjectCode ?? 'DEFAULT');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.book_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.subjectName ?? 'Matière',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              slot.subjectCode ?? '',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSimpleDetailRow(Icons.access_time, '${slot.startTime} - ${slot.endTime}'),
                _buildSimpleDetailRow(Icons.room, slot.room ?? 'Salle non définie'),
                _buildSimpleDetailRow(Icons.person, slot.teacherName ?? 'Prof non défini'),
                _buildSimpleDetailRow(Icons.label, slot.sessionType),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
