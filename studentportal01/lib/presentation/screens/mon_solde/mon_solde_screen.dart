import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/student_context_provider.dart';
import '../../widgets/semester_navigator.dart';

// Semester state provider for this screen
final soldeSemesterProvider = StateProvider<int>((ref) => 1);

// Payment categories for Tunisia
enum PaymentCategory {
  scolarite('Scolarité', Icons.school_rounded, Color(0xFF6366F1)),
  transport('Transport/Bus', Icons.directions_bus_rounded, Color(0xFFF59E0B)),
  inscription('Inscription', Icons.app_registration_rounded, Color(0xFF10B981)),
  uniforme('Uniforme', Icons.checkroom_rounded, Color(0xFFEC4899)),
  cantine('Cantine', Icons.restaurant_rounded, Color(0xFF8B5CF6)),
  activites('Activités', Icons.sports_soccer_rounded, Color(0xFF06B6D4)),
  autres('Autres', Icons.more_horiz_rounded, Color(0xFF64748B));

  final String label;
  final IconData icon;
  final Color color;
  const PaymentCategory(this.label, this.icon, this.color);
}

// Payment breakdown by category
class PaymentCategoryData {
  final PaymentCategory category;
  final double amount;
  final double paid;

  PaymentCategoryData({
    required this.category,
    required this.amount,
    required this.paid,
  });

  double get remaining => amount - paid;
  double get progressPercent => amount > 0 ? (paid / amount) * 100 : 0;
}

// Demo payment plan with Tunisian Dinar
final paymentDataProvider = FutureProvider<PaymentPlanModel>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));

  return PaymentPlanModel(
    id: 'plan1',
    enrollmentId: 'enroll1',
    planType: 'semester',
    amountTotal: 2850,
    currency: 'TND',
    description: 'Frais de scolarité 2024-2025',
    createdAt: DateTime(2024, 9, 1),
    payments: [
      PaymentModel(
        id: 'pay1',
        paymentPlanId: 'plan1',
        amount: 950,
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
        amount: 950,
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
        amount: 950,
        dueDate: DateTime(2025, 2, 1),
        status: 'pending',
        createdAt: DateTime(2024, 9, 1),
      ),
    ],
  );
});

// Payment categories breakdown provider
final paymentCategoriesProvider = Provider<List<PaymentCategoryData>>((ref) {
  return [
    PaymentCategoryData(
      category: PaymentCategory.scolarite,
      amount: 1500,
      paid: 1000,
    ),
    PaymentCategoryData(
      category: PaymentCategory.transport,
      amount: 450,
      paid: 450,
    ),
    PaymentCategoryData(
      category: PaymentCategory.inscription,
      amount: 200,
      paid: 200,
    ),
    PaymentCategoryData(
      category: PaymentCategory.uniforme,
      amount: 350,
      paid: 250,
    ),
    PaymentCategoryData(
      category: PaymentCategory.cantine,
      amount: 250,
      paid: 0,
    ),
    PaymentCategoryData(
      category: PaymentCategory.activites,
      amount: 100,
      paid: 0,
    ),
  ];
});

class MonSoldeScreen extends ConsumerStatefulWidget {
  const MonSoldeScreen({super.key});

  @override
  ConsumerState<MonSoldeScreen> createState() => _MonSoldeScreenState();
}

