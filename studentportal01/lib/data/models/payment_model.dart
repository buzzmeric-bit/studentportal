class PaymentPlanModel {
  final String id;
  final String enrollmentId;
  final String planType; // monthly, semester, annual
  final double amountTotal;
  final String currency;
  final String? description;
  final DateTime createdAt;
  final List<PaymentModel>? payments;

  PaymentPlanModel({
    required this.id,
    required this.enrollmentId,
    required this.planType,
    required this.amountTotal,
    required this.currency,
    this.description,
    required this.createdAt,
    this.payments,
  });

  factory PaymentPlanModel.fromJson(Map<String, dynamic> json) {
    return PaymentPlanModel(
      id: json['id'] as String,
      enrollmentId: json['enrollment_id'] as String,
      planType: json['plan_type'] as String,
      amountTotal: (json['amount_total'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'DZD',
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      payments: json['payments'] != null
          ? (json['payments'] as List)
              .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enrollment_id': enrollmentId,
      'plan_type': planType,
      'amount_total': amountTotal,
      'currency': currency,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get paidAmount {
    if (payments == null) return 0;
    return payments!
        .where((p) => p.status == 'paid')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double get remainingAmount => amountTotal - paidAmount;

  double get progressPercent => 
      amountTotal > 0 ? (paidAmount / amountTotal) * 100 : 0;
}

class PaymentModel {
  final String id;
  final String paymentPlanId;
  final double amount;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? method;
  final String status; // pending, paid, overdue, cancelled
  final String? reference;
  final String? notes;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.paymentPlanId,
    required this.amount,
    this.dueDate,
    this.paidAt,
    this.method,
    required this.status,
    this.reference,
    this.notes,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      paymentPlanId: json['payment_plan_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String)
          : null,
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      method: json['method'] as String?,
      status: json['status'] as String,
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_plan_id': paymentPlanId,
      'amount': amount,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'paid_at': paidAt?.toIso8601String(),
      'method': method,
      'status': status,
      'reference': reference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayMethod {
    switch (method) {
      case 'cash':
        return 'Espèces';
      case 'bank_transfer':
        return 'Virement bancaire';
      case 'card':
        return 'Carte bancaire';
      case 'check':
        return 'Chèque';
      default:
        return method ?? '-';
    }
  }
}
