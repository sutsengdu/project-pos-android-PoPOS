import 'package:flutter_dotenv/flutter_dotenv.dart';

class ShopSettings {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String footerMessage;
  final bool isDarkMode;
  final String languageCode;
  final String autoBackupInterval; // 'none', 'daily', 'weekly', 'monthly'
  final String? lastBackupDate;
  final String? mmqrImagePath;
  final bool isProUnlocked;
  final String? proExpiresAt; // ISO String from server
  final double taxRate;
  final String currencySymbol;

  final String? cloudToken;
  final String? cloudUserEmail;
  final bool isLoggedIn;
  final String apiBaseUrl;
  final String? uuid;
  final String? updatedAt;

  ShopSettings({
    this.name = 'PoPOS Shop',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.footerMessage = 'Thank you for your business!',
    this.isDarkMode = false,
    this.languageCode = 'en',
    this.autoBackupInterval = 'none',
    this.lastBackupDate,
    this.mmqrImagePath,
    this.isProUnlocked = false,
    this.proExpiresAt,
    this.taxRate = 0.0,
    this.currencySymbol = '\$',
    this.cloudToken,
    this.cloudUserEmail,
    this.isLoggedIn = false,
    String? apiBaseUrl,
    this.uuid,
    this.updatedAt,
  }) : apiBaseUrl = apiBaseUrl ?? dotenv.get('API_URL', fallback: 'http://192.168.99.14/project-pos/backend/public/api');

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'footer_message': footerMessage,
      'is_dark_mode': isDarkMode ? 1 : 0,
      'language_code': languageCode,
      'auto_backup_interval': autoBackupInterval,
      'last_backup_date': lastBackupDate,
      'mmqr_image_path': mmqrImagePath,
      'is_pro_unlocked': isProUnlocked ? 1 : 0,
      'pro_expires_at': proExpiresAt,
      'tax_rate': taxRate,
      'currency_symbol': currencySymbol,
      'cloud_token': cloudToken,
      'cloud_user_email': cloudUserEmail,
      'is_logged_in': isLoggedIn ? 1 : 0,
      'api_base_url': apiBaseUrl,
      'uuid': uuid,
      'updated_at': updatedAt,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      name: map['name'] ?? 'PoPOS Shop',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      footerMessage: map['footer_message'] ?? 'Thank you for your business!',
      isDarkMode: (map['is_dark_mode'] ?? 0) == 1,
      languageCode: map['language_code'] ?? 'en',
      autoBackupInterval: map['auto_backup_interval'] ?? 'none',
      lastBackupDate: map['last_backup_date'],
      mmqrImagePath: map['mmqr_image_path'],
      isProUnlocked: (map['is_pro_unlocked'] ?? 0) == 1,
      proExpiresAt: map['pro_expires_at'],
      taxRate: map['tax_rate']?.toDouble() ?? 0.0,
      currencySymbol: map['currency_symbol'] ?? '\$',
      cloudToken: map['cloud_token'],
      cloudUserEmail: map['cloud_user_email'],
      isLoggedIn: (map['is_logged_in'] ?? 0) == 1,
      apiBaseUrl: map['api_base_url'] ?? dotenv.get('API_URL', fallback: 'http://192.168.99.14/project-pos/backend/public/api'),
      uuid: map['uuid'],
      updatedAt: map['updated_at'],
    );
  }

  ShopSettings copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? footerMessage,
    bool? isDarkMode,
    String? languageCode,
    String? autoBackupInterval,
    String? lastBackupDate,
    String? mmqrImagePath,
    bool? isProUnlocked,
    String? proExpiresAt,
    double? taxRate,
    String? currencySymbol,
    String? cloudToken,
    String? cloudUserEmail,
    bool? isLoggedIn,
    String? apiBaseUrl,
    String? uuid,
    String? updatedAt,
  }) {
    return ShopSettings(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      footerMessage: footerMessage ?? this.footerMessage,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
      autoBackupInterval: autoBackupInterval ?? this.autoBackupInterval,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      mmqrImagePath: mmqrImagePath ?? this.mmqrImagePath,
      isProUnlocked: isProUnlocked ?? this.isProUnlocked,
      proExpiresAt: proExpiresAt ?? this.proExpiresAt,
      taxRate: taxRate ?? this.taxRate,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      cloudToken: cloudToken ?? this.cloudToken,
      cloudUserEmail: cloudUserEmail ?? this.cloudUserEmail,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      uuid: uuid ?? this.uuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
