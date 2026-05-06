class Sale {
  final int? id;
  final double totalAmount;
  final double discountAmount;
  final String discountType; // 'fixed' or 'percentage'
  final double taxRate;
  final DateTime timestamp;
  final String paymentMethod;
  final double amountPaid;
  final double change;
  final String? customerName;
  final String? cashierName;
  final bool isSynced;
  final String? remoteId;
  final String? uuid;
  final String? updatedAt;

  Sale({
    this.id,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.discountType = 'fixed',
    this.taxRate = 0.0,
    required this.timestamp,
    this.paymentMethod = 'Cash',
    this.amountPaid = 0.0,
    this.change = 0.0,
    this.customerName,
    this.cashierName,
    this.isSynced = false,
    this.remoteId,
    this.uuid,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'discount_type': discountType,
      'tax_rate': taxRate,
      'timestamp': timestamp.toIso8601String(),
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'change_amount': change,
      'customer_name': customerName,
      'cashier_name': cashierName,
      'is_synced': isSynced ? 1 : 0,
      'remote_id': remoteId,
      'uuid': uuid,
      'updated_at': updatedAt,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      discountAmount: map['discount_amount']?.toDouble() ?? 0.0,
      discountType: map['discount_type'] ?? 'fixed',
      taxRate: map['tax_rate']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      paymentMethod: map['payment_method'] ?? 'Cash',
      amountPaid: map['amount_paid']?.toDouble() ?? map['total_amount']?.toDouble() ?? 0.0,
      change: map['change_amount']?.toDouble() ?? 0.0,
      customerName: map['customer_name'],
      cashierName: map['cashier_name'],
      isSynced: (map['is_synced'] == 1 || map['is_synced'] == true),
      remoteId: map['remote_id'],
      uuid: map['uuid'],
      updatedAt: map['updated_at'],
    );
  }
}
