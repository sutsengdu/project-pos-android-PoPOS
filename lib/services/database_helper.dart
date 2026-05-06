import 'dart:async';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/staff.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static final _uuid = Uuid();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static const _databaseVersion = 10;

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    return await openDatabase(
      path,
      version: 17,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    // Perform any light setup here
  }

  Future<void> _migrateLegacyData(Database db) async {
    try {
      // Products: cost_price -> cost
      var productsColumns = await db.rawQuery('PRAGMA table_info(products)');
      bool hasCostPrice = productsColumns.any((c) => c['name'] == 'cost_price');
      if (hasCostPrice) {
        await db.execute('UPDATE products SET cost = cost_price WHERE (cost IS NULL OR cost = 0) AND cost_price != 0');
      }

      // Sale Items: unit_price -> price, cost_price -> cost
      var saleItemsColumns = await db.rawQuery('PRAGMA table_info(sale_items)');
      bool hasUnitPrice = saleItemsColumns.any((c) => c['name'] == 'unit_price');
      bool hasItemCostPrice = saleItemsColumns.any((c) => c['name'] == 'cost_price');
      
      if (hasUnitPrice) {
        await db.execute('UPDATE sale_items SET price = unit_price WHERE (price IS NULL OR price = 0) AND unit_price != 0');
      }
      if (hasItemCostPrice) {
        await db.execute('UPDATE sale_items SET cost = cost_price WHERE (cost IS NULL OR cost = 0) AND cost_price != 0');
      }

      debugPrint('Legacy data migration completed successfully');
    } catch (e) {
      debugPrint('Legacy data migration error: $e');
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        uuid TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        remote_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        cost REAL DEFAULT 0.0,
        stock INTEGER NOT NULL,
        category_id INTEGER,
        barcode TEXT,
        image_path TEXT,
        uuid TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        remote_id TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        payment_method TEXT DEFAULT 'Cash',
        amount_paid REAL,
        change_amount REAL,
        customer_name TEXT,
        cashier_name TEXT,
        discount_amount REAL DEFAULT 0.0,
        discount_type TEXT DEFAULT 'fixed',
        tax_rate REAL DEFAULT 0.0,
        uuid TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        remote_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        cost REAL DEFAULT 0.0,
        uuid TEXT,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_settings (
        id INTEGER PRIMARY KEY DEFAULT 0,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        footer_message TEXT,
        tax_rate REAL DEFAULT 0.0,
        currency_symbol TEXT DEFAULT '\$',
        is_dark_mode INTEGER DEFAULT 0,
        language_code TEXT DEFAULT 'en',
        is_pro_unlocked INTEGER DEFAULT 0,
        cloud_token TEXT,
        cloud_user_email TEXT,
        is_logged_in INTEGER DEFAULT 0,
        auto_backup_interval TEXT DEFAULT 'none',
        mmqr_image_path TEXT,
        uuid TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT,
        date TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        staff_name TEXT,
        uuid TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        remote_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        pin TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        uuid TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        remote_id TEXT
      )
    ''');

    // Insert default settings
    await db.insert('shop_settings', {
      'id': 0,
      'name': 'My Shop',
      'is_dark_mode': 0,
      'language_code': 'en',
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN cost REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE sale_items ADD COLUMN cost REAL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE shop_settings ADD COLUMN is_pro_unlocked INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE shop_settings ADD COLUMN cloud_token TEXT');
      await db.execute('ALTER TABLE shop_settings ADD COLUMN cloud_user_email TEXT');
      await db.execute('ALTER TABLE shop_settings ADD COLUMN is_logged_in INTEGER DEFAULT 0');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE shop_settings ADD COLUMN auto_backup_interval TEXT DEFAULT "none"');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE shop_settings ADD COLUMN mmqr_image_path TEXT');
    }
    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT,
            date TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0,
            remote_id TEXT
          )
        ''');
      } catch (e) {}
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE sales ADD COLUMN amount_paid REAL');
      await db.execute('ALTER TABLE sales ADD COLUMN change_amount REAL');
      await db.execute('ALTER TABLE sales ADD COLUMN customer_name TEXT');
      await db.execute('ALTER TABLE sales ADD COLUMN cashier_name TEXT');
    }
    if (oldVersion < 9) {
      try {
        await db.execute('''
          CREATE TABLE staff (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            role TEXT NOT NULL,
            pin TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');
        // Seed initial admin
        await db.insert('staff', {
          'name': 'Owner',
          'role': 'Admin',
          'pin': '0000',
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE expenses ADD COLUMN staff_name TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE staff ADD COLUMN is_synced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE staff ADD COLUMN remote_id TEXT');
      } catch (e) {}
    }

    if (oldVersion < 11 || oldVersion < 12) {
      // Add columns if they don't exist
      var productCols = await db.rawQuery('PRAGMA table_info(products)');
      if (!productCols.any((c) => c['name'] == 'cost')) {
        try { await db.execute('ALTER TABLE products ADD COLUMN cost REAL DEFAULT 0.0'); } catch (e) {}
      }

      var saleItemCols = await db.rawQuery('PRAGMA table_info(sale_items)');
      if (!saleItemCols.any((c) => c['name'] == 'price')) {
        try { await db.execute('ALTER TABLE sale_items ADD COLUMN price REAL DEFAULT 0.0'); } catch (e) {}
      }
      if (!saleItemCols.any((c) => c['name'] == 'cost')) {
        try { await db.execute('ALTER TABLE sale_items ADD COLUMN cost REAL DEFAULT 0.0'); } catch (e) {}
      }

      // Migrate data (cost_price -> cost, unit_price -> price)
      await _migrateLegacyData(db);
    }
    
    if (oldVersion < 13) {
      // Ensure EVERY syncable table has is_synced and remote_id
      final tables = ['products', 'categories', 'sales', 'expenses', 'staff'];
      for (var table in tables) {
        var columns = await db.rawQuery('PRAGMA table_info($table)');
        var names = columns.map((c) => c['name']).toList();
        
        if (!names.contains('is_synced')) {
          try { await db.execute('ALTER TABLE $table ADD COLUMN is_synced INTEGER DEFAULT 0'); } catch (e) {}
        }
        if (!names.contains('remote_id')) {
          try { await db.execute('ALTER TABLE $table ADD COLUMN remote_id TEXT'); } catch (e) {}
        }
      }
    }
    
    if (oldVersion < 14) {
      await db.execute('ALTER TABLE sales ADD COLUMN discount_amount REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE sales ADD COLUMN discount_type TEXT DEFAULT "fixed"');
    }

    if (oldVersion < 15) {
      // Ensure tax_rate exists
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN tax_rate REAL DEFAULT 0.0');
      } catch (e) {}
    }

    if (oldVersion < 16) {
      // One-time final cleanup of legacy columns and data
      final tables = ['products', 'sale_items', 'sales', 'categories', 'expenses', 'staff'];
      for (var table in tables) {
        var columns = await db.rawQuery('PRAGMA table_info($table)');
        var names = columns.map((c) => c['name']).toList();
        
        if (table == 'products' && !names.contains('cost')) {
          try { await db.execute('ALTER TABLE products ADD COLUMN cost REAL DEFAULT 0.0'); } catch (e) {}
        }
        if (table == 'sale_items') {
          if (!names.contains('price')) {
            try { await db.execute('ALTER TABLE sale_items ADD COLUMN price REAL DEFAULT 0.0'); } catch (e) {}
          }
          if (!names.contains('cost')) {
            try { await db.execute('ALTER TABLE sale_items ADD COLUMN cost REAL DEFAULT 0.0'); } catch (e) {}
          }
        }
        if (table == 'sales') {
          if (!names.contains('discount_amount')) {
            try { await db.execute('ALTER TABLE sales ADD COLUMN discount_amount REAL DEFAULT 0.0'); } catch (e) {}
          }
          if (!names.contains('discount_type')) {
            try { await db.execute('ALTER TABLE sales ADD COLUMN discount_type TEXT DEFAULT "fixed"'); } catch (e) {}
          }
          if (!names.contains('tax_rate')) {
            try { await db.execute('ALTER TABLE sales ADD COLUMN tax_rate REAL DEFAULT 0.0'); } catch (e) {}
          }
        }
      }
      await _migrateLegacyData(db);
    }

    if (oldVersion < 17) {
      // Add UUID and Timestamp support
      final tables = ['products', 'categories', 'sales', 'sale_items', 'expenses', 'staff', 'shop_settings'];
      for (var table in tables) {
        var columns = await db.rawQuery('PRAGMA table_info($table)');
        var names = columns.map((c) => c['name']).toList();
        
        if (!names.contains('uuid')) {
          try { await db.execute('ALTER TABLE $table ADD COLUMN uuid TEXT'); } catch (e) {}
        }
        if (!names.contains('updated_at') && table != 'sale_items') {
          try { await db.execute('ALTER TABLE $table ADD COLUMN updated_at TEXT'); } catch (e) {}
        }
      }
      debugPrint('Database upgraded to version 17: Added UUID and Timestamp support.');
    }
  }

  // Category CRUD
  Future<int> insertCategory(Category category) async {
    Database db = await database;
    final map = category.toMap();
    map['uuid'] ??= _uuid.v4();
    map['updated_at'] = DateTime.now().toIso8601String();
    final data = await _getValidMap('categories', map);
    return await db.insert('categories', data);
  }

  Future<List<Category>> getCategories() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> updateCategory(Category category) async {
    Database db = await database;
    final map = category.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    final data = await _getValidMap('categories', map);
    data['is_synced'] = 0;
    return await db.update(
      'categories',
      data,
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    Database db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Category?> getCategoryById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  // Product CRUD
  Future<int> insertProduct(Product product) async {
    Database db = await database;
    final map = product.toMap();
    map['uuid'] ??= _uuid.v4();
    map['updated_at'] = DateTime.now().toIso8601String();
    final data = await _getValidMap('products', map);
    return await db.insert('products', data);
  }

  Future<List<Product>> getProducts() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    Database db = await database;
    final map = product.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    final data = await _getValidMap('products', map);
    data['is_synced'] = 0;
    return await db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    Database db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sale CRUD
  Future<int> insertSale(Sale sale, List<SaleItem> items) async {
    Database db = await database;
    return await db.transaction((txn) async {
      final map = sale.toMap();
      map['uuid'] ??= _uuid.v4();
      map['updated_at'] = DateTime.now().toIso8601String();
      final saleData = await _getValidMap('sales', map, txn);
      int saleId = await txn.insert('sales', saleData);
      
      for (var item in items) {
        // Get current product to get its cost price
        final List<Map<String, dynamic>> productMaps = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        double currentCost = 0.0;
        if (productMaps.isNotEmpty) {
          currentCost = (productMaps.first['cost'] ?? productMaps.first['cost_price'])?.toDouble() ?? 0.0;
        }

        final itemMap = item.toMap();
        itemMap['sale_id'] = saleId;
        itemMap['cost'] = currentCost;
        itemMap['uuid'] ??= _uuid.v4();
        
        final itemData = await _getValidMap('sale_items', itemMap, txn);
        await txn.insert('sale_items', itemData);
        
        // Update stock
        await txn.execute(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      return saleId;
    });
  }

  Future<Sale?> getSaleById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sales', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Sale.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteSale(int id) async {
    Database db = await database;
    return await db.transaction((txn) async {
      // First delete associated items
      await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [id]);
      // Then delete the sale itself
      return await txn.delete('sales', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Sale>> getSales() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sales', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) => Sale.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getSaleDetails(int saleId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT si.*, p.name as product_name, p.remote_id as product_remote_id, p.uuid as product_uuid
      FROM sale_items si
      LEFT JOIN products p ON si.product_id = p.id
      WHERE si.sale_id = ?
    ''', [saleId]);
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime start, DateTime end) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT p.name, SUM(si.quantity) as total_qty
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      JOIN sales s ON si.sale_id = s.id
      WHERE s.timestamp BETWEEN ? AND ?
      GROUP BY p.id
      ORDER BY total_qty DESC
      LIMIT 5
    ''', [start.toIso8601String(), end.toIso8601String()]);
  }

  Future<double> getProfit(DateTime start, DateTime end) async {
    Database db = await database;
    final List<Map<String, dynamic>> saleResult = await db.rawQuery('''
      SELECT SUM(si.quantity * (si.price - si.cost)) as total_profit
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      WHERE s.timestamp BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    double saleProfit = saleResult.first['total_profit']?.toDouble() ?? 0.0;

    // Subtract expenses from total profit
    final List<Map<String, dynamic>> expenseResult = await db.rawQuery('''
      SELECT SUM(amount) as total_expenses
      FROM expenses
      WHERE timestamp BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    double totalExpenses = expenseResult.first['total_expenses']?.toDouble() ?? 0.0;
    
    return saleProfit - totalExpenses;
  }

  // Expense CRUD
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    Database db = await database;
    final map = Map<String, dynamic>.from(expense);
    map['uuid'] ??= _uuid.v4();
    map['updated_at'] = DateTime.now().toIso8601String();
    final data = await _getValidMap('expenses', map);
    return await db.insert('expenses', data);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    Database db = await database;
    return await db.query('expenses', orderBy: 'timestamp DESC');
  }

  Future<int> deleteExpense(int id) async {
    Database db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    Database db = await database;
    await db.transaction((txn) async {
      await txn.delete('expenses');
      await txn.delete('sale_items');
      await txn.delete('sales');
      await txn.delete('products');
      await txn.delete('categories');
      await txn.delete('staff');
      await txn.delete('shop_settings');
    });
  }

  // Shop Settings
  Future<Map<String, dynamic>> getShopSettings() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shop_settings', where: 'id = 0');
    if (maps.isEmpty) {
      // Create default if missing
      final defaultData = {
        'id': 0,
        'name': 'PoPOS Shop',
        'uuid': _uuid.v4(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await db.insert('shop_settings', defaultData);
      return defaultData;
    }
    return maps.first;
  }

  Future<int> updateShopSettings(Map<String, dynamic> settings) async {
    Database db = await database;
    final map = Map<String, dynamic>.from(settings);
    map['uuid'] ??= _uuid.v4();
    map['updated_at'] = DateTime.now().toIso8601String();
    final data = await _getValidMap('shop_settings', map);
    // Note: shop_settings might not have an is_synced column in the current schema, 
    // but the updateShopSettings usually doesn't need it if it's not synced via normal SyncService.
    return await db.update('shop_settings', data, where: 'id = 0');
  }

  Future<void> upsertShopSettings(Map<String, dynamic> map, [DatabaseExecutor? executor]) async {
    DatabaseExecutor db = executor ?? await database;
    final data = await _getValidMap('shop_settings', map, db);
    final remoteUpdatedAt = data['updated_at'] != null ? DateTime.tryParse(data['updated_at'].toString()) : null;

    final res = await db.query('shop_settings', where: 'id = 0');
    if (res.isNotEmpty) {
      final localUpdatedAt = res.first['updated_at'] != null ? DateTime.tryParse(res.first['updated_at'].toString()) : null;
      if (remoteUpdatedAt == null || localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt)) {
        await db.update('shop_settings', data, where: 'id = 0');
      }
    } else {
      await db.insert('shop_settings', data..['id'] = 0);
    }
  }

  // Sync Helpers
  Future<int> getUnsyncedCount(String table) async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM $table WHERE is_synced = 0');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getUnsynced(String table) async {
    Database db = await database;
    try {
      return await db.query(table, where: 'is_synced = 0');
    } catch (e) {
      debugPrint('getUnsynced error for $table: $e');
      return [];
    }
  }

  Future<void> markAsSynced(String table, int localId, String remoteId) async {
    Database db = await database;
    final data = await _getValidMap(table, {'is_synced': 1, 'remote_id': remoteId});
    await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> resetSyncStatuses() async {
    Database db = await database;
    await db.update('products', {'is_synced': 0});
    await db.update('categories', {'is_synced': 0});
    await db.update('sales', {'is_synced': 0});
    await db.update('expenses', {'is_synced': 0});
    await db.update('staff', {'is_synced': 0});
  }

  // Staff CRUD
  Future<int> insertStaff(Staff staff) async {
    Database db = await database;
    final data = await _getValidMap('staff', staff.toMap());
    return await db.insert('staff', data);
  }

  Future<List<Staff>> getStaff() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('staff');
    return List.generate(maps.length, (i) => Staff.fromMap(maps[i]));
  }

  Future<int> updateStaff(Staff staff) async {
    Database db = await database;
    final map = staff.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    final data = await _getValidMap('staff', map);
    data['is_synced'] = 0;
    return await db.update(
      'staff',
      data,
      where: 'id = ?',
      whereArgs: [staff.id],
    );
  }

  Future<int> deleteStaff(int id) async {
    Database db = await database;
    return await db.delete('staff', where: 'id = ?', whereArgs: [id]);
  }

  Future<Staff?> loginStaff(String pin) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'staff',
      where: 'pin = ? AND is_active = 1',
      whereArgs: [pin],
    );
    if (maps.isNotEmpty) {
      return Staff.fromMap(maps.first);
    }
    return null;
  }

  // Helper to filter map keys based on actual table columns
  Future<Map<String, dynamic>> _getValidMap(String table, Map<String, dynamic> data, [DatabaseExecutor? executor]) async {
    DatabaseExecutor db = executor ?? await database;
    var columns = await db.rawQuery('PRAGMA table_info($table)');
    Set<String> tableCols = columns.map((c) => c['name'].toString()).toSet();
    
    Map<String, dynamic> filtered = {};
    
    // Map of new keys to legacy keys
    Map<String, String> legacyMapping = {
      'price': 'unit_price',
      'cost': 'cost_price',
    };

    data.forEach((key, value) {
      // 1. If the key exists in the table, add it
      if (tableCols.contains(key)) {
        filtered[key] = value;
      }
      
      // 2. Dual-Column Mapping: Satisfaction of NOT NULL constraints
      // If we have 'price', and the table has 'unit_price', fill 'unit_price' too
      // If we have 'cost', and the table has 'cost_price', fill 'cost_price' too
      if (legacyMapping.containsKey(key)) {
        String legacyKey = legacyMapping[key]!;
        if (tableCols.contains(legacyKey)) {
          filtered[legacyKey] = value;
        }
      }

      // 3. Reverse Mapping: If data has a legacy key ('unit_price'), but table only has 'price'
      legacyMapping.forEach((newK, legacyK) {
        if (key == legacyK && tableCols.contains(newK) && !filtered.containsKey(newK)) {
          filtered[newK] = value;
        }
      });
    });
    
    return filtered;
  }

  Future<void> upsertCategory(Map<String, dynamic> map, [DatabaseExecutor? executor]) async {
    DatabaseExecutor db = executor ?? await database;
    final remoteId = (map['remote_id'] ?? map['id'])?.toString();
    if (remoteId == null) return;
    
    final data = await _getValidMap('categories', Map.from(map)..remove('id')..['is_synced'] = 1..['remote_id'] = remoteId, db);
    final remoteUpdatedAt = data['updated_at'] != null ? DateTime.tryParse(data['updated_at'].toString()) : null;

    final res = await db.query('categories', where: 'remote_id = ?', whereArgs: [remoteId]);
    if (res.isEmpty) {
      // Prevent duplicates by checking name if no remote_id match
      // Better name matching: prioritize UUID/remote_id, but avoid duplicate names
      final nameMatch = await db.query('categories', where: 'LOWER(name) = ?', whereArgs: [data['name'].toString().toLowerCase()]);
      if (nameMatch.isNotEmpty) {
        await db.update('categories', data, where: 'id = ?', whereArgs: [nameMatch.first['id']]);
      } else {
        await db.insert('categories', data);
      }
    } else {
      // Resolve conflict: check if remote is newer
      final localUpdatedAt = res.first['updated_at'] != null ? DateTime.tryParse(res.first['updated_at'].toString()) : null;
      if (remoteUpdatedAt == null || localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt)) {
        await db.update('categories', data, where: 'remote_id = ?', whereArgs: [remoteId]);
      }
    }
  }

  Future<void> upsertProduct(Map<String, dynamic> map, [DatabaseExecutor? executor]) async {
    DatabaseExecutor db = executor ?? await database;
    final remoteId = (map['remote_id'] ?? map['id'])?.toString();
    if (remoteId == null) return;

    final data = await _getValidMap('products', Map.from(map)..remove('id')..['is_synced'] = 1..['remote_id'] = remoteId, db);
    final remoteUpdatedAt = data['updated_at'] != null ? DateTime.tryParse(data['updated_at'].toString()) : null;

    // Resolve local category_id from remote category_id
    if (data['category_id'] != null) {
      final remoteCatId = data['category_id'].toString();
      final catRes = await db.query('categories', where: 'remote_id = ?', whereArgs: [remoteCatId]);
      if (catRes.isNotEmpty) {
        data['category_id'] = catRes.first['id'];
      } else {
        data['category_id'] = null; // Important: avoid using remote_id as local_id
      }
    }

    final res = await db.query('products', where: 'remote_id = ?', whereArgs: [remoteId]);
    if (res.isEmpty) {
      // Strict name/barcode matching to prevent duplicates even if remote_id differs
      final name = data['name'].toString();
      final barcode = data['barcode']?.toString();
      
      List<Map<String, dynamic>> match = [];
      if (barcode != null && barcode.isNotEmpty && barcode != 'NO-BARCODE') {
        match = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
      }
      
      if (match.isEmpty) {
        match = await db.query('products', where: 'LOWER(name) = ?', whereArgs: [name.toLowerCase()]);
      }

      if (match.isNotEmpty) {
        // Collapse/Update existing local record instead of creating duplicate
        await db.update('products', data, where: 'id = ?', whereArgs: [match.first['id']]);
      } else {
        await db.insert('products', data);
      }
    } else {
      final localUpdatedAt = res.first['updated_at'] != null ? DateTime.tryParse(res.first['updated_at'].toString()) : null;
      if (remoteUpdatedAt == null || localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt)) {
        await db.update('products', data, where: 'remote_id = ?', whereArgs: [remoteId]);
      }
    }
  }

  Future<void> upsertExpense(Map<String, dynamic> map, [DatabaseExecutor? executor]) async {
    DatabaseExecutor db = executor ?? await database;
    final remoteId = (map['remote_id'] ?? map['id'])?.toString();
    if (remoteId == null) return;

    final data = await _getValidMap('expenses', Map.from(map)..remove('id')..['is_synced'] = 1..['remote_id'] = remoteId, db);
    final remoteUpdatedAt = data['updated_at'] != null ? DateTime.tryParse(data['updated_at'].toString()) : null;

    final res = await db.query('expenses', where: 'remote_id = ?', whereArgs: [remoteId]);
    if (res.isEmpty) {
      await db.insert('expenses', data);
    } else {
      final localUpdatedAt = res.first['updated_at'] != null ? DateTime.tryParse(res.first['updated_at'].toString()) : null;
      if (remoteUpdatedAt == null || localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt)) {
        await db.update('expenses', data, where: 'remote_id = ?', whereArgs: [remoteId]);
      }
    }
  }

  // Update insertCategory to be cleaner
  // (DELETED DUPLICATE)

  Future<void> upsertStaff(Map<String, dynamic> map, [DatabaseExecutor? executor]) async {
    DatabaseExecutor db = executor ?? await database;
    final remoteId = (map['remote_id'] ?? map['id'])?.toString();
    if (remoteId == null) return;

    final data = await _getValidMap('staff', Map.from(map)..remove('id')..['is_synced'] = 1..['remote_id'] = remoteId, db);
    final remoteUpdatedAt = data['updated_at'] != null ? DateTime.tryParse(data['updated_at'].toString()) : null;

    final res = await db.query('staff', where: 'remote_id = ?', whereArgs: [remoteId]);
    if (res.isEmpty) {
      await db.insert('staff', data);
    } else {
      final localUpdatedAt = res.first['updated_at'] != null ? DateTime.tryParse(res.first['updated_at'].toString()) : null;
      if (remoteUpdatedAt == null || localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt)) {
        await db.update('staff', data, where: 'remote_id = ?', whereArgs: [remoteId]);
      }
    }
  }

  Future<void> upsertSale(Map<String, dynamic> map, [DatabaseExecutor? executor]) async {
    DatabaseExecutor db = executor ?? await database;
    final remoteId = map['remote_id'] ?? map['id'];
    if (remoteId == null) return;

    // Filter main sale data
    final saleData = await _getValidMap('sales', Map.from(map)..remove('id')..['is_synced'] = 1, db);
    saleData['remote_id'] = remoteId.toString();

    int localSaleId;
    final res = await db.query('sales', where: 'remote_id = ?', whereArgs: [remoteId.toString()]);
    
    if (res.isEmpty) {
      localSaleId = await db.insert('sales', saleData);
    } else {
      localSaleId = res.first['id'] as int;
      await db.update('sales', saleData, where: 'id = ?', whereArgs: [localSaleId]);
    }

    // Handle Sale Items
    if (map['items'] != null && map['items'] is List) {
      // Clear existing items for this sale to avoid duplicates or orphaned items
      await db.delete('sale_items', where: 'sale_id = ?', whereArgs: [localSaleId]);
      
      for (var item in map['items']) {
        final itemMap = Map<String, dynamic>.from(item);
        itemMap['sale_id'] = localSaleId;
        
        // Resolve internal product_id from remote_product_id if possible
        final remoteProductId = item['product_id'] ?? item['remote_id'];
        if (remoteProductId != null) {
          final prodRes = await db.query('products', where: 'remote_id = ?', whereArgs: [remoteProductId.toString()]);
          if (prodRes.isNotEmpty) {
            itemMap['product_id'] = prodRes.first['id'];
            final validItemData = await _getValidMap('sale_items', itemMap, db);
            await db.insert('sale_items', validItemData);
          } else {
            print('Warning: Product with remote_id $remoteProductId not found for sale $remoteId. Skipping item.');
          }
        }
      }
    }
  }
}
