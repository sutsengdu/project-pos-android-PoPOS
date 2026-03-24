import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'dashboard_screen.dart';
import 'product_screen.dart';
import 'sale_screen.dart';
import 'sale_history_screen.dart';
import 'settings_screen.dart';
import 'category_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductScreen(),
    const SaleScreen(),
    const SaleHistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).runAutoBackupCheck();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: isDark 
            ? [] 
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: settingsProvider.l10n('dashboard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_rounded),
              label: settingsProvider.l10n('products'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: settingsProvider.l10n('sale'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              label: settingsProvider.l10n('history'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: settingsProvider.l10n('settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, Widget? screen, bool isScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isDark ? Colors.white38 : const Color(0xFF64748B)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);
          if (isScreen && screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
          } else {
            // Logic for refresh if needed
          }
        },
      ),
    );
  }
}
