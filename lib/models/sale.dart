class Sale {
  final int? id;
  final double totalAmount;
  final DateTime timestamp;
  final String paymentMethod;
  final double amountPaid;
  final double change;

  Sale({
    this.id,
    required this.totalAmount,
    required this.timestamp,
    this.paymentMethod = 'Cash',
    this.amountPaid = 0.0,
    this.change = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'change_amount': change,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      totalAmount: map['total_amount'],
      timestamp: DateTime.parse(map['timestamp']),
      paymentMethod: map['payment_method'] ?? 'Cash',
      amountPaid: map['amount_paid'] ?? map['total_amount'],
      change: map['change_amount'] ?? 0.0,
    );
  }
}
