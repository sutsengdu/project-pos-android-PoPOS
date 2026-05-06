class Expense {
  final int? id;
  final String title;
  final double amount;
  final String? category;
  final String date;
  final String timestamp;
  final String? staffName;
  final bool isSynced;
  final String? remoteId;
  final String? uuid;
  final String? updatedAt;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    this.category,
    required this.date,
    required this.timestamp,
    this.staffName,
    this.isSynced = false,
    this.remoteId,
    this.uuid,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date,
      'timestamp': timestamp,
      'staff_name': staffName,
      'is_synced': isSynced ? 1 : 0,
      'remote_id': remoteId,
      'uuid': uuid,
      'updated_at': updatedAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount']?.toDouble() ?? 0.0,
      category: map['category'],
      date: map['date'],
      timestamp: map['timestamp'],
      staffName: map['staff_name'],
      isSynced: (map['is_synced'] == 1 || map['is_synced'] == true),
      remoteId: map['remote_id'],
      uuid: map['uuid'],
      updatedAt: map['updated_at'],
    );
  }
}
