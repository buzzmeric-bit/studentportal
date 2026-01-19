import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/payments_provider.dart';
import '../../widgets/admin_sidebar.dart';

/// Modern Payment Management Screen
/// Full control over student payments with comprehensive filtering and actions
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with TickerProviderStateMixin {
  late TabController _viewTabController;
  final _searchController = TextEditingController();
  bool _showFilters = true;
  Set<String> _selectedPayments = {};

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/payments'),
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text('Erreur: $e', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(paymentsProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (state) => Column(
                children: [
                  _buildTopBar(context, state),
                  Expanded(
                    child: Row(
                      children: [
                        // Left Panel - Filters
                        if (_showFilters) _buildLeftPanel(context, state),
                        
                        // Main Content
                        Expanded(
                          child: _buildMainContent(context, state),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(BuildContext context, PaymentsState state) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Toggle filters
          IconButton(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(_showFilters ? Icons.menu_open : Icons.menu),
            tooltip: _showFilters ? 'Masquer les filtres' : 'Afficher les filtres',
          ),
          
          const SizedBox(width: 16),
          
          // Title & subtitle
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestion des Paiements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${state.payments.length} paiements • ${state.studentSummaries.length} étudiants',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Search bar
          Container(
            width: 300,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un élève, classe, référence...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(paymentsProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => ref.read(paymentsProvider.notifier).setSearchQuery(v),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Bulk actions (when selected)
          if (_selectedPayments.isNotEmpty) ...[
            FilledButton.icon(
              onPressed: () => _showBulkMarkPaidDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text('Marquer ${_selectedPayments.length} payé(s)'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _selectedPayments.clear()),
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 8),
          ],
          
          // Refresh button
          IconButton(
            onPressed: () => ref.read(paymentsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Export button
          PopupMenuButton<String>(
            onSelected: (value) => _handleExport(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('Exporter en PDF')),
              const PopupMenuItem(value: 'excel', child: Text('Exporter en Excel')),
              const PopupMenuItem(value: 'print', child: Text('Imprimer')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text('Exporter', style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEFT PANEL - FILTERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLeftPanel(BuildContext context, PaymentsState state) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatsSection(state),
          ),
          
          const Divider(height: 1),
          
          // Filters
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Filtres'),
                  const SizedBox(height: 16),
                  
                  // Status Filter
                  _buildStatusFilter(state),
                  
                  const SizedBox(height: 16),
                  
                  // Class Filter
                  _buildClassFilter(state),
                  
                  const SizedBox(height: 16),
                  
                  // Category Filter
                  _buildCategoryFilter(state),
                  
                  const SizedBox(height: 16),
                  
                  // Date Range Filter
                  _buildDateRangeFilter(state),
                  
                  const SizedBox(height: 24),
                  
                  // Clear Filters Button
                  if (_hasActiveFilters(state))
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(paymentsProvider.notifier).clearFilters();
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Réinitialiser les filtres'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(PaymentsState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'Total Dû',
              '${state.totalDue.toStringAsFixed(0)} TND',
              Icons.account_balance_wallet,
              const Color(0xFF6366F1),
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(
              'Collecté',
              '${state.totalCollected.toStringAsFixed(0)} TND',
              Icons.check_circle,
              const Color(0xFF10B981),
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'En attente',
              '${state.totalPending.toStringAsFixed(0)} TND',
              Icons.schedule,
              const Color(0xFFF59E0B),
            )),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(
              'En retard',
              '${state.totalOverdue.toStringAsFixed(0)} TND',
              Icons.warning,
              const Color(0xFFEF4444),
              badge: state.overdueCount > 0 ? '${state.overdueCount}' : null,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {String? badge}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildStatusFilter(PaymentsState state) {
    final statuses = [
      ('all', 'Tous', null, const Color(0xFF64748B)),
      ('paid', 'Payés', Icons.check_circle, const Color(0xFF10B981)),
      ('pending', 'En attente', Icons.schedule, const Color(0xFFF59E0B)),
      ('overdue', 'En retard', Icons.warning, const Color(0xFFEF4444)),
      ('cancelled', 'Annulés', Icons.cancel, const Color(0xFF64748B)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((s) {
        final isSelected = state.statusFilter == s.$1;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.$3 != null) ...[
                Icon(s.$3, size: 14, color: isSelected ? Colors.white : s.$4),
                const SizedBox(width: 4),
              ],
              Text(s.$2),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => ref.read(paymentsProvider.notifier).setStatusFilter(s.$1),
          selectedColor: s.$4,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
          ),
          backgroundColor: const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }

  Widget _buildClassFilter(PaymentsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classe',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonFormField<String?>(
            value: state.classFilter,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
              isDense: true,
            ),
            hint: const Text('Toutes les classes', style: TextStyle(fontSize: 13)),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Toutes les classes')),
              if (state.classes.isNotEmpty)
                ...state.classes.map((c) => DropdownMenuItem<String?>(
                  value: c['id']?.toString(),
                  child: Text(c['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                )),
              // Demo classes if no real data
              if (state.classes.isEmpty) ...[
                const DropdownMenuItem<String?>(value: 'c1', child: Text('4ème Année A')),
                const DropdownMenuItem<String?>(value: 'c2', child: Text('3ème Année B')),
                const DropdownMenuItem<String?>(value: 'c3', child: Text('2ème Année A')),
              ],
            ],
            onChanged: (v) => ref.read(paymentsProvider.notifier).setClassFilter(v),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(PaymentsState state) {
    final categories = PaymentCategory.values;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catégorie',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonFormField<String?>(
            value: state.categoryFilter,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
              isDense: true,
            ),
            hint: const Text('Toutes les catégories', style: TextStyle(fontSize: 13)),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Toutes les catégories')),
              ...categories.map((c) => DropdownMenuItem<String?>(
                value: c.label,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(c.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(c.label, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
            ],
            onChanged: (v) => ref.read(paymentsProvider.notifier).setCategoryFilter(v),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(PaymentsState state) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Période d\'échéance',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true, state),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.dateFromFilter != null 
                              ? dateFormat.format(state.dateFromFilter!)
                              : 'Du...',
                          style: TextStyle(
                            fontSize: 12,
                            color: state.dateFromFilter != null ? Colors.black : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      if (state.dateFromFilter != null)
                        GestureDetector(
                          onTap: () => ref.read(paymentsProvider.notifier).setDateFromFilter(null),
                          child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false, state),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.dateToFilter != null 
                              ? dateFormat.format(state.dateToFilter!)
                              : 'Au...',
                          style: TextStyle(
                            fontSize: 12,
                            color: state.dateToFilter != null ? Colors.black : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      if (state.dateToFilter != null)
                        GestureDetector(
                          onTap: () => ref.read(paymentsProvider.notifier).setDateToFilter(null),
                          child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _hasActiveFilters(PaymentsState state) {
    return state.statusFilter != 'all' ||
           state.classFilter != null ||
           state.categoryFilter != null ||
           state.dateFromFilter != null ||
           state.dateToFilter != null ||
           state.searchQuery.isNotEmpty;
  }

  Future<void> _selectDate(BuildContext context, bool isFrom, PaymentsState state) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (state.dateFromFilter ?? DateTime.now()) : (state.dateToFilter ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      if (isFrom) {
        ref.read(paymentsProvider.notifier).setDateFromFilter(picked);
      } else {
        ref.read(paymentsProvider.notifier).setDateToFilter(picked);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMainContent(BuildContext context, PaymentsState state) {
    return Column(
      children: [
        // View Tabs
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              TabBar(
                controller: _viewTabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF10B981),
                labelColor: const Color(0xFF10B981),
                unselectedLabelColor: Colors.grey.shade600,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: '📋 Liste des Paiements'),
                  Tab(text: '👥 Par Étudiant'),
                  Tab(text: '📊 Statistiques'),
                ],
              ),
              const Spacer(),
              // Select all checkbox (for payments view)
              if (_viewTabController.index == 0 && state.filtered.isNotEmpty)
                Row(
                  children: [
                    Checkbox(
                      value: _selectedPayments.length == state.filtered.where((p) => p.status != PaymentStatus.paid).length,
                      tristate: true,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedPayments = state.filtered
                                .where((p) => p.status != PaymentStatus.paid)
                                .map((p) => p.id)
                                .toSet();
                          } else {
                            _selectedPayments.clear();
                          }
                        });
                      },
                    ),
                    Text(
                      'Tout sélectionner',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Content
        Expanded(
          child: TabBarView(
            controller: _viewTabController,
            children: [
              _buildPaymentsList(context, state),
              _buildStudentsList(context, state),
              _buildStatisticsView(context, state),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENTS LIST VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentsList(BuildContext context, PaymentsState state) {
    final payments = state.filtered;
    
    if (payments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.payments_outlined,
        title: 'Aucun paiement trouvé',
        subtitle: 'Modifiez vos filtres ou ajoutez des paiements',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentCard(context, payment);
      },
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isOverdue = payment.isOverdue;
    final statusColor = isOverdue 
        ? const Color(0xFFEF4444)
        : Color(payment.status.colorValue);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedPayments.contains(payment.id) 
              ? const Color(0xFF10B981)
              : const Color(0xFFE2E8F0),
          width: _selectedPayments.contains(payment.id) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPaymentDetails(context, payment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox (if not paid)
                if (payment.status != PaymentStatus.paid)
                  Checkbox(
                    value: _selectedPayments.contains(payment.id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedPayments.add(payment.id);
                        } else {
                          _selectedPayments.remove(payment.id);
                        }
                      });
                    },
                    activeColor: const Color(0xFF10B981),
                  )
                else
                  const SizedBox(width: 48),
                
                // Status indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    payment.status == PaymentStatus.paid 
                        ? Icons.check_circle
                        : (isOverdue ? Icons.warning : Icons.schedule),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Payment info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            payment.studentName ?? 'Étudiant inconnu',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOverdue ? 'En retard' : payment.status.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.class_, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            payment.className ?? '-',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.category, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            payment.category ?? 'Non catégorisé',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.event, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Échéance: ${dateFormat.format(payment.dueDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue ? const Color(0xFFEF4444) : Colors.grey.shade600,
                              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (payment.paidAt != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.check, size: 14, color: Colors.green.shade500),
                            const SizedBox(width: 4),
                            Text(
                              'Payé le ${dateFormat.format(payment.paidAt!)}',
                              style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${payment.amount.toStringAsFixed(0)} TND',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (payment.reference != null)
                      Text(
                        payment.reference!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePaymentAction(context, value, payment),
                  itemBuilder: (context) => [
                    if (payment.status != PaymentStatus.paid)
                      const PopupMenuItem(
                        value: 'mark_paid',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                            SizedBox(width: 8),
                            Text('Marquer comme payé'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Color(0xFF3B82F6), size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Color(0xFF64748B), size: 18),
                          SizedBox(width: 8),
                          Text('Voir les détails'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    if (payment.status != PaymentStatus.cancelled)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Color(0xFFEF4444), size: 18),
                            SizedBox(width: 8),
                            Text('Annuler'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Color(0xFFEF4444), size: 18),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STUDENTS LIST VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStudentsList(BuildContext context, PaymentsState state) {
    final students = state.filteredStudents;
    
    if (students.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'Aucun étudiant trouvé',
        subtitle: 'Modifiez vos filtres pour voir les étudiants',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentCard(context, student);
      },
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentPaymentSummary student) {
    final progress = student.progressPercent;
    final progressColor = progress >= 100 
        ? const Color(0xFF10B981)
        : (progress >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showStudentPaymentDetails(context, student),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Progress circle
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: progress / 100,
                          backgroundColor: progressColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          strokeWidth: 6,
                        ),
                      ),
                      Text(
                        '${progress.toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            student.studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (student.overduePayments > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning, size: 12, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${student.overduePayments} en retard',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.className ?? 'Classe non assignée',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildProgressLabel('Total', '${student.totalAmount.toStringAsFixed(0)} TND', Colors.grey.shade700),
                          const SizedBox(width: 20),
                          _buildProgressLabel('Payé', '${student.paidAmount.toStringAsFixed(0)} TND', const Color(0xFF10B981)),
                          const SizedBox(width: 20),
                          _buildProgressLabel('Reste', '${student.pendingAmount.toStringAsFixed(0)} TND', const Color(0xFFF59E0B)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Payment counts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          '${student.paidPayments}/${student.totalPayments}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'paiements effectués',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLabel(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATISTICS VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatisticsView(BuildContext context, PaymentsState state) {
    final collectionRate = state.totalDue > 0 
        ? (state.totalCollected / state.totalDue * 100)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          Row(
            children: [
              Expanded(child: _buildOverviewCard(
                'Taux de Recouvrement',
                '${collectionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                const Color(0xFF10B981),
                subtitle: '${state.totalCollected.toStringAsFixed(0)} / ${state.totalDue.toStringAsFixed(0)} TND',
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildOverviewCard(
                'Paiements en Retard',
                '${state.overdueCount}',
                Icons.warning,
                const Color(0xFFEF4444),
                subtitle: '${state.totalOverdue.toStringAsFixed(0)} TND impayés',
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildOverviewCard(
                'Étudiants à Jour',
                '${state.studentSummaries.where((s) => s.overduePayments == 0).length}',
                Icons.check_circle,
                const Color(0xFF10B981),
                subtitle: 'sur ${state.studentSummaries.length} étudiants',
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildOverviewCard(
                'À Percevoir',
                '${state.totalPending.toStringAsFixed(0)} TND',
                Icons.schedule,
                const Color(0xFFF59E0B),
                subtitle: 'paiements en attente',
              )),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Charts row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment status distribution
              Expanded(
                flex: 1,
                child: _buildChartCard(
                  'Répartition par Statut',
                  _buildStatusPieChart(state),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Category breakdown
              Expanded(
                flex: 2,
                child: _buildChartCard(
                  'Paiements par Catégorie',
                  _buildCategoryBreakdown(state),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Top debtors
          _buildChartCard(
            'Étudiants avec Paiements en Retard',
            _buildDebtorsList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusPieChart(PaymentsState state) {
    final paid = state.payments.where((p) => p.status == PaymentStatus.paid).length;
    final pending = state.payments.where((p) => p.status == PaymentStatus.pending && !p.isOverdue).length;
    final overdue = state.payments.where((p) => p.isOverdue).length;
    final cancelled = state.payments.where((p) => p.status == PaymentStatus.cancelled).length;
    final total = state.payments.length;

    if (total == 0) {
      return const Center(child: Text('Aucune donnée'));
    }

    return Row(
      children: [
        // Simple pie representation
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _SimplePieChartPainter(
              segments: [
                (paid / total, const Color(0xFF10B981)),
                (pending / total, const Color(0xFFF59E0B)),
                (overdue / total, const Color(0xFFEF4444)),
                (cancelled / total, const Color(0xFF64748B)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildLegendItem('Payés', paid, const Color(0xFF10B981)),
              _buildLegendItem('En attente', pending, const Color(0xFFF59E0B)),
              _buildLegendItem('En retard', overdue, const Color(0xFFEF4444)),
              _buildLegendItem('Annulés', cancelled, const Color(0xFF64748B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
          Text(
            '$count',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(PaymentsState state) {
    final categoryTotals = <String, double>{};
    for (final p in state.payments) {
      final cat = p.category ?? 'Autres';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + p.amount;
    }

    if (categoryTotals.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxAmount = sortedCategories.first.value;

    return Column(
      children: sortedCategories.map((entry) {
        final categoryEnum = PaymentCategory.values.cast<PaymentCategory?>().firstWhere(
          (c) => c?.label == entry.key,
          orElse: () => PaymentCategory.autres,
        )!;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(categoryEnum.colorValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(categoryEnum),
                  size: 16,
                  color: Color(categoryEnum.colorValue),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: entry.value / maxAmount,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(categoryEnum.colorValue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  '${entry.value.toStringAsFixed(0)} TND',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(PaymentCategory category) {
    switch (category) {
      case PaymentCategory.scolarite: return Icons.school;
      case PaymentCategory.transport: return Icons.directions_bus;
      case PaymentCategory.inscription: return Icons.app_registration;
      case PaymentCategory.uniforme: return Icons.checkroom;
      case PaymentCategory.cantine: return Icons.restaurant;
      case PaymentCategory.activites: return Icons.sports_soccer;
      case PaymentCategory.autres: return Icons.more_horiz;
    }
  }

  Widget _buildDebtorsList(PaymentsState state) {
    final debtors = state.studentSummaries
        .where((s) => s.overduePayments > 0)
        .toList()
      ..sort((a, b) => b.pendingAmount.compareTo(a.pendingAmount));

    if (debtors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade400, size: 24),
            const SizedBox(width: 8),
            Text(
              'Aucun paiement en retard ! 🎉',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: debtors.take(5).map((student) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEF4444).withOpacity(0.2),
              child: Text(
                student.studentName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    student.className ?? '-',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${student.pendingAmount.toStringAsFixed(0)} TND',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFFEF4444),
                  ),
                ),
                Text(
                  '${student.overduePayments} en retard',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.email_outlined, size: 20),
              color: const Color(0xFF64748B),
              onPressed: () => _sendReminder(student),
              tooltip: 'Envoyer un rappel',
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGS & ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _handlePaymentAction(BuildContext context, String action, Payment payment) {
    switch (action) {
      case 'mark_paid':
        _showMarkPaidDialog(context, payment);
        break;
      case 'edit':
        _showEditPaymentDialog(context, payment);
        break;
      case 'view':
        _showPaymentDetails(context, payment);
        break;
      case 'cancel':
        _confirmCancelPayment(context, payment);
        break;
      case 'delete':
        _confirmDeletePayment(context, payment);
        break;
    }
  }

  void _showMarkPaidDialog(BuildContext context, Payment payment) {
    String? selectedMethod;
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer comme payé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant: ${payment.amount.toStringAsFixed(0)} TND'),
            Text('Étudiant: ${payment.studentName ?? "-"}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Mode de paiement',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Virement bancaire')),
                DropdownMenuItem(value: 'card', child: Text('Carte bancaire')),
                DropdownMenuItem(value: 'check', child: Text('Chèque')),
              ],
              onChanged: (v) => selectedMethod = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence / Reçu (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(paymentsProvider.notifier).markAsPaid(
                payment.id,
                method: selectedMethod,
                reference: referenceController.text.isNotEmpty ? referenceController.text : null,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paiement marqué comme payé'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showBulkMarkPaidDialog(BuildContext context) {
    String? selectedMethod;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer les paiements comme payés'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_selectedPayments.length} paiements sélectionnés'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Mode de paiement',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Virement bancaire')),
                DropdownMenuItem(value: 'card', child: Text('Carte bancaire')),
                DropdownMenuItem(value: 'check', child: Text('Chèque')),
              ],
              onChanged: (v) => selectedMethod = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(paymentsProvider.notifier).bulkMarkAsPaid(
                _selectedPayments.toList(),
                method: selectedMethod,
              );
              setState(() => _selectedPayments.clear());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paiements marqués comme payés'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showEditPaymentDialog(BuildContext context, Payment payment) {
    final amountController = TextEditingController(text: payment.amount.toString());
    final notesController = TextEditingController(text: payment.notes ?? '');
    DateTime selectedDate = payment.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le paiement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (TND)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date d\'échéance',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(paymentsProvider.notifier).updatePayment(
                  id: payment.id,
                  amount: double.tryParse(amountController.text),
                  dueDate: selectedDate,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paiement modifié')),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, Payment payment) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              payment.status == PaymentStatus.paid ? Icons.check_circle : Icons.schedule,
              color: Color(payment.status.colorValue),
            ),
            const SizedBox(width: 8),
            const Text('Détails du Paiement'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Montant', '${payment.amount.toStringAsFixed(0)} TND'),
              _buildDetailRow('Statut', payment.status.label),
              _buildDetailRow('Étudiant', payment.studentName ?? '-'),
              _buildDetailRow('Classe', payment.className ?? '-'),
              _buildDetailRow('Catégorie', payment.category ?? '-'),
              _buildDetailRow('Échéance', DateFormat('dd/MM/yyyy').format(payment.dueDate)),
              if (payment.paidAt != null)
                _buildDetailRow('Payé le', dateFormat.format(payment.paidAt!)),
              if (payment.method != null)
                _buildDetailRow('Mode', payment.method!),
              if (payment.reference != null)
                _buildDetailRow('Référence', payment.reference!),
              if (payment.notes != null && payment.notes!.isNotEmpty)
                _buildDetailRow('Notes', payment.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelPayment(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le paiement ?'),
        content: Text('Voulez-vous annuler le paiement de ${payment.amount.toStringAsFixed(0)} TND ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(paymentsProvider.notifier).cancelPayment(payment.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paiement annulé')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le paiement ?'),
        content: Text('Cette action est irréversible. Supprimer le paiement de ${payment.amount.toStringAsFixed(0)} TND ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(paymentsProvider.notifier).deletePayment(payment.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paiement supprimé'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showStudentPaymentDetails(BuildContext context, StudentPaymentSummary student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.studentName),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Classe', student.className ?? '-'),
              _buildDetailRow('Total', '${student.totalAmount.toStringAsFixed(0)} TND'),
              _buildDetailRow('Payé', '${student.paidAmount.toStringAsFixed(0)} TND'),
              _buildDetailRow('Reste', '${student.pendingAmount.toStringAsFixed(0)} TND'),
              _buildDetailRow('Paiements', '${student.paidPayments}/${student.totalPayments}'),
              if (student.overduePayments > 0)
                _buildDetailRow('En retard', '${student.overduePayments} paiement(s)'),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: student.progressPercent / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  student.progressPercent >= 100 
                      ? const Color(0xFF10B981)
                      : (student.progressPercent >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${student.progressPercent.toStringAsFixed(0)}% complété',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (student.overduePayments > 0)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _sendReminder(student);
              },
              child: const Text('Envoyer un rappel'),
            ),
        ],
      ),
    );
  }

  void _sendReminder(StudentPaymentSummary student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rappel envoyé à ${student.studentName}'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  void _handleExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export $format en cours...'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIMPLE PIE CHART PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _SimplePieChartPainter extends CustomPainter {
  final List<(double, Color)> segments;

  _SimplePieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    double startAngle = -math.pi / 2;
    
    for (final segment in segments) {
      if (segment.$1 <= 0) continue;
      
      final sweepAngle = segment.$1 * 2 * math.pi;
      final paint = Paint()
        ..color = segment.$2
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Draw center hole for donut effect
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