class _MonSoldeScreenState extends ConsumerState<MonSoldeScreen>
    with TickerProviderStateMixin {
  late AnimationController _chartAnimationController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _counterController;
  late Animation<double> _chartAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _counterAnimation;

  int? _selectedSegmentIndex;
  int? _hoveredSegmentIndex;

  static const Color _accentColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();

    // Main chart animation
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Shimmer animation for premium effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    // Pulse animation for selected segment
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Counter animation
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _counterAnimation = CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    );

    _chartAnimationController.forward();
    _counterController.forward();
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paymentDataAsync = ref.watch(paymentDataProvider);
    final categories = ref.watch(paymentCategoriesProvider);
    final selectedSemester = ref.watch(soldeSemesterProvider);

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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: _buildHeader(l10n),
                ),
              ),
              
              // Semester Navigator
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: DynamicSemesterNav(
                    selectedSemesterNumber: selectedSemester,
                    onChanged: (v) => ref.read(soldeSemesterProvider.notifier).state = v,
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Content
              paymentDataAsync.when(
                data: (paymentPlan) =>
                    _buildContent(context, paymentPlan, categories, l10n),
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
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
              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.payment_rounded,
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
                l10n.monSolde,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Suivi des paiements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    PaymentPlanModel paymentPlan,
    List<PaymentCategoryData> categories,
    AppLocalizations l10n,
  ) {
    final paidAmount = paymentPlan.paidAmount;
    final totalAmount = paymentPlan.amountTotal;
    final remainingAmount = paymentPlan.remainingAmount;
    final progressPercent = paymentPlan.progressPercent;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Main Balance Card
          _buildBalanceCard(
            remainingAmount,
            paidAmount,
            totalAmount,
            progressPercent,
          ),
          const SizedBox(height: 28),

          // Categories Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: _accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Répartition par catégorie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Premium Animated Glassy Donut Chart
          _buildPremiumGlassyDonutChart(categories, remainingAmount),
          const SizedBox(height: 24),

          // Category Cards
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GlassyCategoryCard(category: cat),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Schedule Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.paymentSchedule,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (paymentPlan.payments != null)
            ...paymentPlan.payments!.map(
              (payment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GlassyPaymentCard(payment: payment, currency: 'TND'),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildBalanceCard(
    double remaining,
    double paid,
    double total,
    double progressPercent,
  ) {
    final isGood = progressPercent > 50;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isGood
                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                  : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    (isGood ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solde restant',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(remaining),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4, left: 6),
                              child: Text(
                                'TND',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(4),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: progressPercent / 100,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '${progressPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payé: ${_formatCurrency(paid)} TND',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Total: ${_formatCurrency(total)} TND',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumGlassyDonutChart(
    List<PaymentCategoryData> categories,
    double totalRemaining,
  ) {
    final total = categories.fold<double>(0, (sum, c) => sum + c.amount);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _chartAnimation,
        _shimmerAnimation,
        _pulseAnimation,
        _counterAnimation,
      ]),
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.85),
                    Colors.white.withValues(alpha: 0.65),
                    Colors.white.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 20,
                    offset: const Offset(-5, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Premium Donut Chart with center value
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Main donut chart
                        GestureDetector(
                          onTapUp: (details) =>
                              _handleChartTap(details, categories, total),
                          onLongPressStart: (details) => 
                              _handleChartTap(TapUpDetails(kind: PointerDeviceKind.touch, globalPosition: details.globalPosition, localPosition: details.localPosition), categories, total),
                          child: MouseRegion(
                            onHover: (event) =>
                                _handleChartHover(event, categories, total),
                            onExit: (_) =>
                                setState(() => _hoveredSegmentIndex = null),
                            child: SizedBox(
                              width: 220,
                              height: 220,
                              child: CustomPaint(
                                painter: _Premium3DDonutPainter(
                                  categories: categories,
                                  total: total,
                                  animationValue: _chartAnimation.value,
                                  shimmerValue: 0.0,
                                  pulseValue: 0.0,
                                  selectedIndex: _selectedSegmentIndex,
                                  hoveredIndex: _hoveredSegmentIndex,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Center glassy circle with animated counter
                        _buildCenterDisplay(totalRemaining),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bottom legend grid
                  _buildLegendGrid(categories, total),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleChartTap(
    TapUpDetails details,
    List<PaymentCategoryData> categories,
    double total,
  ) {
    final index = _getSegmentAtPosition(
      details.localPosition,
      categories,
      total,
    );
    setState(() {
      _selectedSegmentIndex = index == _selectedSegmentIndex ? null : index;
    });
  }

  void _handleChartHover(
    PointerHoverEvent event,
    List<PaymentCategoryData> categories,
    double total,
  ) {
    final index = _getSegmentAtPosition(event.localPosition, categories, total);
    if (index != _hoveredSegmentIndex) {
      setState(() => _hoveredSegmentIndex = index);
    }
  }

  int? _getSegmentAtPosition(
    Offset position,
    List<PaymentCategoryData> categories,
    double total,
  ) {
    final center = const Offset(110, 110);
    final distance = (position - center).distance;

    // Check if within donut ring
    if (distance < 45 || distance > 95) return null;

    final angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    var normalizedAngle = angle + math.pi / 2;
    if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;

    double startAngle = 0;
    for (int i = 0; i < categories.length; i++) {
      final sweepAngle = (categories[i].amount / total) * 2 * math.pi;
      if (normalizedAngle >= startAngle &&
          normalizedAngle < startAngle + sweepAngle) {
        return i;
      }
      startAngle += sweepAngle;
    }
    return null;
  }

  Widget _buildCenterDisplay(double totalRemaining) {
    final animatedValue = totalRemaining * _counterAnimation.value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(60),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.85),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Reste',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(animatedValue),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                  height: 1.1,
                ),
              ),
              Text(
                'TND',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendGrid(List<PaymentCategoryData> categories, double total) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: categories.map((cat) {
        final percent = total > 0 ? (cat.amount / total * 100) : 0.0;
        final index = categories.indexOf(cat);
        final isSelected = _selectedSegmentIndex == index;

        return GestureDetector(
          onTap: () => setState(() {
            _selectedSegmentIndex = isSelected ? null : index;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.category.color.withValues(alpha: 0.15)
                  : Colors.grey.shade100.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? cat.category.color.withValues(alpha: 0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cat.category.color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: cat.category.color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  cat.category.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? cat.category.color
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? cat.category.color
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return formatter.format(amount);
  }
}

// Premium 3D Donut Chart Painter with glassmorphism effects
class _Premium3DDonutPainter extends CustomPainter {
  final List<PaymentCategoryData> categories;
  final double total;
  final double animationValue;
  final double shimmerValue;
  final double pulseValue;
  final int? selectedIndex;
  final int? hoveredIndex;

  _Premium3DDonutPainter({
    required this.categories,
    required this.total,
    required this.animationValue,
    required this.shimmerValue,
    required this.pulseValue,
    this.selectedIndex,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 15;
    final innerRadius = outerRadius * 0.52;

    // Draw shadow base for 3D effect
    _drawShadowBase(canvas, center, outerRadius, innerRadius);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final sweepAngle = total > 0
          ? (cat.amount / total) * 2 * math.pi * animationValue
          : 0.0;
      final isSelected = selectedIndex == i;
      final isHovered = hoveredIndex == i;

      // Calculate offset for selected/hovered segment
      final expandOffset = (isSelected || isHovered) ? 8.0 : 0.0;
      final midAngle = startAngle + sweepAngle / 2;
      final offsetX = math.cos(midAngle) * expandOffset;
      final offsetY = math.sin(midAngle) * expandOffset;
      final segmentCenter = Offset(center.dx + offsetX, center.dy + offsetY);

      // Draw segment with gradient
      _drawSegment(
        canvas,
        segmentCenter,
        outerRadius + (isSelected ? 5 : 0),
        innerRadius,
        startAngle,
        sweepAngle,
        cat.category.color,
        isSelected || isHovered,
      );

      // Draw glow effect for selected segment
      if (isSelected) {
        _drawGlowEffect(
          canvas,
          segmentCenter,
          outerRadius + 5,
          startAngle,
          sweepAngle,
          cat.category.color,
        );
      }

      // Draw shimmer highlight
      _drawShimmerHighlight(
        canvas,
        segmentCenter,
        outerRadius,
        innerRadius,
        startAngle,
        sweepAngle,
      );

      startAngle += sweepAngle;
    }

    // Draw inner circle gradient overlay for depth
    _drawInnerGradient(canvas, center, innerRadius);
  }

  void _drawShadowBase(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
  ) {
    // Outer shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(
      Offset(center.dx, center.dy + 8),
      outerRadius,
      shadowPaint,
    );
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
    bool isHighlighted,
  ) {
    if (sweepAngle <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: outerRadius);

    // Draw the arc segment
    final path = Path()
      ..moveTo(
        center.dx + innerRadius * math.cos(startAngle),
        center.dy + innerRadius * math.sin(startAngle),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle,
        false,
      )
      ..lineTo(
        center.dx + outerRadius * math.cos(startAngle + sweepAngle),
        center.dy + outerRadius * math.sin(startAngle + sweepAngle),
      )
      ..arcTo(rect, startAngle + sweepAngle, -sweepAngle, false)
      ..close();

    // Draw main segment
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Draw gradient overlay
    final overlayPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.5,
        colors: [
          Colors.white.withValues(alpha: isHighlighted ? 0.4 : 0.25),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawPath(path, overlayPaint);

    // Draw segment border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, borderPaint);
  }

  void _drawGlowEffect(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    for (int i = 0; i < 3; i++) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15 - i * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 + i * 4
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 + i * 3);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + i * 3),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  void _drawShimmerHighlight(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
  ) {
    if (sweepAngle <= 0) return;

    final shimmerAngle = startAngle + shimmerValue * 2 * math.pi;
    final midRadius = (outerRadius + innerRadius) / 2;

    // Only draw shimmer if it's within this segment
    if (shimmerAngle >= startAngle && shimmerAngle <= startAngle + sweepAngle) {
      final shimmerX = center.dx + midRadius * math.cos(shimmerAngle);
      final shimmerY = center.dy + midRadius * math.sin(shimmerAngle);

      final shimmerPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 1.0],
            ).createShader(
              Rect.fromCircle(center: Offset(shimmerX, shimmerY), radius: 20),
            );

      canvas.drawCircle(Offset(shimmerX, shimmerY), 15, shimmerPaint);
    }
  }

  void _drawInnerGradient(Canvas canvas, Offset center, double innerRadius) {
    final innerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.drawCircle(center, innerRadius - 2, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _Premium3DDonutPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.shimmerValue != shimmerValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

// Glassy Category Card
class _GlassyCategoryCard extends StatelessWidget {
  final PaymentCategoryData category;

  const _GlassyCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final cat = category.category;
    final isPaid = category.remaining <= 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: cat.color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(cat.icon, color: cat.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (isPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: Color(0xFF10B981),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Payé',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar with gradient
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (category.progressPercent / 100).clamp(
                              0.0,
                              1.0,
                            ),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cat.color,
                                    cat.color.withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: cat.color.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatCurrency(category.paid)} / ${_formatCurrency(category.amount)} TND',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (!isPaid)
                          Text(
                            'Reste: ${_formatCurrency(category.remaining)} TND',
                            style: TextStyle(
                              fontSize: 11,
                              color: cat.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return formatter.format(amount);
  }
}

// Glassy Payment Card
class _GlassyPaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final String currency;

  const _GlassyPaymentCard({required this.payment, required this.currency});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isPaid = payment.status == 'paid';
    final isOverdue =
        !isPaid &&
        payment.dueDate != null &&
        payment.dueDate!.isBefore(DateTime.now());

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isPaid) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Payé';
    } else if (isOverdue) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.warning_rounded;
      statusText = 'En retard';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.schedule_rounded;
      statusText = 'En attente';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Échéance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (payment.dueDate != null)
                      Text(
                        dateFormat.format(payment.dueDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatCurrency(payment.amount)} $currency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return formatter.format(amount);
  }
}
