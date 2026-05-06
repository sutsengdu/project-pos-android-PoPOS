class Staff {
  final int? id;
  final String name;
  final String role; // 'Admin', 'Manager', 'Cashier'
  final String pin;
  final bool isActive;
  final DateTime createdAt;
  final bool isSynced;
  final String? remoteId;
  final String? uuid;
  final String? updatedAt;

  Staff({
    this.id,
    required this.name,
    required this.role,
    required this.pin,
    this.isActive = true,
    DateTime? createdAt,
    this.isSynced = false,
    this.remoteId,
    this.uuid,
    this.updatedAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'pin': pin,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'remote_id': remoteId,
      'uuid': uuid,
      'updated_at': updatedAt,
    };
  }

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'],
      name: map['name'],
      role: map['role'],
      pin: map['pin'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      isSynced: (map['is_synced'] == 1 || map['is_synced'] == true),
      remoteId: map['remote_id'],
      uuid: map['uuid'],
      updatedAt: map['updated_at'],
    );
  }

  Staff copyWith({
    int? id,
    String? name,
    String? role,
    String? pin,
    bool? isActive,
    bool? isSynced,
    String? remoteId,
    String? uuid,
    String? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: this.createdAt,
    );
  }

  bool get isAdmin => role == 'Admin';
  bool get isManager => role == 'Manager' || role == 'Admin';
}
