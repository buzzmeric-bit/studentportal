import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';

class Payment {
  final String id;
  final String paymentPlanId;
  final double amount;
  final String status;
  final DateTime? paidAt;
  final DateTime dueDate;
  final String? studentName;
  final String? className;

  Payment({required this.id, required this.paymentPlanId, required this.amount, required this.status, this.paidAt, required this.dueDate, this.studentName, this.className});

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id']?.toString() ?? '',
    paymentPlanId: json['payment_plan_id']?.toString() ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    status: json['status']?.toString() ?? 'pending',
    paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
    dueDate: DateTime.tryParse(json['due_date']?.toString() ?? '') ?? DateTime.now(),
    studentName: json['payment_plans']?['enrollments']?['users']?['full_name']?.toString(),
    className: json['payment_plans']?['enrollments']?['classes']?['name']?.toString(),
  );
}

class PaymentsState {
  final List<Payment> payments;
  final String statusFilter;
  PaymentsState({this.payments = const [], this.statusFilter = 'all'});

  List<Payment> get filtered => statusFilter == 'all' ? payments : payments.where((p) => p.status == statusFilter).toList();

  PaymentsState copyWith({List<Payment>? payments, String? statusFilter}) =>
    PaymentsState(payments: payments ?? this.payments, statusFilter: statusFilter ?? this.statusFilter);
}

class PaymentsNotifier extends AsyncNotifier<PaymentsState> {
  @override
  Future<PaymentsState> build() async => _load();

  Future<PaymentsState> _load() async {
    final supabase = SupabaseConfig.client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Non connecte');

    final profile = await supabase.from('users').select('school_id').eq('id', user.id).single();
    final data = await supabase.from('payments').select('*, payment_plans(enrollments(users(full_name, school_id), classes(name)))').order('due_date', ascending: false);

    final payments = (data as List).where((e) => e['payment_plans']?['enrollments']?['users']?['school_id'] == profile['school_id']).map((e) => Payment.fromJson(e)).toList();
    return PaymentsState(payments: payments);
  }

  void setStatusFilter(String status) {
    state.whenData((s) => state = AsyncData(s.copyWith(statusFilter: status)));
  }

  Future<void> markAsPaid(String id) async {
    await SupabaseConfig.client.from('payments').update({'status': 'paid', 'paid_at': DateTime.now().toIso8601String()}).eq('id', id);
    ref.invalidateSelf();
  }
}

final paymentsProvider = AsyncNotifierProvider<PaymentsNotifier, PaymentsState>(PaymentsNotifier.new);