class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final int quantity;
  final double price;
  final double cost;
  final String? uuid;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.cost,
    this.uuid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'unit_price': price, // Legacy support
      'cost': cost,
      'cost_price': cost, // Legacy support
      'uuid': uuid,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'] ?? 0,
      productId: map['product_id'] ?? 0,
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? map['unit_price'] ?? 0.0).toDouble(),
      cost: (map['cost'] ?? map['cost_price'] ?? 0.0).toDouble(),
      uuid: map['uuid'],
    );
  }
}
