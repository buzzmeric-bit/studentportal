import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENT MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Payment category enum matching student app
enum PaymentCategory {
  scolarite('Scolarité', 0xFF6366F1),
  transport('Transport/Bus', 0xFFF59E0B),
  inscription('Inscription', 0xFF10B981),
  uniforme('Uniforme', 0xFFEC4899),
  cantine('Cantine', 0xFF8B5CF6),
  activites('Activités', 0xFF06B6D4),
  autres('Autres', 0xFF64748B);

  final String label;
  final int colorValue;
  const PaymentCategory(this.label, this.colorValue);
}

/// Payment status enum
enum PaymentStatus {
  pending('En attente', 0xFFF59E0B),
  paid('Payé', 0xFF10B981),
  overdue('En retard', 0xFFEF4444),
  cancelled('Annulé', 0xFF64748B);

  final String label;
  final int colorValue;
  const PaymentStatus(this.label, this.colorValue);

  static PaymentStatus fromString(String s) {
    switch (s) {
      case 'paid': return PaymentStatus.paid;
      case 'overdue': return PaymentStatus.overdue;
      case 'cancelled': return PaymentStatus.cancelled;
      default: return PaymentStatus.pending;
    }
  }
}

/// Payment plan type
enum PaymentPlanType {
  monthly('Mensuel'),
  semester('Semestriel'),
  annual('Annuel');

  final String label;
  const PaymentPlanType(this.label);

  static PaymentPlanType fromString(String s) {
    switch (s) {
      case 'semester': return PaymentPlanType.semester;
      case 'annual': return PaymentPlanType.annual;
      default: return PaymentPlanType.monthly;
    }
  }
}

/// Payment model
class Payment {
  final String id;
  final String paymentPlanId;
  final double amount;
  final PaymentStatus status;
  final DateTime? paidAt;
  final DateTime dueDate;
  final String? method;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  // Related data
  final String? studentId;
  final String? studentName;
  final String? studentEmail;
  final String? classId;
  final String? className;
  final String? category;

