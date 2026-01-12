import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/payment_model.dart';

// Demo payment plan and payments provider
final paymentDataProvider = FutureProvider<PaymentPlanModel>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  return PaymentPlanModel(
    id: 'plan1',
    enrollmentId: 'enroll1',
    planType: 'semester',
    amountTotal: 85000,
    currency: 'DZD',
    description: 'Frais de scolarité 2024-2025',
    createdAt: DateTime(2024, 9, 1),
    payments: [
      PaymentModel(
        id: 'pay1',
        paymentPlanId: 'plan1',
        amount: 28333,
        dueDate: DateTime(2024, 10, 1),
        paidAt: DateTime(2024, 9, 25),
        method: 'cash',
        status: 'paid',
        reference: 'REC-2024-001',
        createdAt: DateTime(2024, 9, 25),
      ),
      PaymentModel(
        id: 'pay2',
        paymentPlanId: 'plan1',
        amount: 28333,
        dueDate: DateTime(2024, 12, 1),
        paidAt: DateTime(2024, 11, 28),
        method: 'bank_transfer',
        status: 'paid',
        reference: 'REC-2024-002',
        createdAt: DateTime(2024, 11, 28),
      ),
      PaymentModel(
        id: 'pay3',
        paymentPlanId: 'plan1',
        amount: 28334,
        dueDate: DateTime(2025, 2, 1),
        status: 'pending',
        createdAt: DateTime(2024, 9, 1),
      ),
    ],
  );
});

class MonSoldeScreen extends ConsumerWidget {
  const MonSoldeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final paymentDataAsync = ref.watch(paymentDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.monSolde),
        backgroundColor: AppColors.tileMonSolde,
        foregroundColor: Colors.white,
      ),
      body: paymentDataAsync.when(
        data: (paymentPlan) {
          final paidAmount = paymentPlan.paidAmount;
          final totalAmount = paymentPlan.amountTotal;
          final remainingAmount = paymentPlan.remainingAmount;
          final progressPercent = paymentPlan.progressPercent;

          return ListView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            children: [
              // Balance overview card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.tileMonSolde,
                        AppColors.tileMonSolde.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.remainingBalance,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingS),
                      Text(
                        _formatCurrency(remainingAmount, paymentPlan.currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingL),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100,
                          minHeight: 10,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n.paid}: ${_formatCurrency(paidAmount, paymentPlan.currency)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${l10n.total}: ${_formatCurrency(totalAmount, paymentPlan.currency)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              // Plan info
              if (paymentPlan.description != null) ...[
                _InfoCard(
                  icon: Icons.info_outline,
                  title: l10n.paymentPlan,
                  subtitle: paymentPlan.description!,
                ),
                const SizedBox(height: AppSizes.paddingM),
              ],
              // Payment schedule section
              Text(
                l10n.paymentSchedule,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              if (paymentPlan.payments != null)
                ...paymentPlan.payments!.map((payment) => _PaymentCard(
                      payment: payment,
                      currency: paymentPlan.currency,
                    )),
              const SizedBox(height: AppSizes.paddingL),
              // Payment history section
              Text(
                l10n.paymentHistory,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingM),
              if (paymentPlan.payments != null)
                ...paymentPlan.payments!
                    .where((p) => p.status == 'paid')
                    .map((payment) => _PaymentHistoryCard(
                          payment: payment,
                          currency: paymentPlan.currency,
                        )),
              if (paymentPlan.payments?.where((p) => p.status == 'paid').isEmpty ?? true)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingL),
                    child: Text(
                      l10n.noPayments,
                      style: TextStyle(color: AppColors.textLight),
                    ),
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
                onPressed: () => ref.refresh(paymentDataProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} $currency';
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.paddingS),
          decoration: BoxDecoration(
            color: AppColors.tileMonSolde.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Icon(icon, color: AppColors.tileMonSolde),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final String currency;

  const _PaymentCard({
    required this.payment,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isPaid = payment.status == 'paid';
    final isOverdue = !isPaid && 
        payment.dueDate != null && 
        payment.dueDate!.isBefore(DateTime.now());

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPaid) {
      statusColor = AppColors.success;
      statusText = l10n.statusPaid;
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = AppColors.error;
      statusText = l10n.statusOverdue;
      statusIcon = Icons.warning;
    } else {
      statusColor = AppColors.warning;
      statusText = l10n.statusPending;
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.installment,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (payment.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.dueDate}: ${dateFormat.format(payment.dueDate!)}',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(payment.amount, currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} $currency';
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final PaymentModel payment;
  final String currency;

  const _PaymentHistoryCard({
    required this.payment,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    IconData methodIcon;
    switch (payment.method) {
      case 'cash':
        methodIcon = Icons.money;
        break;
      case 'bank_transfer':
        methodIcon = Icons.account_balance;
        break;
      case 'card':
        methodIcon = Icons.credit_card;
        break;
      case 'check':
        methodIcon = Icons.receipt_long;
        break;
      default:
        methodIcon = Icons.payment;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Icon(methodIcon, color: AppColors.success, size: 20),
        ),
        title: Text(
          _formatCurrency(payment.amount, currency),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payment.paidAt != null)
              Text(
                dateFormat.format(payment.paidAt!),
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
            if (payment.reference != null)
              Text(
                payment.reference!,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Text(
          payment.displayMethod,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} $currency';
  }
}
