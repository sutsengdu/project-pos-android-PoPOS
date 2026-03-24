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

  ShopSettings({
    this.name = 'My POS Shop',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.footerMessage = 'Thank you for your business!',
    this.isDarkMode = false,
    this.languageCode = 'en',
    this.autoBackupInterval = 'none',
    this.lastBackupDate,
    this.mmqrImagePath,
  });

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
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      name: map['name'] ?? 'My POS Shop',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      footerMessage: map['footer_message'] ?? 'Thank you for your business!',
      isDarkMode: (map['is_dark_mode'] ?? 0) == 1,
      languageCode: map['language_code'] ?? 'en',
      autoBackupInterval: map['auto_backup_interval'] ?? 'none',
      lastBackupDate: map['last_backup_date'],
      mmqrImagePath: map['mmqr_image_path'],
    );
  }
}
