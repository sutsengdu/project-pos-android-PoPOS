class Product {
  final int? id;
  final String name;
  final int categoryId;
  final double price;
  final double cost;
  final int stock;
  final String barcode;
  final int lowStockThreshold;
  final String? uuid;
  final String? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.cost,
    required this.stock,
    required this.barcode,
    this.lowStockThreshold = 5,
    this.uuid,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'price': price,
      'unit_price': price, // Legacy support for NOT NULL constraints
      'cost': cost,
      'cost_price': cost, // Legacy support for NOT NULL constraints
      'stock': stock,
      'barcode': barcode,
      'low_stock_threshold': lowStockThreshold,
      'uuid': uuid,
      'updated_at': updatedAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      categoryId: map['category_id'] ?? 1,
      price: (map['price'] ?? map['unit_price'] ?? 0.0).toDouble(),
      cost: (map['cost'] ?? map['cost_price'] ?? 0.0).toDouble(),
      stock: map['stock'] ?? 0,
      barcode: map['barcode'] ?? '',
      lowStockThreshold: map['low_stock_threshold'] ?? 5,
      uuid: map['uuid'],
      updatedAt: map['updated_at'],
    );
  }

  Product copyWith({
    int? id,
    String? name,
    int? categoryId,
    double? price,
    double? cost,
    int? stock,
    String? barcode,
    int? lowStockThreshold,
    String? uuid,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
