import 'dart:math';
import '../models/category.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import 'database_helper.dart';

class DemoDataService {
  static Future<void> generateDemoData() async {
    final db = DatabaseHelper();
    
    // Clear existing
    await db.clearAllData();

    // 1. Categories
    final catIds = <int>[];
    final categoryNames = ['Electronics', 'Groceries', 'Beverages', 'Clothing', 'Home Decor'];
    for (var name in categoryNames) {
      final id = await db.insertCategory(Category(name: name));
      catIds.add(id);
    }

    // 2. Products
    final productIds = <int>[];
    final products = <Product>[
      Product(name: 'iPhone 15', categoryId: catIds[0], price: 999.0, costPrice: 700.0, stock: 50, barcode: '1001'),
      Product(name: 'MacBook Air', categoryId: catIds[0], price: 1200.0, costPrice: 900.0, stock: 20, barcode: '1002'),
      Product(name: 'Milk 1L', categoryId: catIds[1], price: 2.5, costPrice: 1.8, stock: 200, barcode: '2001'),
      Product(name: 'Bread', categoryId: catIds[1], price: 1.5, costPrice: 0.9, stock: 150, barcode: '2002'),
      Product(name: 'Coca Cola', categoryId: catIds[2], price: 1.2, costPrice: 0.6, stock: 500, barcode: '3001'),
      Product(name: 'Coffee Beans', categoryId: catIds[2], price: 15.0, costPrice: 9.0, stock: 100, barcode: '3002'),
      Product(name: 'T-Shirt', categoryId: catIds[3], price: 25.0, costPrice: 12.0, stock: 300, barcode: '4001'),
      Product(name: 'Jeans', categoryId: catIds[3], price: 45.0, costPrice: 22.0, stock: 200, barcode: '4002'),
      Product(name: 'Table Lamp', categoryId: catIds[4], price: 35.0, costPrice: 18.0, stock: 60, barcode: '5001'),
    ];

    for (var p in products) {
      final id = await db.insertProduct(p);
      productIds.add(id);
    }

    // 3. Sales for last 2 months
    final random = Random();
    final now = DateTime.now();
    
    for (int i = 0; i < 60; i++) {
      final date = now.subtract(Duration(days: i));
      // Random number of sales per day (0-5)
      final salesCount = random.nextInt(6);
      
      for (int k = 0; k < salesCount; k++) {
        final items = <SaleItem>[];
        double total = 0;
        
        // Random items per sale (1-3)
        final itemCount = random.nextInt(3) + 1;
        for (int j = 0; j < itemCount; j++) {
          final prodIndex = random.nextInt(products.length);
          final product = products[prodIndex];
          final qty = random.nextInt(3) + 1;
          
          items.add(SaleItem(
            saleId: 0,
            productId: productIds[prodIndex],
            quantity: qty,
            unitPrice: product.price,
          ));
          total += product.price * qty;
        }

        final sale = Sale(
          totalAmount: total,
          timestamp: date.add(Duration(hours: random.nextInt(12) + 8)),
          paymentMethod: random.nextBool() ? 'Cash' : 'Card',
          amountPaid: total,
          change: 0,
        );
        
        await db.insertSale(sale, items);
      }
    }
  }
}
