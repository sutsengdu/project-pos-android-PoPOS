import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../models/category.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(settingsProvider.l10n('categories')),
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(settingsProvider.languageCode == 'my' ? 'အမျိုးအစားမရှိသေးပါ' : 'No categories yet', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[500], fontSize: 18)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.1),
                    child: const Icon(Icons.folder_open_rounded, color: Color(0xFF0EA5E9), size: 20),
                  ),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (v) {
                      if (v == 'edit') _showCategoryDialog(context, category: category);
                      if (v == 'delete') _showDeleteDialog(context, category);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 20), const SizedBox(width: 8), Text(settingsProvider.l10n('edit'))])),
                      PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, color: Colors.red, size: 20), const SizedBox(width: 8), Text(settingsProvider.l10n('delete'), style: const TextStyle(color: Colors.red))])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showCategoryDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {Category? category}) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final controller = TextEditingController(text: category?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(category == null ? settingsProvider.l10n('new_category') : settingsProvider.l10n('edit_category'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: settingsProvider.l10n('category_name'),
            hintText: settingsProvider.languageCode == 'my' ? 'ဥပမာ- ရေ' : 'e.g. Beverages',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(settingsProvider.l10n('cancel'), style: const TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                if (category == null) {
                  Provider.of<CategoryProvider>(context, listen: false).addCategory(name);
                } else {
                  Provider.of<CategoryProvider>(context, listen: false).updateCategory(
                    Category(id: category.id, name: name),
                  );
                }
                Navigator.pop(context);
              }
            },
            child: Text(settingsProvider.l10n('save_category')),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Category category) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settingsProvider.l10n('delete')),
        content: Text('${settingsProvider.languageCode == 'my' ? 'ဖျက်မှာသေချာပါသလား' : 'Are you sure you want to delete'} "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(settingsProvider.l10n('cancel'))),
          TextButton(
            onPressed: () {
              Provider.of<CategoryProvider>(context, listen: false).deleteCategory(category.id!);
              Navigator.pop(context);
            },
            child: Text(settingsProvider.l10n('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
