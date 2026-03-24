import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> get products => _products;

  Future<void> fetchProducts() async {
    _products = await DatabaseHelper().getProducts();
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper().insertProduct(product);
    await fetchProducts();
    _checkLowStock(product);
  }

  Future<void> updateProduct(Product product) async {
    await DatabaseHelper().updateProduct(product);
    await fetchProducts();
    _checkLowStock(product);
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseHelper().deleteProduct(id);
    await fetchProducts();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    return await DatabaseHelper().getProductByBarcode(barcode);
  }

  Future<void> refreshAndCheckStock(List<int> productIds) async {
    await fetchProducts();
    for (var id in productIds) {
      final product = _products.firstWhere((p) => p.id == id);
      _checkLowStock(product);
    }
  }

  void _checkLowStock(Product product) {
    if (product.stock <= product.lowStockThreshold) {
      NotificationService().showLowStockNotification(product.name, product.stock);
    }
  }

  List<Product> get lowStockProducts {
    return _products.where((p) => p.stock <= p.lowStockThreshold).toList();
  }

  double get totalInstockWorth {
    return _products.fold(0.0, (sum, p) => sum + (p.price * p.stock));
  }
}