  Payment({
    required this.id,
    required this.paymentPlanId,
    required this.amount,
    required this.status,
    this.paidAt,
    required this.dueDate,
    this.method,
    this.reference,
    this.notes,
    required this.createdAt,
    this.studentId,
    this.studentName,
    this.studentEmail,
    this.classId,
    this.className,
    this.category,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final paymentPlan = json['payment_plans'] as Map<String, dynamic>?;
    final enrollment = paymentPlan?['enrollments'] as Map<String, dynamic>?;
    final user = enrollment?['users'] as Map<String, dynamic>?;
    final classData = enrollment?['classes'] as Map<String, dynamic>?;

    return Payment(
      id: json['id']?.toString() ?? '',
      paymentPlanId: json['payment_plan_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: PaymentStatus.fromString(json['status']?.toString() ?? 'pending'),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? '') ?? DateTime.now(),
      method: json['method']?.toString(),
      reference: json['reference']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      studentId: user?['id']?.toString(),
      studentName: user?['full_name']?.toString(),
      studentEmail: user?['email']?.toString(),
      classId: classData?['id']?.toString(),
      className: classData?['name']?.toString(),
      category: paymentPlan?['description']?.toString(),
    );
  }

  bool get isOverdue => status == PaymentStatus.pending && dueDate.isBefore(DateTime.now());

  Payment copyWith({
    String? id,
    String? paymentPlanId,
    double? amount,
    PaymentStatus? status,
    DateTime? paidAt,
    DateTime? dueDate,
    String? method,
    String? reference,
    String? notes,
    DateTime? createdAt,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? classId,
    String? className,
    String? category,
  }) {
    return Payment(
      id: id ?? this.id,
      paymentPlanId: paymentPlanId ?? this.paymentPlanId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      dueDate: dueDate ?? this.dueDate,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      category: category ?? this.category,
    );
  }
}

/// Payment plan model
class PaymentPlan {
  final String id;
  final String enrollmentId;
  final PaymentPlanType planType;
  final double amountTotal;
  final String currency;
  final String? description;
  final DateTime createdAt;
  final List<Payment> payments;
  // Related data
  final String? studentId;
  final String? studentName;
  final String? classId;
  final String? className;

  PaymentPlan({
    required this.id,
    required this.enrollmentId,
    required this.planType,
    required this.amountTotal,
    required this.currency,
    this.description,
    required this.createdAt,
    this.payments = const [],
    this.studentId,
    this.studentName,
    this.classId,
    this.className,
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    final enrollment = json['enrollments'] as Map<String, dynamic>?;
    final user = enrollment?['users'] as Map<String, dynamic>?;
    final classData = enrollment?['classes'] as Map<String, dynamic>?;

    return PaymentPlan(
      id: json['id']?.toString() ?? '',
      enrollmentId: json['enrollment_id']?.toString() ?? '',
      planType: PaymentPlanType.fromString(json['plan_type']?.toString() ?? 'monthly'),
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'TND',
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      payments: (json['payments'] as List?)?.map((e) => Payment.fromJson(e)).toList() ?? [],
      studentId: user?['id']?.toString(),
      studentName: user?['full_name']?.toString(),
      classId: classData?['id']?.toString(),
      className: classData?['name']?.toString(),
    );
  }

  double get paidAmount => payments
      .where((p) => p.status == PaymentStatus.paid)
      .fold(0.0, (sum, p) => sum + p.amount);

  double get pendingAmount => amountTotal - paidAmount;

  double get progressPercent => amountTotal > 0 ? (paidAmount / amountTotal) * 100 : 0;

  int get paidCount => payments.where((p) => p.status == PaymentStatus.paid).length;
  int get pendingCount => payments.where((p) => p.status == PaymentStatus.pending).length;
  int get overdueCount => payments.where((p) => p.isOverdue).length;
}

/// Student payment summary
class StudentPaymentSummary {
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final String? classId;
  final String? className;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final int totalPayments;
  final int paidPayments;
  final int overduePayments;
  final List<PaymentPlan> plans;

  StudentPaymentSummary({
    required this.studentId,
    required this.studentName,
    this.studentEmail,
    this.classId,
    this.className,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.totalPayments,
    required this.paidPayments,
    required this.overduePayments,
    required this.plans,
  });

  double get progressPercent => totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENTS STATE
// ═══════════════════════════════════════════════════════════════════════════

class PaymentsState {
  final List<Payment> payments;
  final List<PaymentPlan> paymentPlans;
  final List<Map<String, dynamic>> classes;
  final List<StudentPaymentSummary> studentSummaries;
  
  // Filters
  final String statusFilter;
  final String? classFilter;
  final String? categoryFilter;
  final DateTime? dateFromFilter;
  final DateTime? dateToFilter;
  final String searchQuery;

  // Stats
  final double totalDue;
  final double totalCollected;
  final double totalPending;
  final double totalOverdue;
  final int overdueCount;

  PaymentsState({
    this.payments = const [],
    this.paymentPlans = const [],
    this.classes = const [],
    this.studentSummaries = const [],
    this.statusFilter = 'all',
    this.classFilter,
    this.categoryFilter,
    this.dateFromFilter,
    this.dateToFilter,
    this.searchQuery = '',
    this.totalDue = 0,
    this.totalCollected = 0,
    this.totalPending = 0,
    this.totalOverdue = 0,
    this.overdueCount = 0,
  });

  List<Payment> get filtered {
    return payments.where((p) {
      // Status filter
      if (statusFilter != 'all') {
        if (statusFilter == 'overdue') {
          if (!p.isOverdue) return false;
        } else if (p.status.name != statusFilter) {
          return false;
        }
      }
      
      // Class filter
      if (classFilter != null && classFilter!.isNotEmpty) {
        if (p.classId != classFilter) return false;
      }
      
      // Category filter
      if (categoryFilter != null && categoryFilter!.isNotEmpty) {
        if (p.category != categoryFilter) return false;
      }
      
      // Date range filter
      if (dateFromFilter != null) {
        if (p.dueDate.isBefore(dateFromFilter!)) return false;
      }
      if (dateToFilter != null) {
        if (p.dueDate.isAfter(dateToFilter!)) return false;
      }
      
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = p.studentName?.toLowerCase().contains(query) ?? false;
        final matchesClass = p.className?.toLowerCase().contains(query) ?? false;
        final matchesRef = p.reference?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesClass && !matchesRef) return false;
      }
      
      return true;
    }).toList();
  }

  List<StudentPaymentSummary> get filteredStudents {
    if (searchQuery.isEmpty && classFilter == null) return studentSummaries;
    
    return studentSummaries.where((s) {
      if (classFilter != null && classFilter!.isNotEmpty) {
        if (s.classId != classFilter) return false;
      }
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesName = s.studentName.toLowerCase().contains(query);
        final matchesClass = s.className?.toLowerCase().contains(query) ?? false;
        if (!matchesName && !matchesClass) return false;
      }
      return true;
    }).toList();
  }

  PaymentsState copyWith({
    List<Payment>? payments,
    List<PaymentPlan>? paymentPlans,
    List<Map<String, dynamic>>? classes,
    List<StudentPaymentSummary>? studentSummaries,
    String? statusFilter,
    String? classFilter,
    String? categoryFilter,
    DateTime? dateFromFilter,
    DateTime? dateToFilter,
    String? searchQuery,
    double? totalDue,
    double? totalCollected,
    double? totalPending,
    double? totalOverdue,
    int? overdueCount,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearClassFilter = false,
    bool clearCategoryFilter = false,
  }) {
    return PaymentsState(
      payments: payments ?? this.payments,
      paymentPlans: paymentPlans ?? this.paymentPlans,
      classes: classes ?? this.classes,
      studentSummaries: studentSummaries ?? this.studentSummaries,
      statusFilter: statusFilter ?? this.statusFilter,
      classFilter: clearClassFilter ? null : (classFilter ?? this.classFilter),
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      dateFromFilter: clearDateFrom ? null : (dateFromFilter ?? this.dateFromFilter),
      dateToFilter: clearDateTo ? null : (dateToFilter ?? this.dateToFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      totalDue: totalDue ?? this.totalDue,
      totalCollected: totalCollected ?? this.totalCollected,
      totalPending: totalPending ?? this.totalPending,
      totalOverdue: totalOverdue ?? this.totalOverdue,
      overdueCount: overdueCount ?? this.overdueCount,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENTS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class PaymentsNotifier extends AsyncNotifier<PaymentsState> {
  @override
  Future<PaymentsState> build() async => _load();

  Future<PaymentsState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecté');

    try {
      final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
      final schoolId = profile['school_id'];

      // Load classes for filter dropdown
      final classesData = await supabase
          .from('classes')
          .select('id, name')
          .eq('school_id', schoolId)
          .order('name');
      
      // Load payments with full relationships
      List<Payment> payments = [];
      List<PaymentPlan> paymentPlans = [];
      List<StudentPaymentSummary> studentSummaries = [];

      try {
        final paymentsData = await supabase
            .from('payments')
            .select('''
              *,
              payment_plans(
                *,
                enrollments(
                  id,
                  users(id, full_name, email, school_id),
                  classes(id, name)
                )
              )
            ''')
            .order('due_date', ascending: false);

        payments = (paymentsData as List)
            .where((e) => 
                e['payment_plans']?['enrollments']?['users']?['school_id'] == schoolId)
            .map((e) => Payment.fromJson(e))
            .toList();

        // Load payment plans for student summaries
        final plansData = await supabase
            .from('payment_plans')
            .select('''
              *,
              payments(*),
              enrollments(
                id,
                users(id, full_name, email, school_id),
                classes(id, name)
              )
            ''');

        final filteredPlans = (plansData as List)
            .where((e) => e['enrollments']?['users']?['school_id'] == schoolId)
            .map((e) => PaymentPlan.fromJson(e))
            .toList();

        paymentPlans = filteredPlans;

        // Build student summaries
        final studentMap = <String, StudentPaymentSummary>{};
        for (final plan in filteredPlans) {
          if (plan.studentId == null) continue;
          
          if (!studentMap.containsKey(plan.studentId)) {
            studentMap[plan.studentId!] = StudentPaymentSummary(
              studentId: plan.studentId!,
              studentName: plan.studentName ?? 'Inconnu',
              studentEmail: null,
              classId: plan.classId,
              className: plan.className,
              totalAmount: 0,
              paidAmount: 0,
              pendingAmount: 0,
              totalPayments: 0,
              paidPayments: 0,
              overduePayments: 0,
              plans: [],
            );
          }

          final existing = studentMap[plan.studentId!]!;
          studentMap[plan.studentId!] = StudentPaymentSummary(
            studentId: existing.studentId,
            studentName: existing.studentName,
            studentEmail: existing.studentEmail,
            classId: existing.classId ?? plan.classId,
            className: existing.className ?? plan.className,
            totalAmount: existing.totalAmount + plan.amountTotal,
            paidAmount: existing.paidAmount + plan.paidAmount,
            pendingAmount: existing.pendingAmount + plan.pendingAmount,
            totalPayments: existing.totalPayments + plan.payments.length,
            paidPayments: existing.paidPayments + plan.paidCount,
            overduePayments: existing.overduePayments + plan.overdueCount,
            plans: [...existing.plans, plan],
          );
        }
        studentSummaries = studentMap.values.toList()
          ..sort((a, b) => a.studentName.compareTo(b.studentName));

      } catch (e) {
        // Table might not exist or empty - use demo data
        payments = _generateDemoPayments();
        studentSummaries = _generateDemoStudentSummaries();
      }

      // Calculate stats
      double totalDue = 0;
      double totalCollected = 0;
      double totalPending = 0;
      double totalOverdue = 0;
      int overdueCount = 0;

      for (final p in payments) {
        totalDue += p.amount;
        if (p.status == PaymentStatus.paid) {
          totalCollected += p.amount;
        } else if (p.isOverdue) {
          totalOverdue += p.amount;
          overdueCount++;
        } else if (p.status == PaymentStatus.pending) {
          totalPending += p.amount;
        }
      }

      return PaymentsState(
        payments: payments,
        paymentPlans: paymentPlans,
        classes: (classesData as List).map((e) => e as Map<String, dynamic>).toList(),
        studentSummaries: studentSummaries,
        totalDue: totalDue,
        totalCollected: totalCollected,
        totalPending: totalPending,
        totalOverdue: totalOverdue,
        overdueCount: overdueCount,
      );
    } catch (e) {
      // Return demo data on error
      final demoPayments = _generateDemoPayments();
      return PaymentsState(
        payments: demoPayments,
        studentSummaries: _generateDemoStudentSummaries(),
        totalDue: demoPayments.fold(0.0, (sum, p) => sum + p.amount),
        totalCollected: demoPayments
            .where((p) => p.status == PaymentStatus.paid)
            .fold(0.0, (sum, p) => sum + p.amount),
        totalPending: demoPayments
            .where((p) => p.status == PaymentStatus.pending && !p.isOverdue)
            .fold(0.0, (sum, p) => sum + p.amount),
        totalOverdue: demoPayments
            .where((p) => p.isOverdue)
            .fold(0.0, (sum, p) => sum + p.amount),
        overdueCount: demoPayments.where((p) => p.isOverdue).length,
      );
    }
  }

  List<Payment> _generateDemoPayments() {
    final now = DateTime.now();
    final students = [
      {'id': '1', 'name': 'Ahmed Ben Ali', 'classId': 'c1', 'className': '4ème Année A'},
      {'id': '2', 'name': 'Fatma Trabelsi', 'classId': 'c1', 'className': '4ème Année A'},
      {'id': '3', 'name': 'Mohamed Salah', 'classId': 'c2', 'className': '3ème Année B'},
      {'id': '4', 'name': 'Amira Mansour', 'classId': 'c2', 'className': '3ème Année B'},
      {'id': '5', 'name': 'Youssef Hamdi', 'classId': 'c3', 'className': '2ème Année A'},
      {'id': '6', 'name': 'Sarra Bouaziz', 'classId': 'c3', 'className': '2ème Année A'},
    ];

    final categories = ['Scolarité', 'Transport/Bus', 'Inscription', 'Uniforme', 'Cantine'];
    
    return [
      for (int i = 0; i < 20; i++)
        Payment(
          id: 'demo_$i',
          paymentPlanId: 'plan_${i % 6}',
          amount: [250, 450, 500, 950, 200, 100, 350][i % 7].toDouble(),
          status: i % 4 == 0 
              ? PaymentStatus.paid 
              : (i % 4 == 3 ? PaymentStatus.overdue : PaymentStatus.pending),
          paidAt: i % 4 == 0 ? now.subtract(Duration(days: i * 3)) : null,
          dueDate: now.add(Duration(days: (i - 10) * 7)),
          method: i % 4 == 0 ? (i % 2 == 0 ? 'cash' : 'bank_transfer') : null,
          reference: i % 4 == 0 ? 'REC-2024-${100 + i}' : null,
          createdAt: now.subtract(Duration(days: 30 + i)),
          studentId: students[i % students.length]['id'],
          studentName: students[i % students.length]['name'],
          classId: students[i % students.length]['classId'],
          className: students[i % students.length]['className'],
          category: categories[i % categories.length],
        ),
    ];
  }

  List<StudentPaymentSummary> _generateDemoStudentSummaries() {
    return [
      StudentPaymentSummary(
        studentId: '1',
        studentName: 'Ahmed Ben Ali',
        classId: 'c1',
        className: '4ème Année A',
        totalAmount: 2850,
        paidAmount: 1900,
        pendingAmount: 950,
        totalPayments: 3,
        paidPayments: 2,
        overduePayments: 1,
        plans: [],
      ),
      StudentPaymentSummary(
        studentId: '2',
        studentName: 'Fatma Trabelsi',
        classId: 'c1',
        className: '4ème Année A',
        totalAmount: 2850,
        paidAmount: 2850,
        pendingAmount: 0,
        totalPayments: 3,
        paidPayments: 3,
        overduePayments: 0,
        plans: [],
      ),
      StudentPaymentSummary(
        studentId: '3',
        studentName: 'Mohamed Salah',
        classId: 'c2',
        className: '3ème Année B',
        totalAmount: 2500,
        paidAmount: 1000,
        pendingAmount: 1500,
        totalPayments: 3,
        paidPayments: 1,
        overduePayments: 0,
        plans: [],
      ),
      StudentPaymentSummary(
        studentId: '4',
        studentName: 'Amira Mansour',
        classId: 'c2',
        className: '3ème Année B',
        totalAmount: 2850,
        paidAmount: 950,
        pendingAmount: 1900,
        totalPayments: 3,
        paidPayments: 1,
        overduePayments: 2,
        plans: [],
      ),
      StudentPaymentSummary(
        studentId: '5',
        studentName: 'Youssef Hamdi',
        classId: 'c3',
        className: '2ème Année A',
        totalAmount: 2200,
        paidAmount: 2200,
        pendingAmount: 0,
        totalPayments: 2,
        paidPayments: 2,
        overduePayments: 0,
        plans: [],
      ),
      StudentPaymentSummary(
        studentId: '6',
        studentName: 'Sarra Bouaziz',
        classId: 'c3',
        className: '2ème Année A',
        totalAmount: 2500,
        paidAmount: 500,
        pendingAmount: 2000,
        totalPayments: 3,
        paidPayments: 1,
        overduePayments: 1,
        plans: [],
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void setStatusFilter(String status) {
    state.whenData((s) => state = AsyncData(s.copyWith(statusFilter: status)));
  }

  void setClassFilter(String? classId) {
    state.whenData((s) => state = AsyncData(
      classId == null 
          ? s.copyWith(clearClassFilter: true)
          : s.copyWith(classFilter: classId)
    ));
  }

  void setCategoryFilter(String? category) {
    state.whenData((s) => state = AsyncData(
      category == null 
          ? s.copyWith(clearCategoryFilter: true)
          : s.copyWith(categoryFilter: category)
    ));
  }

  void setDateFromFilter(DateTime? date) {
    state.whenData((s) => state = AsyncData(
      date == null 
          ? s.copyWith(clearDateFrom: true)
          : s.copyWith(dateFromFilter: date)
    ));
  }

  void setDateToFilter(DateTime? date) {
    state.whenData((s) => state = AsyncData(
      date == null 
          ? s.copyWith(clearDateTo: true)
          : s.copyWith(dateToFilter: date)
    ));
  }

  void setSearchQuery(String query) {
    state.whenData((s) => state = AsyncData(s.copyWith(searchQuery: query)));
  }

  void clearFilters() {
    state.whenData((s) => state = AsyncData(s.copyWith(
      statusFilter: 'all',
      clearClassFilter: true,
      clearCategoryFilter: true,
      clearDateFrom: true,
      clearDateTo: true,
      searchQuery: '',
    )));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> markAsPaid(String id, {String? method, String? reference}) async {
    try {
      await SupabaseConfig.client.from('payments').update({
        'status': 'paid',
        'paid_at': DateTime.now().toIso8601String(),
        if (method != null) 'method': method,
        if (reference != null) 'reference': reference,
      }).eq('id', id);
      ref.invalidateSelf();
    } catch (e) {
      // Demo mode - update locally
      state.whenData((s) {
        final payments = s.payments.map((p) {
          if (p.id == id) {
            return p.copyWith(
              status: PaymentStatus.paid,
              paidAt: DateTime.now(),
              method: method,
              reference: reference,
            );
          }
          return p;
        }).toList();
        state = AsyncData(s.copyWith(payments: payments));
      });
    }
  }

  Future<void> markAsOverdue(String id) async {
    try {
      await SupabaseConfig.client.from('payments').update({
        'status': 'overdue',
      }).eq('id', id);
      ref.invalidateSelf();
    } catch (e) {
      state.whenData((s) {
        final payments = s.payments.map((p) {
          if (p.id == id) {
            return p.copyWith(status: PaymentStatus.overdue);
          }
          return p;
        }).toList();
        state = AsyncData(s.copyWith(payments: payments));
      });
    }
  }

  Future<void> cancelPayment(String id) async {
    try {
      await SupabaseConfig.client.from('payments').update({
        'status': 'cancelled',
      }).eq('id', id);
      ref.invalidateSelf();
    } catch (e) {
      state.whenData((s) {
        final payments = s.payments.map((p) {
          if (p.id == id) {
            return p.copyWith(status: PaymentStatus.cancelled);
          }
          return p;
        }).toList();
        state = AsyncData(s.copyWith(payments: payments));
      });
    }
  }

  Future<void> updatePayment({
    required String id,
    double? amount,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      await SupabaseConfig.client.from('payments').update({
        if (amount != null) 'amount': amount,
        if (dueDate != null) 'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
        if (notes != null) 'notes': notes,
      }).eq('id', id);
      ref.invalidateSelf();
    } catch (e) {
      state.whenData((s) {
        final payments = s.payments.map((p) {
          if (p.id == id) {
            return p.copyWith(
              amount: amount,
              dueDate: dueDate,
              notes: notes,
            );
          }
          return p;
        }).toList();
        state = AsyncData(s.copyWith(payments: payments));
      });
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      await SupabaseConfig.client.from('payments').delete().eq('id', id);
      ref.invalidateSelf();
    } catch (e) {
      state.whenData((s) {
        final payments = s.payments.where((p) => p.id != id).toList();
        state = AsyncData(s.copyWith(payments: payments));
      });
    }
  }

  Future<void> addPayment({
    required String paymentPlanId,
    required double amount,
    required DateTime dueDate,
    String? notes,
  }) async {
    try {
      await SupabaseConfig.client.from('payments').insert({
        'payment_plan_id': paymentPlanId,
        'amount': amount,
        'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
        'status': 'pending',
        if (notes != null) 'notes': notes,
      });
      ref.invalidateSelf();
    } catch (e) {
      // Demo mode - just refresh
      ref.invalidateSelf();
    }
  }

  Future<void> bulkMarkAsPaid(List<String> ids, {String? method}) async {
    for (final id in ids) {
      await markAsPaid(id, method: method);
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final paymentsProvider = AsyncNotifierProvider<PaymentsNotifier, PaymentsState>(
  PaymentsNotifier.new,
);
