import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/timetable_provider.dart';
import '../../widgets/admin_sidebar.dart';

class TimetablesScreen extends ConsumerWidget {
  const TimetablesScreen({super.key});

  static const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(timetableProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/timetables'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(child: timetableAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                  data: (state) => _buildContent(context, ref, state),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Row(
        children: [
          Text('Emplois du temps', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, TimetableState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: state.slots.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.schedule, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Aucun emploi du temps', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Configurez dabord les offres de matieres', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(6, (dayIndex) {
                  final daySlots = state.slots.where((s) => s.dayOfWeek == dayIndex + 1).toList();
                  if (daySlots.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(days[dayIndex], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: daySlots.map((slot) => Container(
                          width: 200,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.subjectName ?? 'Matiere', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${slot.startTime} - ${slot.endTime}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              if (slot.className != null) Text(slot.className!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              if (slot.room != null) Text('Salle: ${slot.room}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }),
              ),
            ),
      ),
    );
  }
}