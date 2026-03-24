import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/shop_settings.dart';
import 'package:image_picker/image_picker.dart';
import 'category_screen.dart';
import '../services/backup_service.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  bool _isSynced = false;
  String? _tempMMQRPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _footerController = TextEditingController();
  }

  void _syncControllers(ShopSettings settings) {
    _nameController.text = settings.name;
    _addressController.text = settings.address;
    _phoneController.text = settings.phone;
    _emailController.text = settings.email;
    _footerController.text = settings.footerMessage;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    // Sync controllers on first load when data is available
    if (!_isSynced && settingsProvider.isLoaded) {
      _syncControllers(settings);
    }

    return Scaffold(
      appBar: AppBar(title: Text(settingsProvider.l10n('settings'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
              const Divider(),
              const SizedBox(height: 16),
              _buildSectionHeader(settingsProvider.l10n('category_management')),
              ListTile(
                leading: const Icon(Icons.category_rounded, color: Color(0xFF6366F1)),
                title: Text(settingsProvider.l10n('manage_categories')),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen())),
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildSectionHeader(settingsProvider.l10n('mmqr_pay_image')),
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
                      // Copy to permanent storage
                      final appDocDir = await getApplicationDocumentsDirectory();
                      final fileName = p.basename(image.path);
                      final permanentPath = p.join(appDocDir.path, fileName);
                      await File(image.path).copy(permanentPath);
                      
                      setState(() => _tempMMQRPath = permanentPath);
                    }
                  },
                  icon: const Icon(Icons.upload_rounded),
                  label: Text(settingsProvider.l10n('select_image')),
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildSectionHeader(settingsProvider.l10n('backup_restore')),
              ListTile(
                leading: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF6366F1)),
                title: Text(settingsProvider.l10n('manual_backup')),
                onTap: () async {
                  await settingsProvider.triggerBackup();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(settingsProvider.l10n('backup_success'))));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_rounded, color: Color(0xFF6366F1)),
                title: Text(settingsProvider.l10n('manual_restore')),
                onTap: () async {
                  final success = await BackupService.restoreBackup();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(settingsProvider.l10n('restore_success'))));
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(settingsProvider.l10n('restore_fail'))));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_mode_rounded, color: Color(0xFF6366F1)),
                title: Text(settingsProvider.l10n('auto_backup')),
                trailing: DropdownButton<String>(
                  value: settings.autoBackupInterval,
                  items: [
                    DropdownMenuItem(value: 'none', child: Text(settingsProvider.l10n('none'))),
                    DropdownMenuItem(value: 'daily', child: Text(settingsProvider.l10n('daily'))),
                    DropdownMenuItem(value: 'weekly', child: Text(settingsProvider.l10n('weekly'))),
                    DropdownMenuItem(value: 'monthly', child: Text(settingsProvider.l10n('monthly'))),
                  ],
                  onChanged: (v) {
                    if (v != null) settingsProvider.updateBackupInterval(v);
                  },
                ),
              ),
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
                      final newSettings = ShopSettings(
                        name: _nameController.text,
                        address: _addressController.text,
                        phone: _phoneController.text,
                        email: _emailController.text,
                        footerMessage: _footerController.text,
                        isDarkMode: settings.isDarkMode,
                        languageCode: settings.languageCode,
                        autoBackupInterval: settings.autoBackupInterval,
                        lastBackupDate: settings.lastBackupDate,
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
}
