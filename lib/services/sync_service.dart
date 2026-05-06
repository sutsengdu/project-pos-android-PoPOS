import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shop_settings.dart';
import '../services/database_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  final String baseUrl; // E.g., http://your-laravel-api.test/api
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String? authToken;

  SyncService({String? baseUrl, this.authToken}) : baseUrl = baseUrl ?? dotenv.get('API_URL', fallback: 'http://192.168.99.14/project-pos/backend/public/api');

  static bool _isAutoSyncRunning = false;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  void initializeAutoSync(ShopSettings settings) {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        debugPrint('Network detected (${results.join(", ")})! Triggering auto-sync...');
        _triggerAutoSync(settings);
      }
    });
  }

  Future<void> _triggerAutoSync(ShopSettings settings) async {
    if (_isAutoSyncRunning || !settings.isLoggedIn || settings.cloudToken == null) return;
    _isAutoSyncRunning = true;
    try {
      await syncData(settings);
    } catch (e) {
      debugPrint('Auto-sync failed: $e');
    } finally {
      _isAutoSyncRunning = false;
    }
  }

  Future<String?> syncData([ShopSettings? settings]) async {
    if (settings != null && !settings.isProUnlocked) {
      return 'PRO subscription required for cloud sync.';
    }
    try {
      print('Starting Full Sync...');
      
      try {
        if (settings != null) await syncSettings(settings);
      } catch (e) { print('Settings sync error: $e'); }

      await Future.delayed(Duration.zero);
      try {
        await syncCategories();
      } catch (e) { print('Categories sync error: $e'); }

      await Future.delayed(Duration.zero);
      try {
        await syncProducts();
      } catch (e) { print('Products sync error: $e'); }

      await Future.delayed(Duration.zero);
      try {
        await syncSales();
      } catch (e) { print('Sales sync error: $e'); }

      await Future.delayed(Duration.zero);
      try {
        await syncExpenses();
      } catch (e) { print('Expenses sync error: $e'); }

      await Future.delayed(Duration.zero);
      try {
        await syncStaff();
      } catch (e) { print('Staff sync error: $e'); }
      
      // Pull changes from cloud
      print('Starting Cloud Pull...');
      await pullAll();
      
      print('Full Sync Completed!');
      return null; // Success
    } catch (e) {
      print('Overall sync error: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        return 'Connection error: Please check your API URL/IP address.';
      }
      return 'Sync error: $e';
    }
  }

  Future<void> syncCategories() async {
    final unsynced = await _dbHelper.getUnsynced('categories');
    for (var item in unsynced) {
      try {
        final payload = Map<String, dynamic>.from(item);
        // Ensure remote knows about our UUID and timestamp
        payload['uuid'] ??= item['uuid'];
        payload['updated_at'] = item['updated_at'];

        final response = await http.post(
          Uri.parse('$baseUrl/categories'),
          headers: _headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _dbHelper.markAsSynced('categories', item['id'], data['remote_id']?.toString() ?? data['id']?.toString() ?? '');
        } else {
          print('Category sync failed (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        print('Category sync error: $e');
      }
    }
  }

  Future<void> syncProducts() async {
    final unsynced = await _dbHelper.getUnsynced('products');
    for (var item in unsynced) {
      try {
        final payload = Map<String, dynamic>.from(item);
        
        // Fetch category uuid for better synchronization on backend
        if (item['category_id'] != null) {
          final categoryRes = await _dbHelper.getCategoryById(item['category_id']);
          if (categoryRes != null) {
            payload['category_uuid'] = categoryRes.uuid;
            payload['category_name'] = categoryRes.name;
          }
        }

        payload['uuid'] ??= item['uuid'];
        payload['updated_at'] = item['updated_at'];
        payload['price'] = (item['price'] ?? item['unit_price'] ?? 0.0).toDouble();
        payload['cost'] = (item['cost'] ?? item['cost_price'] ?? 0.0).toDouble();

        final response = await http.post(
          Uri.parse('$baseUrl/products'),
          headers: _headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _dbHelper.markAsSynced('products', item['id'], data['remote_id']?.toString() ?? data['id']?.toString() ?? '');
        } else {
          print('Product sync failed (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        print('Product sync error: $e');
      }
    }
  }

  Future<void> syncSales() async {
    final unsynced = await _dbHelper.getUnsynced('sales');
    if (unsynced.isEmpty) return;

    print('Syncing ${unsynced.length} sales in batches...');

    // Batch size of 50
    for (var i = 0; i < unsynced.length; i += 50) {
      final batch = unsynced.skip(i).take(50).toList();
      final List<Map<String, dynamic>> salesPayload = [];

      for (var item in batch) {
        try {
          await Future.delayed(Duration.zero);
          final details = await _dbHelper.getSaleDetails(item['id']);
          
          final mappedItems = details.map((d) {
            final mapped = Map<String, dynamic>.from(d);
            // Include UUIDs for items and products
            mapped['uuid'] = d['uuid'];
            if (d['product_remote_id'] != null) {
              mapped['product_id'] = int.tryParse(d['product_remote_id'].toString()) ?? d['product_id'];
            }
            // Add product uuid if available
            final prodUuid = d['product_uuid']; // We might need to select this in getSaleDetails
            if (prodUuid != null) mapped['product_uuid'] = prodUuid;

            mapped['price'] = (d['price'] ?? d['unit_price'] ?? 0.0).toDouble();
            mapped['cost'] = (d['cost'] ?? d['cost_price'] ?? 0.0).toDouble();
            return mapped;
          }).toList();

          final payload = Map<String, dynamic>.from(item);
          payload['uuid'] ??= item['uuid'];
          payload['local_id'] = item['id'];
          payload['updated_at'] = item['updated_at'];
          payload['items'] = mappedItems;
          payload['discount_amount'] = (item['discount_amount'] ?? 0.0).toDouble();
          payload['discount_type'] = item['discount_type'] ?? 'fixed';
          payload['tax_rate'] = (item['tax_rate'] ?? 0.0).toDouble();
          
          salesPayload.add(payload);
        } catch (e) {
          print('Error preparing sale ${item['id']}: $e');
        }
      }

      if (salesPayload.isEmpty) continue;

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/sales'),
          headers: _headers,
          body: jsonEncode({'sales': salesPayload}),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final Map<String, dynamic> syncedIds = data['synced_ids'] ?? {};
          
          print('Synced ${syncedIds.length} sales from batch of ${salesPayload.length}.');
          for (var localIdStr in syncedIds.keys) {
            final localId = int.tryParse(localIdStr);
            if (localId != null) {
              await _dbHelper.markAsSynced('sales', localId, syncedIds[localIdStr].toString());
            }
          }
        } else {
          print('Bulk sale sync failed with status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        print('Bulk sale sync error: $e');
      }
    }
  }

  Future<void> syncExpenses() async {
    final unsynced = await _dbHelper.getUnsynced('expenses');
    for (var item in unsynced) {
      try {
        final payload = Map<String, dynamic>.from(item);
        payload['uuid'] ??= item['uuid'];
        payload['updated_at'] = item['updated_at'];

        final response = await http.post(
          Uri.parse('$baseUrl/expenses'),
          headers: _headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _dbHelper.markAsSynced('expenses', item['id'], data['remote_id']?.toString() ?? data['id']?.toString() ?? '');
        } else {
          print('Expense sync failed (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        print('Expense sync error: $e');
      }
    }
  }

  Future<void> syncStaff() async {
    final unsynced = await _dbHelper.getUnsynced('staff');
    for (var item in unsynced) {
      try {
        final payload = Map<String, dynamic>.from(item);
        payload['uuid'] ??= item['uuid'];
        payload['updated_at'] = item['updated_at'];

        final response = await http.post(
          Uri.parse('$baseUrl/staff'),
          headers: _headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _dbHelper.markAsSynced('staff', item['id'], data['remote_id']?.toString() ?? data['id']?.toString() ?? '');
        } else {
          print('Staff sync failed (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        print('Staff sync error: $e');
      }
    }
  }

  Future<void> syncSettings(ShopSettings settings) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
        body: jsonEncode({
          'store_name': settings.name,
          'store_address': settings.address,
          'store_phone': settings.phone,
          'store_email': settings.email,
          'receipt_message': settings.footerMessage,
          'currency_symbol': settings.currencySymbol,
          'tax_rate': settings.taxRate,
          'is_dark_mode': settings.isDarkMode ? 1 : 0,
          'language_code': settings.languageCode,
          'mmqr_image_url': settings.mmqrImagePath,
        }),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        print("Settings sync failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Settings sync error: $e");
      rethrow; // Re-throw to be caught by syncData's try-catch
    }
  }

  // --- Cloud Integration ---
  
  Future<String?> syncAll([ShopSettings? settings]) async {
    return await syncData(settings);
  }

  Future<void> pullAll([String? token, String? url]) async {
    final targetUrl = url ?? baseUrl;
    final targetToken = token ?? authToken;
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (targetToken != null) 'Authorization': 'Bearer $targetToken',
    };

    // Pull Categories
    print('Pulling Categories...');
    final catRes = await http.get(Uri.parse('$targetUrl/categories'), headers: headers).timeout(const Duration(seconds: 30));
    if (catRes.statusCode == 200) {
      final List cats = jsonDecode(catRes.body);
      print('Upserting ${cats.length} categories...');
      await (await _dbHelper.database).transaction((txn) async {
        for (var cat in cats) {
          await _dbHelper.upsertCategory(cat, txn);
        }
      });
      await Future.delayed(Duration.zero);
    }

    // Pull Products
    print('Pulling Products...');
    final prodRes = await http.get(Uri.parse('$targetUrl/products'), headers: headers).timeout(const Duration(seconds: 30));
    if (prodRes.statusCode == 200) {
      final List prods = jsonDecode(prodRes.body);
      print('Upserting ${prods.length} products...');
      await (await _dbHelper.database).transaction((txn) async {
        for (var prod in prods) {
          await _dbHelper.upsertProduct(prod, txn);
        }
      });
      await Future.delayed(Duration.zero);
    }

    // Pull Expenses
    print('Pulling Expenses...');
    final expRes = await http.get(Uri.parse('$targetUrl/expenses'), headers: headers).timeout(const Duration(seconds: 30));
    if (expRes.statusCode == 200) {
      final List exps = jsonDecode(expRes.body);
      print('Upserting ${exps.length} expenses...');
      await (await _dbHelper.database).transaction((txn) async {
        for (var exp in exps) {
          await _dbHelper.upsertExpense(exp, txn);
        }
      });
      await Future.delayed(Duration.zero);
    }

    // Pull Staff
    print('Pulling Staff...');
    final staffRes = await http.get(Uri.parse('$targetUrl/staff'), headers: headers).timeout(const Duration(seconds: 30));
    if (staffRes.statusCode == 200) {
      final List staffList = jsonDecode(staffRes.body);
      print('Upserting ${staffList.length} staff...');
      await (await _dbHelper.database).transaction((txn) async {
        for (var s in staffList) {
          await _dbHelper.upsertStaff(s, txn);
        }
      });
      await Future.delayed(Duration.zero);
    }

    // Pull Sales
    print('Pulling Sales...');
    final saleRes = await http.get(Uri.parse('$targetUrl/sales'), headers: headers).timeout(const Duration(seconds: 60));
    if (saleRes.statusCode == 200) {
      final List salesList = jsonDecode(saleRes.body);
      print('Upserting ${salesList.length} sales...');
      await (await _dbHelper.database).transaction((txn) async {
        for (var sale in salesList) {
          await _dbHelper.upsertSale(sale, txn);
        }
      });
      await Future.delayed(Duration.zero);
    }

    // Pull Settings
    await pullSettings(targetToken, targetUrl);
    print('Cloud Pull Completed!');
  }

  Future<void> pullSettings([String? token, String? url]) async {
    final targetUrl = url ?? baseUrl;
    final targetToken = token ?? authToken;
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (targetToken != null) 'Authorization': 'Bearer $targetToken',
    };

    try {
      print('Pulling Shop Settings...');
      final res = await http.get(Uri.parse('$targetUrl/settings'), headers: headers).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        // Map backend keys to local database keys
        await _dbHelper.upsertShopSettings({
          'name': data['store_name'],
          'address': data['store_address'],
          'phone': data['store_phone'],
          'email': data['store_email'],
          'footer_message': data['receipt_message'],
          'currency_symbol': data['currency_symbol'],
          'tax_rate': data['tax_rate']?.toDouble(),
          'is_dark_mode': (data['is_dark_mode'] == 1 || data['is_dark_mode'] == true) ? 1 : 0,
          'language_code': data['language_code'],
          'is_pro_unlocked': (data['is_pro'] == 1 || data['is_pro'] == true) ? 1 : 0,
          'mmqr_image_path': data['mmqr_image_url'],
          'uuid': data['uuid'],
          'updated_at': data['updated_at'],
        });
        print('Shop Settings Updated from Cloud.');
      }
    } catch (e) {
      print('Pull settings error: $e');
    }
  }
}
