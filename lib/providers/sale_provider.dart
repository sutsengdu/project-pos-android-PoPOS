import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class SaleProvider with ChangeNotifier {
  Map<int, SaleItem> _cartItems = {};
  Map<int, SaleItem> get cartItems => _cartItems;

  List<Sale> _sales = [];
  List<Sale> get sales => _sales;

  double _discountAmount = 0.0;
  String _discountType = 'fixed'; // 'fixed' or 'percentage'
  
  double get discountAmount => _discountAmount;
  String get discountType => _discountType;

  void setDiscount(double amount, String type) {
    _discountAmount = amount;
    _discountType = type;
    notifyListeners();
  }

  double get discountValue {
    if (_discountType == 'percentage') {
      return subTotal * (_discountAmount / 100);
    }
    return _discountAmount;
  }

  double get subTotal {
    double total = 0.0;
    _cartItems.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  double getTotalWithTax(double taxRate) {
    double discountedSubtotal = subTotal - discountValue;
    if (discountedSubtotal < 0) discountedSubtotal = 0;
    return discountedSubtotal * (1 + taxRate / 100);
  }

  void addToCart(Product product) {
    if (_cartItems.containsKey(product.id)) {
      _cartItems.update(
        product.id!,
        (existing) => SaleItem(
          saleId: 0,
          productId: existing.productId,
          quantity: existing.quantity + 1,
          price: existing.price,
          cost: existing.cost,
        ),
      );
    } else {
      _cartItems.putIfAbsent(
        product.id!,
        () => SaleItem(
          saleId: 0,
          productId: product.id!,
          quantity: 1,
          price: product.price,
          cost: product.cost,
        ),
      );
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cartItems.remove(productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int delta) {
    if (_cartItems.containsKey(productId)) {
      final existing = _cartItems[productId]!;
      final newQty = existing.quantity + delta;
      
      if (newQty <= 0) {
        _cartItems.remove(productId);
      } else {
        _cartItems.update(
          productId,
          (existing) => SaleItem(
            saleId: existing.saleId,
            productId: existing.productId,
            quantity: newQty,
            price: existing.price,
            cost: existing.cost,
          ),
        );
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems = {};
    _discountAmount = 0.0;
    _discountType = 'fixed';
    notifyListeners();
  }

  Future<Sale?> completeSale(BuildContext context, {
    required double totalAmount,
    double discountAmount = 0.0,
    String discountType = 'fixed',
    String paymentMethod = 'Cash',
    double amountPaid = 0.0,
    double change = 0.0,
    String? customerName,
    String? cashierName,
  }) async {
    if (_cartItems.isEmpty) return null;

    final sale = Sale(
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      discountType: discountType,
      taxRate: Provider.of<SettingsProvider>(context, listen: false).settings.taxRate,
      timestamp: DateTime.now(),
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      change: change,
      customerName: customerName,
      cashierName: cashierName,
    );

    final itemsList = _cartItems.values.toList();
    final saleId = await DatabaseHelper().insertSale(sale, itemsList);
    
    // Clear cart
    _cartItems = {};
    _discountAmount = 0.0;
    _discountType = 'fixed';
    notifyListeners();

    // Refresh data
    await fetchSales();
    
    // We need to trigger stock check in ProductProvider
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.refreshAndCheckStock(itemsList.map((e) => e.productId).toList());

    // Return the EXACT saved sale by its ID
    return await DatabaseHelper().getSaleById(saleId);
  }

  Future<void> fetchSales() async {
    _sales = await DatabaseHelper().getSales();
    notifyListeners();
  }

  Future<void> deleteSale(int id) async {
    await DatabaseHelper().deleteSale(id);
    await fetchSales();
  }

  Future<List<Map<String, dynamic>>> getSaleDetails(int saleId) async {
    return await DatabaseHelper().getSaleDetails(saleId);
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime start, DateTime end) async {
    return await DatabaseHelper().getTopSellingProducts(start, end);
  }

  Future<double> getProfit(DateTime start, DateTime end) async {
    return await DatabaseHelper().getProfit(start, end);
  }

  List<Map<String, dynamic>> getSalesForChart(String period, {int offset = 0}) {
    final now = DateTime.now();
    
    if (period == 'daily') {
      final baseDate = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
      final filtered = _sales.where((s) => 
        s.timestamp.year == baseDate.year && 
        s.timestamp.month == baseDate.month && 
        s.timestamp.day == baseDate.day
      ).toList();
      
      final Map<int, double> hourlyTotals = {};
      for (int i = 0; i < 24; i++) hourlyTotals[i] = 0.0;
      
      for (var s in filtered) {
        hourlyTotals[s.timestamp.hour] = (hourlyTotals[s.timestamp.hour] ?? 0) + s.totalAmount;
      }
      
      return hourlyTotals.entries
          .where((e) => e.value > 0 || (e.key >= 8 && e.key <= 20))
          .map((e) => {'label': '${e.key}h', 'value': e.value})
          .toList();

    } else if (period == 'weekly') {
      final Map<String, double> dailyTotals = {};
      final DateFormat formatter = DateFormat('E');
      
      final baseStart = DateTime(now.year, now.month, now.day).add(Duration(days: offset * 7));
      
      for (int i = 6; i >= 0; i--) {
        final d = baseStart.subtract(Duration(days: i));
        dailyTotals[formatter.format(d)] = 0.0;
      }
      
      final weekStart = baseStart.subtract(const Duration(days: 6));
      final weekEnd = baseStart.add(const Duration(days: 1));
      
      for (var s in _sales) {
        if (s.timestamp.isAfter(weekStart.subtract(const Duration(seconds: 1))) && s.timestamp.isBefore(weekEnd)) {
          final label = formatter.format(s.timestamp);
          dailyTotals[label] = (dailyTotals[label] ?? 0) + s.totalAmount;
        }
      }
      
      return dailyTotals.entries.map((e) => {'label': e.key, 'value': e.value}).toList();
      
    } else { // monthly
      final List<Map<String, dynamic>> weeklyData = [];
      final baseStart = DateTime(now.year, now.month, now.day).add(Duration(days: offset * 28));
      
      for (int i = 3; i >= 0; i--) {
        final weekEnd = baseStart.subtract(Duration(days: i * 7));
        final weekStart = weekEnd.subtract(const Duration(days: 6));
        
        double total = 0;
        for (var s in _sales) {
          if (s.timestamp.isAfter(weekStart.subtract(const Duration(seconds: 1))) && s.timestamp.isBefore(weekEnd.add(const Duration(days: 1)))) {
            total += s.totalAmount;
          }
        }
        
        String label;
        if (offset == 0) {
           label = i == 0 ? 'Now' : '${i}w ago';
        } else {
           final df = DateFormat('MMM d');
           label = df.format(weekEnd);
        }

        weeklyData.add({
          'label': label,
          'value': total,
        });
      }
      
      return weeklyData;
    }
  }
}
