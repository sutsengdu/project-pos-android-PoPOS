import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/shop_settings.dart';
import 'package:image_picker/image_picker.dart';
import 'category_screen.dart';
import 'main_screen.dart';
import '../services/backup_service.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'login_screen.dart';
import '../providers/staff_provider.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/expense_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _footerController;
  late TextEditingController _taxController;
  late TextEditingController _currencyController;
  bool _isSynced = false;
  String? _tempMMQRPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _footerController = TextEditingController();
    _taxController = TextEditingController();
    _currencyController = TextEditingController();
  }

  void _syncControllers(ShopSettings settings) {
    _nameController.text = settings.name;
    _addressController.text = settings.address;
    _phoneController.text = settings.phone;
    _emailController.text = settings.email;
    _footerController.text = settings.footerMessage;
    _taxController.text = settings.taxRate.toString();
    _currencyController.text = settings.currencySymbol;
    _tempMMQRPath = settings.mmqrImagePath;
    _isSynced = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _footerController.dispose();
    _taxController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    if (!_isSynced && settingsProvider.isLoaded) {
      _syncControllers(settings);
    }

    final staffProvider = Provider.of<StaffProvider>(context);
    final isPro = settingsProvider.settings.isProUnlocked;
    if (isPro && !staffProvider.hasPermission('access_settings')) {
      return Scaffold(
        appBar: AppBar(title: Text(settingsProvider.l10n('settings'))),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(settingsProvider.l10n('settings')),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => MainScreen.of(context)?.openDrawer(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              ListView(
                children: [
                  _buildSectionHeader(settingsProvider.l10n('dark_mode')),
                  SwitchListTile(
                    title: Text(settingsProvider.l10n('dark_mode')),
                    subtitle: Text(settings.isDarkMode ? 'Enabled' : 'Disabled'),
                    secondary: Icon(settings.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: const Color(0xFF6366F1)),
                    value: settings.isDarkMode,
                    onChanged: (v) => settingsProvider.toggleTheme(),
                  ),
                  const Divider(),
                  _buildSectionHeader(settingsProvider.l10n('language')),
                  ListTile(
                    leading: const Icon(Icons.language, color: Color(0xFF6366F1)),
                    title: Text(settingsProvider.l10n('language')),
                    trailing: DropdownButton<String>(
                      value: settings.languageCode,
                      items: [
                        const DropdownMenuItem(value: 'en', child: Text('English')),
                        const DropdownMenuItem(value: 'my', child: Text('မြန်မာ')),
                      ],
                      onChanged: (v) {
                        if (v != null) settingsProvider.setLanguage(v);
                      },
                    ),
                  ),
                  const Divider(),
                  _buildSectionHeader(settingsProvider.languageCode == 'my' ? 'ဗားရှင်းနှင့် အထူးလုပ်ဆောင်ချက်များ' : 'Version & Pro Features'),
                  ListTile(
                    title: Row(
                      children: [
                        Text(settings.isProUnlocked ? 'PoPOS PRO' : 'PoPOS Basic', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (settings.isLoggedIn) 
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.blue),
                            onPressed: () => settingsProvider.refreshProStatus(),
                            tooltip: 'Refresh Status',
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(settings.isProUnlocked 
                          ? (settingsProvider.languageCode == 'my' ? 'အထူးလုပ်ဆောင်ချက်များ အားလုံးအသုံးပြုနိုင်ပါသည်' : 'All premium features unlocked')
                          : (settingsProvider.languageCode == 'my' ? 'အခြေခံလုပ်ဆောင်ချက်များသာ' : 'Standard features only')),
                        if (settings.isProUnlocked && settings.proExpiresAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            settingsProvider.languageCode == 'my' 
                              ? 'သက်တမ်းကုန်ဆုံးမည့်ရက်: ${settings.proExpiresAt!.substring(0, 10)}' 
                              : 'Expires on: ${settings.proExpiresAt!.substring(0, 10)}',
                            style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                    leading: Icon(
                      settings.isProUnlocked ? Icons.verified_rounded : Icons.info_outline_rounded, 
                      color: settings.isProUnlocked ? Colors.orange : Colors.grey
                    ),
                  ),
                  if (!settings.isProUnlocked) _buildProComparisonCard(settingsProvider),
                  
                  _buildMMQRSection(settingsProvider),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  _buildCloudSyncSection(settingsProvider, settings),
                  const Divider(),
                  
                  _buildOfflineBackupSection(settingsProvider, settings),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildSectionHeader(settingsProvider.l10n('shop_info')),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: settingsProvider.l10n('shop_name'),
                      prefixIcon: const Icon(Icons.store_rounded),
                    ),
                    validator: (v) => v!.isEmpty ? settingsProvider.l10n('Enter shop name') : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: settingsProvider.l10n('address'),
                      prefixIcon: const Icon(Icons.location_on_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: settingsProvider.l10n('phone'),
                      prefixIcon: const Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: settingsProvider.l10n('email'),
                      prefixIcon: const Icon(Icons.email_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _footerController,
                    decoration: InputDecoration(
                      labelText: settingsProvider.l10n('footer_msg'),
                      prefixIcon: const Icon(Icons.message_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(settingsProvider.languageCode == 'my' ? 'အခွန်နှင့် ငွေကြေး' : 'Tax & Currency'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _taxController,
                          decoration: InputDecoration(
                            labelText: settingsProvider.languageCode == 'my' ? 'အခွန်နှုန်း (%)' : 'Tax Rate (%)',
                            prefixIcon: const Icon(Icons.percent_rounded),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _currencyController,
                          decoration: InputDecoration(
                            labelText: settingsProvider.languageCode == 'my' ? 'ငွေကြေးသင်္ကေတ' : 'Currency Symbol',
                            prefixIcon: const Icon(Icons.payments_outlined),
                            hintText: '\$, MMK, SGD',
                            helperText: settingsProvider.languageCode == 'my' ? 'ဥပမာ - \$, MMK' : 'Example: \$, MMK',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Divider(color: Colors.redAccent, thickness: 1),
                  _buildSectionHeader(settingsProvider.l10n('danger_zone')),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    title: Text(settingsProvider.l10n('reset_app'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () => _showResetConfirmation(context, settingsProvider),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final newSettings = settings.copyWith(
                            name: _nameController.text,
                            address: _addressController.text,
                            phone: _phoneController.text,
                            email: _emailController.text,
                            footerMessage: _footerController.text,
                            taxRate: double.tryParse(_taxController.text) ?? 0.0,
                            currencySymbol: _currencyController.text.isNotEmpty ? _currencyController.text : '¤',
                            mmqrImagePath: _tempMMQRPath,
                          );
                          await settingsProvider.updateSettings(newSettings);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(settingsProvider.languageCode == 'my' ? 'သိမ်းဆည်းပြီးပါပြီ' : 'Settings saved successfully!')));
                          }
                        }
                      },
                      child: Text(settingsProvider.l10n('save_settings'), style: const TextStyle(fontSize: 16, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Processing Cloud Data...', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, SettingsProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.l10n('confirm_reset_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.l10n('confirm_reset_msg')),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'delete'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(provider.languageCode == 'my' ? 'မလုပ်တော့ပါ' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              if (controller.text == 'delete') {
                await provider.resetApp();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App Reset Successfully')));
                }
              }
            },
            child: Text(provider.languageCode == 'my' ? 'အားလုံးဖျက်မည်' : 'Reset Everything', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudStatus(BuildContext context, SettingsProvider sp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn = sp.settings.isLoggedIn;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLoggedIn ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isLoggedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: isLoggedIn ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? (sp.languageCode == 'my' ? 'Cloud ချိတ်ဆက်ထားသည်' : 'Cloud Sync Active') : (sp.languageCode == 'my' ? 'Offline အသုံးပြုနေသည်' : 'Offline Mode'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  isLoggedIn ? (sp.settings.cloudUserEmail ?? '') : (sp.languageCode == 'my' ? 'ဒေတာများကို သိမ်းဆည်းရန် ဝင်ရောက်ပါ' : 'Login to secure your data'),
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                ),
                  _buildCloudSyncButton(context, sp),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: () {
              if (isLoggedIn) {
                _showLogoutDialog(context, sp);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLoggedIn ? Colors.grey.withOpacity(0.1) : const Color(0xFF6366F1),
              foregroundColor: isLoggedIn ? (isDark ? Colors.white : Colors.black) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(isLoggedIn ? (sp.languageCode == 'my' ? 'ထွက်ရန်' : 'Logout') : (sp.languageCode == 'my' ? 'ဝင်ရန်' : 'Login')),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, SettingsProvider sp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sp.languageCode == 'my' ? 'အကောင့်ထွက်ရန်' : 'Logout Cloud'),
        content: Text(sp.languageCode == 'my' ? 'ဝင်ရောက်ထားခြင်းမှ ထွက်မှာသေချာပါသလား?' : 'Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(sp.l10n('cancel'))),
          TextButton(
            onPressed: () async {
              await sp.logout();
              Navigator.pop(context);
            },
            child: Text(sp.languageCode == 'my' ? 'ထွက်မည်' : 'Logout', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSyncButton(BuildContext context, SettingsProvider sp) {
    if (!sp.settings.isLoggedIn) return const SizedBox.shrink();
    
    final isPro = sp.settings.isProUnlocked;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: (!isPro || _isLoading) ? null : () async {
              setState(() => _isLoading = true);
              final error = await sp.syncNow();
              if (mounted) {
                setState(() => _isLoading = false);
                if (error == null) {
                  Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
                  Provider.of<ProductProvider>(context, listen: false).fetchProducts();
                  Provider.of<SaleProvider>(context, listen: false).fetchSales();
                  Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
                  Provider.of<StaffProvider>(context, listen: false).loadStaff();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error == null ? (sp.languageCode == 'my' ? 'Cloud နှင့် ချိတ်ဆက်မှု အောင်မြင်ပါသည်' : 'Cloud Sync Successful!') : error),
                    backgroundColor: error == null ? Colors.green : Colors.redAccent,
                  ),
                );
              }
            },
            icon: Icon(isPro ? Icons.sync_rounded : Icons.lock_outline_rounded, size: 18),
            label: Text(sp.languageCode == 'my' ? 'Cloud နှင့် ဒေတာ ချိတ်ဆက်မည်' : 'Sync with Cloud'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: isPro ? null : Colors.grey,
            ),
          ),
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                sp.languageCode == 'my' ? '* Cloud Sync ကို PRO ဗားရှင်းတွင်သာ ရနိုင်ပါသည်။' : '* Cloud Sync is only available in PRO version.',
                style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProRequiredBanner(SettingsProvider sp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            sp.languageCode == 'my' ? 'PRO ဗားရှင်းတွင်သာ အသုံးပြုနိုင်ပါသည်' : 'Available in PRO version',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildMMQRSection(SettingsProvider sp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        _buildSectionHeader(sp.l10n('mmqr_pay_image')),
        const SizedBox(height: 8),
        if (_tempMMQRPath != null)
          Center(
            child: Stack(
              children: [
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _tempMMQRPath!.startsWith('http') 
                      ? Image.network(_tempMMQRPath!, fit: BoxFit.contain)
                      : Image.file(File(_tempMMQRPath!), fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _tempMMQRPath = null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: () async {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final appDocDir = await getApplicationDocumentsDirectory();
                final fileName = p.basename(image.path);
                final permanentPath = p.join(appDocDir.path, fileName);
                await File(image.path).copy(permanentPath);
                setState(() => _tempMMQRPath = permanentPath);
              }
            },
            icon: const Icon(Icons.upload_rounded),
            label: Text(sp.l10n('select_image')),
          ),
        ),
      ],
    );
  }

  Widget _buildCloudSyncSection(SettingsProvider sp, ShopSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(sp.l10n('backup_restore'), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        ),
        _buildCloudStatus(context, sp),
      ],
    );
  }

  Widget _buildOfflineBackupSection(SettingsProvider sp, ShopSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(sp.l10n('offline_backup'), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.file_upload_outlined, color: Colors.blueGrey),
          title: Text(sp.l10n('export_db')),
          subtitle: const Text('Save .db file to your device or share it'),
          onTap: () async {
            await sp.exportOfflineBackup();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sp.l10n('backup_success'))));
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined, color: Colors.blueGrey),
          title: Text(sp.l10n('import_db')),
          subtitle: const Text('Restore from a previously exported .db file'),
          onTap: () async {
            final success = await sp.importOfflineBackup();
            if (mounted && success) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sp.l10n('restore_success'))));
            }
          },
        ),
      ],
    );
  }

  Widget _buildProComparisonCard(SettingsProvider sp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = [
      {'title': 'Multi-staff & PIN Security', 'my': 'ဝန်ထမ်းများစွာနှင့် PIN လုံခြုံရေး'},
      {'title': 'Cloud Backup & Sync', 'my': 'Cloud ထဲတွင် ဒေတာသိမ်းဆည်းခြင်း'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.withOpacity(0.05) : Colors.orange.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                sp.languageCode == 'my' ? 'PRO ၏ အကျိုးကျေးဇူးများ' : 'PRO Features Benefit',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sp.languageCode == 'my' ? f['my']! : f['title']!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
