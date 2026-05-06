import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'dashboard_screen.dart';
import 'product_screen.dart';
import 'sale_screen.dart';
import 'sale_history_screen.dart';
import 'settings_screen.dart';
import 'category_screen.dart';
import 'expense_screen.dart';
import 'staff_screen.dart';
import 'staff_login_screen.dart';
import '../providers/staff_provider.dart';
import '../models/staff.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static MainScreenState? of(BuildContext context) => context.findAncestorStateOfType<MainScreenState>();

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SaleScreen(),
    const SettingsScreen(),
  ];

  List<int> _currentScreenIndices = [0, 1, 2];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = Provider.of<SettingsProvider>(context, listen: false);
      sp.runAutoBackupCheck();
      if (sp.settings.isLoggedIn) {
        sp.syncNow();
      }
      Provider.of<StaffProvider>(context, listen: false).loadStaff();
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

    final staffProvider = Provider.of<StaffProvider>(context);
    final currentStaff = staffProvider.currentStaff;
    final isPro = settingsProvider.settings.isProUnlocked;
    final hasStaff = staffProvider.staff.isNotEmpty;

    // In Pro mode, if there are staff members defined, enforce a login
    if (isPro && hasStaff && currentStaff == null) {
      return const StaffLoginScreen();
    }

    final effectiveStaff = currentStaff ?? Staff(name: 'Admin', role: 'Admin', pin: '');
    final isAdmin = effectiveStaff.isAdmin;
    final List<Widget> accessibleScreens = [
      const DashboardScreen(),
      const SaleScreen(),
    ];
    if (isAdmin) accessibleScreens.add(const SettingsScreen());

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.store_rounded, size: 48, color: Color(0xFF6366F1)),
                    const SizedBox(height: 12),
                    Text(
                      settingsProvider.settings.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildDrawerItem(context, settingsProvider.l10n('products'), Icons.inventory_2_rounded, const ProductScreen(), true),
                  _buildDrawerItem(context, settingsProvider.l10n('categories'), Icons.category_rounded, const CategoryScreen(), true),
                  _buildDrawerItem(context, settingsProvider.l10n('history'), Icons.receipt_long_rounded, const SaleHistoryScreen(), true),
                  _buildDrawerItem(
                    context, 
                    settingsProvider.l10n('expenses'), 
                    Icons.money_off_rounded, 
                    const ExpenseScreen(), 
                    true,
                  ),
                  if (effectiveStaff.isAdmin)
                    _buildDrawerItem(
                      context, 
                      (settingsProvider.languageCode == 'my' ? 'ဝန်ထမ်းများ' : 'Staff') + (settingsProvider.settings.isProUnlocked ? '' : ' (PRO)'), 
                      Icons.people_outline_rounded, 
                      const StaffManagementScreen(), 
                      true,
                      isLocked: !settingsProvider.settings.isProUnlocked
                    ),
                  if (settingsProvider.settings.isProUnlocked) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.switch_account_rounded, color: Colors.blueAccent),
                      title: Text(settingsProvider.languageCode == 'my' ? 'ဝန်ထမ်းပြောင်းရန်' : 'Switch Staff'),
                      onTap: () {
                        Navigator.pop(context);
                        staffProvider.logout();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: accessibleScreens[_selectedIndex >= accessibleScreens.length ? 0 : _selectedIndex],
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
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: settingsProvider.l10n('sale'),
            ),
            if (isAdmin)
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_rounded),
                label: settingsProvider.l10n('settings'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, dynamic target, bool isNewScreen, {bool isLocked = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = !isNewScreen && target == _selectedIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.white38 : const Color(0xFF64748B))),
        trailing: isLocked ? const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.orange) : null,
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
            color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context);
          if (isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This is a PRO feature. Please enable PRO mode in Settings.'))
            );
            return;
          }
          if (isNewScreen) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => target as Widget));
          } else {
            _onItemTapped(target as int);
          }
        },
      ),
    );
  }
}
