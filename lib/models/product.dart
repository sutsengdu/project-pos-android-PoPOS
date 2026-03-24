class Product {
  final int? id;
  final String name;
  final int categoryId;
  final double price;
  final double costPrice;
  final int stock;
  final String barcode;
  final int lowStockThreshold;

  Product({
    this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.barcode,
    this.lowStockThreshold = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'barcode': barcode,
      'low_stock_threshold': lowStockThreshold,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      categoryId: map['category_id'],
      price: map['price'],
      costPrice: map['cost_price'],
      stock: map['stock'],
      barcode: map['barcode'],
      lowStockThreshold: map['low_stock_threshold'] ?? 5,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    int? categoryId,
    double? price,
    double? costPrice,
    int? stock,
    String? barcode,
    int? lowStockThreshold,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}
