import 'package:flutter/material.dart';
import '../models/shop_settings.dart';
import '../services/database_helper.dart';
import '../services/backup_service.dart';

class SettingsProvider with ChangeNotifier {
  ShopSettings _settings = ShopSettings();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  ShopSettings get settings => _settings;

  bool get isDarkMode => _settings.isDarkMode;
  String get languageCode => _settings.languageCode;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> fetchSettings() async {
    final Map<String, dynamic> map = await _dbHelper.getShopSettings();
    _settings = ShopSettings.fromMap(map);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> updateSettings(ShopSettings newSettings) async {
    await _dbHelper.updateShopSettings(newSettings.toMap());
    _settings = newSettings;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final newSettings = ShopSettings(
      name: _settings.name,
      address: _settings.address,
      phone: _settings.phone,
      email: _settings.email,
      footerMessage: _settings.footerMessage,
      isDarkMode: !_settings.isDarkMode,
      languageCode: _settings.languageCode,
      autoBackupInterval: _settings.autoBackupInterval,
      lastBackupDate: _settings.lastBackupDate,
      mmqrImagePath: _settings.mmqrImagePath,
    );
    await updateSettings(newSettings);
  }

  Future<void> setLanguage(String code) async {
    final newSettings = ShopSettings(
      name: _settings.name,
      address: _settings.address,
      phone: _settings.phone,
      email: _settings.email,
      footerMessage: _settings.footerMessage,
      isDarkMode: _settings.isDarkMode,
      languageCode: code,
      autoBackupInterval: _settings.autoBackupInterval,
      lastBackupDate: _settings.lastBackupDate,
      mmqrImagePath: _settings.mmqrImagePath,
    );
    await updateSettings(newSettings);
  }

  Future<void> updateBackupInterval(String interval) async {
    final newSettings = ShopSettings(
      name: _settings.name,
      address: _settings.address,
      phone: _settings.phone,
      email: _settings.email,
      footerMessage: _settings.footerMessage,
      isDarkMode: _settings.isDarkMode,
      languageCode: _settings.languageCode,
      autoBackupInterval: interval,
      lastBackupDate: _settings.lastBackupDate,
      mmqrImagePath: _settings.mmqrImagePath,
    );
    await updateSettings(newSettings);
  }

  Future<void> triggerBackup() async {
    await BackupService.exportBackup();
    final now = DateTime.now().toIso8601String();
    final newSettings = ShopSettings(
      name: _settings.name,
      address: _settings.address,
      phone: _settings.phone,
      email: _settings.email,
      footerMessage: _settings.footerMessage,
      isDarkMode: _settings.isDarkMode,
      languageCode: _settings.languageCode,
      autoBackupInterval: _settings.autoBackupInterval,
      lastBackupDate: now,
      mmqrImagePath: _settings.mmqrImagePath,
    );
    await updateSettings(newSettings);
  }

  Future<void> updateMMQRImagePath(String path) async {
    final newSettings = ShopSettings(
      name: _settings.name,
      address: _settings.address,
      phone: _settings.phone,
      email: _settings.email,
      footerMessage: _settings.footerMessage,
      isDarkMode: _settings.isDarkMode,
      languageCode: _settings.languageCode,
      autoBackupInterval: _settings.autoBackupInterval,
      lastBackupDate: _settings.lastBackupDate,
      mmqrImagePath: path,
    );
    await updateSettings(newSettings);
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
    'backup_restore': 'Backup & Restore',
    'manual_backup': 'Manual Backup (Export)',
    'manual_restore': 'Manual Restore (Import)',
    'auto_backup': 'Automatic Backup',
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
    'backup_restore': 'ဒေတာသိမ်းဆည်းခြင်းနှင့်ပြန်ယူခြင်း',
    'manual_backup': 'ဒေတာသိမ်းဆည်းရန် (Backup)',
    'manual_restore': 'ဒေတာပြန်ယူရန် (Restore)',
    'auto_backup': 'အလိုအလျောက်ဒေတာသိမ်းဆည်းခြင်း',
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
  };
}
