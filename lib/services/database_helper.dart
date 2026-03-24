import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        price REAL NOT NULL,
        cost_price REAL NOT NULL,
        stock INTEGER NOT NULL,
        barcode TEXT,
        low_stock_threshold INTEGER DEFAULT 5,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        payment_method TEXT DEFAULT "Cash",
        amount_paid REAL DEFAULT 0.0,
        change_amount REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER,
        product_id INTEGER,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_settings (
        id INTEGER PRIMARY KEY CHECK (id = 0),
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        footer_message TEXT,
        is_dark_mode INTEGER DEFAULT 0,
        language_code TEXT DEFAULT 'en',
        auto_backup_interval TEXT DEFAULT 'none',
        last_backup_date TEXT,
        mmqr_image_path TEXT
      )
    ''');

    await db.insert('shop_settings', {
      'id': 0,
      'name': 'My POS Shop',
      'address': '',
      'phone': '',
      'email': '',
      'footer_message': 'Thank you for your business!',
      'is_dark_mode': 0,
      'language_code': 'en',
      'auto_backup_interval': 'none',
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sales ADD COLUMN payment_method TEXT DEFAULT "Cash"');
      await db.execute('ALTER TABLE sales ADD COLUMN amount_paid REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE sales ADD COLUMN change_amount REAL DEFAULT 0.0');

      await db.execute('''
        CREATE TABLE shop_settings (
          id INTEGER PRIMARY KEY CHECK (id = 0),
          name TEXT NOT NULL,
          address TEXT,
          phone TEXT,
          email TEXT,
          footer_message TEXT
        )
      ''');

      await db.insert('shop_settings', {
        'id': 0,
        'name': 'My POS Shop',
        'address': '',
        'phone': '',
        'email': '',
        'footer_message': 'Thank you for your business!',
        'is_dark_mode': 0,
        'language_code': 'en',
      });
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE shop_settings ADD COLUMN is_dark_mode INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE shop_settings ADD COLUMN language_code TEXT DEFAULT "en"');
      } catch (e) {
        // Column might exist
      }
    }

    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE shop_settings ADD COLUMN auto_backup_interval TEXT DEFAULT 'none'");
        await db.execute("ALTER TABLE shop_settings ADD COLUMN last_backup_date TEXT");
      } catch (e) {
      }
    }

    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE shop_settings ADD COLUMN mmqr_image_path TEXT");
      } catch (e) {
        // Column might exist
      }
    }
  }

  // Category CRUD
  Future<int> insertCategory(Category category) async {
    Database db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> updateCategory(Category category) async {
    Database db = await database;
    return await db.update(
      'categories',
      category.toMap(),
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

  // Product CRUD
  Future<int> insertProduct(Product product) async {
    Database db = await database;
    return await db.insert('products', product.toMap());
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
    return await db.update(
      'products',
      product.toMap(),
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
      int saleId = await txn.insert('sales', sale.toMap());
      for (var item in items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
        });
        
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
      SELECT si.*, p.name as product_name 
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
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
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SUM(si.quantity * (si.unit_price - p.cost_price)) as total_profit
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      JOIN sales s ON si.sale_id = s.id
      WHERE s.timestamp BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    return result.first['total_profit']?.toDouble() ?? 0.0;
  }

  Future<void> clearAllData() async {
    Database db = await database;
    await db.transaction((txn) async {
      await txn.delete('sale_items');
      await txn.delete('sales');
      await txn.delete('products');
      await txn.delete('categories');
    });
  }

  // Shop Settings
  Future<Map<String, dynamic>> getShopSettings() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shop_settings', where: 'id = 0');
    return maps.first;
  }

  Future<int> updateShopSettings(Map<String, dynamic> settings) async {
    Database db = await database;
    return await db.update('shop_settings', settings, where: 'id = 0');
  }
}
