import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/admin_sidebar.dart';
import '../../../data/models/dashboard_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/dashboard'),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, ref, authState),
                Expanded(
                  child: dashboardAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (state) => _buildDashboardContent(context, ref, state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, AdminAuthState authState) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            child: Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  authState.user?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(authState.user?.fullName ?? 'Admin'),
              const Icon(Icons.arrow_drop_down),
            ]),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.red))])),
            ],
            onSelected: (value) { if (value == 'logout') ref.read(authProvider.notifier).signOut(); },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref, DashboardState state) {
    final kpis = state.kpis;
    final currencyFormat = NumberFormat.currency(locale: 'fr_DZ', symbol: 'DZD ', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vue d\'ensemble', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Bienvenue sur votre tableau de bord administratif', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _KpiCard(title: 'Etudiants', value: kpis.totalStudents.toString(), icon: Icons.school, color: Colors.blue, subtitle: 'Inscrits')),
              const SizedBox(width: 16),
              Expanded(child: _KpiCard(title: 'Enseignants', value: kpis.totalTeachers.toString(), icon: Icons.person, color: Colors.green, subtitle: 'Actifs')),
              const SizedBox(width: 16),
              Expanded(child: _KpiCard(title: 'Classes', value: kpis.totalClasses.toString(), icon: Icons.class_, color: Colors.orange, subtitle: 'Total')),
              const SizedBox(width: 16),
              Expanded(child: _KpiCard(title: 'A risque', value: state.atRiskStudents.length.toString(), icon: Icons.warning, color: Colors.red, subtitle: 'Etudiants')),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _KpiCard(title: 'Paiements dus', value: currencyFormat.format(kpis.totalPaymentsDue), icon: Icons.account_balance_wallet, color: Colors.purple, subtitle: 'Total')),
              const SizedBox(width: 16),
              Expanded(child: _KpiCard(title: 'Encaisses', value: currencyFormat.format(kpis.totalPaymentsCollected), icon: Icons.check_circle, color: Colors.teal, subtitle: '${kpis.paymentProgress.toStringAsFixed(1)}%')),
              const SizedBox(width: 16),
              Expanded(child: _KpiCard(title: 'Restant', value: currencyFormat.format(kpis.outstandingPayments), icon: Icons.pending, color: Colors.amber, subtitle: 'A recouvrer')),
              const SizedBox(width: 16),
              Expanded(child: _KpiCard(title: 'Suggestions', value: kpis.openSuggestions.toString(), icon: Icons.message, color: Colors.indigo, subtitle: 'Ouvertes')),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildAbsenceChart(context)),
              const SizedBox(width: 16),
              Expanded(child: _buildPaymentDonut(context, kpis)),
            ],
          ),
          const SizedBox(height: 24),

          _buildAtRiskTable(context, state.atRiskStudents),
        ],
      ),
    );
  }

  Widget _buildAbsenceChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tendance des absences', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Heures d\'absence par semaine', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[200]!, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text('${v.toInt()}h', style: TextStyle(fontSize: 10, color: Colors.grey[600])))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text('S${v.toInt() + 1}', style: TextStyle(fontSize: 10, color: Colors.grey[600])))),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 12), FlSpot(1, 18), FlSpot(2, 15), FlSpot(3, 22), FlSpot(4, 19), FlSpot(5, 14), FlSpot(6, 16)],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDonut(BuildContext context, DashboardKpis kpis) {
    final collected = kpis.totalPaymentsCollected;
    final remaining = kpis.outstandingPayments;
    final total = collected + remaining;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recouvrement', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Progression des paiements', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: total > 0
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(value: collected, color: Colors.green, title: '${(collected / total * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), radius: 50),
                        PieChartSectionData(value: remaining, color: Colors.red.shade300, title: '${(remaining / total * 100).toStringAsFixed(0)}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), radius: 50),
                      ],
                    ),
                  )
                : const Center(child: Text('Aucune donnee')),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: Colors.green, label: 'Paye'),
              const SizedBox(width: 16),
              _LegendItem(color: Colors.red.shade300, label: 'Restant'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAtRiskTable(BuildContext context, List<AtRiskStudent> students) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Etudiants a risque', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Voir tout')),
            ],
          ),
          const SizedBox(height: 16),
          students.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aucun etudiant a risque', style: TextStyle(color: Colors.grey))))
              : DataTable(
                  columns: const [
                    DataColumn(label: Text('Etudiant', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Classe', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Matiere', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Absences', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: students.map((s) => DataRow(cells: [
                    DataCell(Text(s.studentName)),
                    DataCell(Text(s.className)),
                    DataCell(Text(s.subjectName)),
                    DataCell(Text('${s.absencePercent.toStringAsFixed(1)}%')),
                    DataCell(_StatusChip(status: s.status)),
                  ])).toList(),
                ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _KpiCard({required this.title, required this.value, required this.icon, required this.color, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'warning':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Attention';
        break;
      case 'critical':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Critique';
        break;
      case 'elimination':
        bgColor = Colors.red.shade200;
        textColor = Colors.red.shade900;
        label = 'Elimine';
        break;
      default:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'OK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}