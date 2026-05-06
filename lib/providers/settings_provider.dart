import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/shop_settings.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import '../services/api_service.dart';
import '../services/backup_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SettingsProvider with ChangeNotifier {
  ShopSettings _settings = ShopSettings();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  ShopSettings get settings => _settings;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool get isDarkMode => _settings.isDarkMode;
  String get languageCode => _settings.languageCode;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> fetchSettings() async {
    final Map<String, dynamic> map = await _dbHelper.getShopSettings();
    _settings = ShopSettings.fromMap(map);

    // Sync with .env if different (allows user to change IP in .env easily)
    final envUrl = dotenv.get('API_URL', fallback: '');
    if (envUrl.isNotEmpty && _settings.apiBaseUrl != envUrl) {
      _settings = _settings.copyWith(apiBaseUrl: envUrl);
      await updateSettings(_settings);
      debugPrint('Auto-updated apiBaseUrl from .env: $envUrl');
    }

    _isLoaded = true;
    notifyListeners();

    // Initialize Auto-Sync
    if (_settings.isLoggedIn && _settings.cloudToken != null) {
      SyncService(baseUrl: _settings.apiBaseUrl, authToken: _settings.cloudToken)
          .initializeAutoSync(_settings);
      
      // Auto-refresh PRO status in background on startup
      refreshProStatus();
    }
  }

  Future<void> updateSettings(ShopSettings newSettings) async {
    await _dbHelper.updateShopSettings(newSettings.toMap());
    _settings = newSettings;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final newSettings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await updateSettings(newSettings);
  }

  Future<void> setLanguage(String code) async {
    final newSettings = _settings.copyWith(languageCode: code);
    await updateSettings(newSettings);
  }

  Future<int> getUnsyncedSalesCount() async {
    return await _dbHelper.getUnsyncedCount('sales');
  }

  Future<void> updateBackupInterval(String interval) async {
    final newSettings = _settings.copyWith(autoBackupInterval: interval);
    await updateSettings(newSettings);
  }


  Future<void> triggerBackup() async {
    await BackupService.exportBackup();
    final now = DateTime.now().toIso8601String();
    final newSettings = _settings.copyWith(lastBackupDate: now);
    await updateSettings(newSettings);
  }

  Future<void> updateMMQRImagePath(String path) async {
    final newSettings = _settings.copyWith(mmqrImagePath: path);
    await updateSettings(newSettings);
  }

  Future<void> refreshProStatus() async {
    if (!_settings.isLoggedIn || _settings.cloudToken == null) return;
    
    try {
      final api = ApiService(baseUrl: _settings.apiBaseUrl);
      final response = await api.get('/user', headers: {
        'Authorization': 'Bearer ${_settings.cloudToken}',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isPro = data['is_pro'] == 1 || data['is_pro'] == true;
        final proExpiresAt = data['pro_expires_at'];
        
        final newSettings = _settings.copyWith(
          isProUnlocked: isPro,
          proExpiresAt: proExpiresAt,
        );
        await updateSettings(newSettings);
      }
    } catch (e) {
      debugPrint('Failed to refresh PRO status: $e');
    }
  }

  Future<String?> syncNow() async {
    if (!_settings.isLoggedIn || _settings.cloudToken == null) return "Not logged in";
    
    _isSyncing = true;
    notifyListeners();

    try {
      final error = await SyncService(
        baseUrl: _settings.apiBaseUrl, 
        authToken: _settings.cloudToken
      ).syncAll(_settings);
      
      if (error == null) {
        _lastSyncTime = DateTime.now();
        await fetchSettings();
      }
      
      _isSyncing = false;
      notifyListeners();
      return error;
    } catch (e) {
      debugPrint('Sync failed: $e');
      _isSyncing = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> resetSyncAndSyncNow() async {
    await _dbHelper.resetSyncStatuses();
    return await syncNow();
  }

  static const String _googleWebClientId = '135543725732-2mjnhgr45bc8ofih583c1a8slp90uhsj.apps.googleusercontent.com';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleWebClientId,
    scopes: ['email', 'profile'],
  );

  Future<String?> loginWithGoogle(String baseUrl) async {
    try {
      // Force account selection by signing out from any previous session first
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Google sign-in canceled';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) return 'Failed to get ID token from Google';

      final deviceInfo = DeviceInfoPlugin();
      String deviceName = "Android Device";
      try {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = "${androidInfo.brand} ${androidInfo.model}";
      } catch (_) {}

      final api = ApiService(baseUrl: baseUrl);
      final response = await api.post('/auth/google', {
        'idToken': idToken,
        'device_name': deviceName,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final email = data['user']['email'];
        final isPro = data['user']['is_pro'] == 1 || data['user']['is_pro'] == true;
        final proExpiresAt = data['user']['pro_expires_at'];
        
        await login(email, token, baseUrl, isPro, proExpiresAt);
        
        // Initial Pull from Cloud (PRO only)
        if (isPro) {
          await SyncService(baseUrl: baseUrl, authToken: token).pullAll();
        }
        
        return null; // Success
      } else {
        try {
          final data = jsonDecode(response.body);
          return data['message'] ?? 'Google backend verification failed (${response.statusCode})';
        } catch (_) {
          return 'Server error (${response.statusCode}): ${response.body}';
        }
      }
    } catch (e) {
      return 'Google login error: $e';
    }
  }

  Future<void> login(String email, String token, String baseUrl, bool isPro, [String? proExpiresAt]) async {
    // CRITICAL: Clear any existing local data from a previous user before logging in
    await _dbHelper.clearAllData();

    final newSettings = _settings.copyWith(
      cloudToken: token,
      cloudUserEmail: email,
      isLoggedIn: true,
      apiBaseUrl: baseUrl,
      isProUnlocked: isPro,
      proExpiresAt: proExpiresAt,
    );
    await updateSettings(newSettings);
  }

  Future<void> logout() async {
    // CRITICAL: Clear all personal/shop data to ensure privacy between different accounts
    await _dbHelper.clearAllData();
    
    // Reset settings to default
    final defaultSettings = ShopSettings();
    _settings = defaultSettings;
    await _dbHelper.updateShopSettings(defaultSettings.toMap());

    // Also sign out from Google
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    
    notifyListeners();
  }

  Future<void> resetApp() async {
    await _dbHelper.clearAllData();
    // Also reset settings to default
    final defaultSettings = ShopSettings();
    await updateSettings(defaultSettings);
    _isLoaded = false;
    await fetchSettings();
  }

  Future<void> runAutoBackupCheck() async {
    if (!_isLoaded) return;
    
    // Simple logic: check if we should backup based on interval
    await BackupService.checkAndRunAutoBackup(_settings.autoBackupInterval, _settings.lastBackupDate);
  }

  Future<void> exportOfflineBackup() async {
    await BackupService.exportBackup();
  }

  Future<bool> importOfflineBackup() async {
    final success = await BackupService.restoreBackup();
    if (success) {
      _isLoaded = false;
      await fetchSettings();
      notifyListeners();
    }
    return success;
  }

  String l10n(String key) {
    if (_settings.languageCode == 'my') {
      return _mmTranslations[key] ?? key;
    }
    return _enTranslations[key] ?? key;
  }


  static const Map<String, String> _enTranslations = {
    'dashboard': 'Dashboard',
    'products': 'Products',
    'sale': 'Sale',
    'history': 'History',
    'settings': 'Settings',
    'overview': 'Overview',
    'revenue': 'Revenue',
    'profit': 'Profit',
    'transactions': 'Transactions',
    'instock_worth': 'In-stock Worth',
    'top_selling': 'Top Selling Products',
    'top_selling_daily': 'Top Selling (Daily)',
    'top_selling_weekly': 'Top Selling (Weekly)',
    'top_selling_monthly': 'Top Selling (Monthly)',
    'sales_trend': 'Sales Trend',
    'daily': 'Daily',
    'weekly': 'Weekly',
    'monthly': 'Monthly',
    'new_sale': 'New Sale',
    'dark_mode': 'Dark Mode',
    'language': 'Language',
    'categories': 'Categories',
    'shop_info': 'Shop Information',
    'shop_name': 'Shop Name',
    'address': 'Address',
    'phone': 'Phone',
    'email': 'Email',
    'footer_msg': 'Invoice Footer Message',
    'save_settings': 'Save Settings',
    'product_name': 'Product Name',
    'price': 'Price',
    'cost_price': 'Cost Price',
    'stock': 'Stock',
    'barcode': 'Barcode',
    'threshold': 'Low Stock Alert At',
    'category': 'Category',
    'new_product': 'New Product',
    'edit_product': 'Edit Product',
    'save_product': 'Save Product',
    'new_category': 'New Category',
    'edit_category': 'Edit Category',
    'category_name': 'Category Name',
    'save_category': 'Save Category',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'edit': 'Edit',
    'confirm': 'Confirm',
    'search_product': 'Search product...',
    'out_of_stock': 'Out of stock!',
    'not_found': 'Product not found!',
    'cart_empty': 'Cart is empty',
    'scan_to_begin': 'Scan or search a product to begin',
    'total_amount': 'Total Amount',
    'complete_sale': 'COMPLETE SALE',
    'payment': 'Payment',
    'amount_paid': 'Amount Paid',
    'change': 'Change',
    'confirm_payment': 'Confirm Payment',
    'sale_success': 'Sale Successful',
    'gen_invoice': 'Generate invoice?',
    'view_invoice': 'View Invoice',
    'cash': 'Cash',
    'card': 'Card',
    'other': 'Other',
    'close': 'Close',
    'print_receipt': 'Print Receipt',
    'sale_no': 'Sale #',
    'sale_details': 'Sale Details',
    'no_sale_found': 'No sales record found',
    'refresh_data': 'Refresh Data',
    'premium_edition': 'Premium Edition',
    'backup_restore': 'Cloud Sync & Backup',
    'cloud_backup': 'Back up to Cloud',
    'cloud_restore': 'Restore from Cloud',
    'offline_backup': 'Offline Local Backup',
    'export_db': 'Export Database (.db)',
    'import_db': 'Import Database (.db)',
    'auto_backup': 'Auto Cloud Backup',
    'none': 'None',
    'backup_success': 'Backup successful!',
    'restore_success': 'Restore successful! Please restart the app to apply changes.',
    'restore_fail': 'Restore failed!',
    'reset_app': 'Reset App',
    'danger_zone': 'Danger Zone',
    'confirm_reset_title': 'Reset All Data?',
    'confirm_reset_msg': 'This will delete all products, categories, and sales. Type "delete" to confirm.',
    'mmqr_pay_image': 'MMQR Payment Image',
    'upload_image': 'Upload Image',
    'select_image': 'Select Image',
    'category_management': 'Category Management',
    'manage_categories': 'Manage Categories',
    'mmqr_pay': 'MMQR Pay',
    'expenses': 'Expenses',
    'add_expense': 'Add Expense',
    'expense_title': 'Expense Title',
    'no_expenses_found': 'No expenses found',
    'confirm_delete': 'Are you sure you want to delete this?',
    'customer_name': 'Customer Name',
    'optional': 'optional',
    'low_stock_alerts': 'Low Stock Alerts',
    'items_low_stock': 'items are low in stock',
    'view_all': 'View All',
  };

  static const Map<String, String> _mmTranslations = {
    'dashboard': 'ပင်မစာမျက်နှာ',
    'products': 'ကုန်ပစ္စည်းများ',
    'sale': 'အရောင်း',
    'history': 'မှတ်တမ်း',
    'settings': 'ဆက်တင်များ',
    'overview': 'ခြုံငုံသုံးသပ်ချက်',
    'revenue': 'စုစုပေါင်းရောင်းရငွေ',
    'profit': 'အမြတ်',
    'transactions': 'အရောင်းအဝယ်အရေအတွက်',
    'instock_worth': 'လက်ကျန်ပစ္စည်းတန်ဖိုး',
    'top_selling': 'အရောင်းရဆုံးပစ္စည်းများ',
    'top_selling_daily': 'ယနေ့အရောင်းရဆုံး',
    'top_selling_weekly': 'ယခုအပတ်အရောင်းရဆုံး',
    'top_selling_monthly': 'ယခုလအရောင်းရဆုံး',
    'sales_trend': 'အရောင်းအလားအလာ',
    'daily': 'နေ့စဉ်',
    'weekly': 'အပတ်စဉ်',
    'monthly': 'လစဉ်',
    'new_sale': 'အရောင်းအသစ်',
    'dark_mode': 'ညဘက်အသုံးပြုမှု',
    'language': 'ဘာသာစကား',
    'categories': 'အမျိုးအစားများ',
    'shop_info': 'ဆိုင်အချက်အလက်',
    'shop_name': 'ဆိုင်အမည်',
    'address': 'လိပ်စာ',
    'phone': 'ဖုန်းနံပါတ်',
    'email': 'အီးမေးလ်',
    'footer_msg': 'ဘောက်ချာအောက်ခြေစာသား',
    'save_settings': 'ဆက်တင်များသိမ်းဆည်းရန်',
    'product_name': 'ကုန်ပစ္စည်းအမည်',
    'price': 'ရောင်းဈေး',
    'cost_price': 'ရင်းဈေး',
    'stock': 'လက်ကျန်အရေအတွက်',
    'barcode': 'ဘာကုတ်',
    'threshold': 'လက်ကျန်နည်းပါကအသိပေးရန်',
    'category': 'အမျိုးအစား',
    'new_product': 'ကုန်ပစ္စည်းအသစ်ထည့်ရန်',
    'edit_product': 'ကုန်ပစ္စည်းပြင်ဆင်ရန်',
    'save_product': 'ကုန်ပစ္စည်းသိမ်းဆည်းရန်',
    'new_category': 'အမျိုးအစားအသစ်',
    'edit_category': 'အမျိုးအစားပြင်ရန်',
    'category_name': 'အမျိုးအစားအမည်',
    'save_category': 'အမျိုးအစားသိမ်းရန်',
    'delete': 'ဖျက်ရန်',
    'cancel': 'မလုပ်တော့ပါ',
    'edit': 'ပြင်ရန်',
    'confirm': 'အတည်ပြုသည်',
    'search_product': 'ပစ္စည်းရှာဖွေရန်...',
    'out_of_stock': 'ပစ္စည်းပြတ်သွားပါပြီ။',
    'not_found': 'ပစ္စည်းရှာမတွေ့ပါ။',
    'cart_empty': 'ဈေးဝယ်ခြင်းတောင်းထဲတွင်ဘာမှမရှိပါ',
    'scan_to_begin': 'စတင်ရန် ပစ္စည်းရှာပါ (သို့) ဘာကုတ်ဖတ်ပါ',
    'total_amount': 'စုစုပေါင်းကျသင့်ငွေ',
    'complete_sale': 'ရောင်းချမှုအပြီးသတ်ရန်',
    'payment': 'ငွေပေးချေမှု',
    'amount_paid': 'ပေးငွေ',
    'change': 'ပြန်အမ်းငွေ',
    'confirm_payment': 'ငွေလက်ခံကြောင်းအတည်ပြုရန်',
    'sale_success': 'ရောင်းချမှုအောင်မြင်ပါသည်',
    'gen_invoice': 'ဘောက်ချာထုတ်ပေးမလား?',
    'view_invoice': 'ဘောက်ချာကြည့်ရန်',
    'cash': 'လက်ငင်းငွေ',
    'card': 'ကတ်ဖြင့်ပေးချေမှု',
    'other': 'အခြား',
    'close': 'ပိတ်ရန်',
    'print_receipt': 'ဘောက်ချာထုတ်ရန်',
    'sale_no': 'ဘောက်ချာအမှတ် #',
    'sale_details': 'အသေးစိတ်အချက်အလက်များ',
    'no_sale_found': 'ရောင်းချမှုမှတ်တမ်းမရှိပါ',
    'refresh_data': 'ဒေတာအသစ်ပြန်ယူရန်',
    'premium_edition': 'ပရီမီယံဗားရှင်း',
    'backup_restore': 'Cloud နှင့် ဒေတာချိတ်ဆက်ခြင်း',
    'cloud_backup': 'Cloud သို့ သိမ်းဆည်းမည်',
    'cloud_restore': 'Cloud မှ ပြန်ယူမည်',
    'offline_backup': 'ဖုန်းအတွင်း သိမ်းဆည်းခြင်း',
    'export_db': 'ဖိုင်အဖြစ် သိမ်းမည် (.db)',
    'import_db': 'ဖိုင်မှ ပြန်သွင်းမည် (.db)',
    'auto_backup': 'အလိုအလျောက် Cloud သိမ်းဆည်းခြင်း',
    'none': 'ပိတ်ထားရန်',
    'backup_success': 'ဒေတာသိမ်းဆည်းမှုအောင်မြင်ပါသည်',
    'restore_success': 'ဒေတာပြန်ယူမှုအောင်မြင်ပါသည်၊ အက်ပ်ကိုပြန်ဖွင့်ပေးပါ။',
    'restore_fail': 'ဒေတာပြန်ယူမှုမအောင်မြင်ပါ',
    'reset_app': 'အက်ပ်ကိုအစမှပြန်စရန်',
    'danger_zone': 'အထူးသတိပြုရန်',
    'confirm_reset_title': 'ဒေတာအားလုံးဖျက်မည်လား?',
    'confirm_reset_msg': 'ကုန်ပစ္စည်းများ၊ ကဏ္ဍများနှင့် အရောင်းမှတ်တမ်းများအားလုံး ပျက်သွားပါမည်။ အတည်ပြုရန် "delete" ဟု ရိုက်ထည့်ပါ။',
    'mmqr_pay_image': 'MMQR ငွေပေးချေမှုပုံစံ',
    'upload_image': 'ပုံတင်ရန်',
    'select_image': 'ပုံရွေးရန်',
    'category_management': 'ကဏ္ဍများစီမံခန့်ခွဲခြင်း',
    'manage_categories': 'ကဏ္ဍများကို စီမံမည်',
    'mmqr_pay': 'MMQR ဖြင့်ပေးချေမည်',
    'expenses': 'အထွေထွေအသုံးစရိတ်များ',
    'add_expense': 'အသုံးစရိတ်အသစ်ထည့်ရန်',
    'expense_title': 'အသုံးစရိတ်ခေါင်းစဉ်',
    'no_expenses_found': 'အသုံးစရိတ်မှတ်တမ်းမရှိပါ',
    'confirm_delete': 'ဤအရာကိုဖျက်ရန်သေချာပါသလား?',
    'customer_name': 'ဝယ်ယူသူအမည်',
    'optional': 'မဖြစ်မနေထည့်ရန်မလိုပါ',
    'low_stock_alerts': 'လက်ကျန်နည်းနေသောပစ္စည်းများ',
    'items_low_stock': 'ခု လက်ကျန်နည်းနေပါသည်',
    'view_all': 'အားလုံးကြည့်ရန်',
  };
}
