import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/payments_provider.dart';
import '../../widgets/admin_sidebar.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/payments'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(child: paymentsAsync.when(
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
          Text('Paiements', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PaymentsState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: state.statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tous')),
                      DropdownMenuItem(value: 'pending', child: Text('En attente')),
                      DropdownMenuItem(value: 'paid', child: Text('Paye')),
                      DropdownMenuItem(value: 'overdue', child: Text('En retard')),
                    ],
                    onChanged: (v) => ref.read(paymentsProvider.notifier).setStatusFilter(v!),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.filtered.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.payment, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Aucun paiement', style: TextStyle(color: Colors.grey[600])),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.filtered.length,
                    itemBuilder: (context, index) {
                      final p = state.filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: p.status == 'paid' ? Colors.green.shade100 : (p.status == 'overdue' ? Colors.red.shade100 : Colors.orange.shade100),
                            child: Icon(Icons.payment, color: p.status == 'paid' ? Colors.green : (p.status == 'overdue' ? Colors.red : Colors.orange)),
                          ),
                          title: Text('${p.amount.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(p.studentName ?? 'Etudiant inconnu'),
                              Text('Classe: ${p.className ?? "-"}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              Text('Echeance: ${DateFormat('dd/MM/yyyy').format(p.dueDate)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                          trailing: p.status == 'paid'
                            ? const Chip(label: Text('Paye', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
                            : ElevatedButton(
                                onPressed: () => ref.read(paymentsProvider.notifier).markAsPaid(p.id),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Marquer paye', style: TextStyle(color: Colors.white)),
                              ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}