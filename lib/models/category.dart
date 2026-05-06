class Category {
  final int? id;
  final String name;
  final String? uuid;
  final String? updatedAt;

  Category({this.id, required this.name, this.uuid, this.updatedAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'uuid': uuid,
      'updated_at': updatedAt,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      uuid: map['uuid'],
      updatedAt: map['updated_at'],
    );
  }
}
