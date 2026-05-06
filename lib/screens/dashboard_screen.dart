import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../models/sale.dart';
import 'product_screen.dart';
import 'category_screen.dart';
import 'sale_screen.dart';
import 'sale_history_screen.dart';
import 'settings_screen.dart';
import 'main_screen.dart';
import '../providers/staff_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _dateOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _dateOffset = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(settingsProvider.l10n('dashboard')),
            if (settingsProvider.settings.isLoggedIn)
              Text(
                settingsProvider.isSyncing 
                  ? (settingsProvider.languageCode == 'my' ? 'ဒေတာများ သိမ်းဆည်းနေသည်...' : 'Syncing...') 
                  : (settingsProvider.lastSyncTime != null 
                    ? '${settingsProvider.languageCode == 'my' ? 'နောက်ဆုံး သိမ်းဆည်းမှု' : 'Last Sync'}: ${DateFormat('HH:mm').format(settingsProvider.lastSyncTime!)}'
                    : ''),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Colors.grey),
              ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => MainScreen.of(context)?.openDrawer(),
          ),
        ),
        actions: [
          if (settingsProvider.settings.isLoggedIn)
            IconButton(
              icon: settingsProvider.isSyncing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded),
              onPressed: settingsProvider.isSyncing ? null : () => settingsProvider.syncNow(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: settingsProvider.l10n('daily')),
            Tab(text: settingsProvider.l10n('weekly')),
            Tab(text: settingsProvider.l10n('monthly')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalysisView(context, 'daily'),
          _buildAnalysisView(context, 'weekly'),
          _buildAnalysisView(context, 'monthly'),
        ],
      ),
    );
  }

  Widget _buildAnalysisView(BuildContext context, String period) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Consumer<SaleProvider>(
      builder: (context, saleProvider, child) {
        final start = _getPeriodStart(period);
        final end = _getPeriodEnd(period);
        final filteredSales = _filterSales(saleProvider.sales, period);
        final totalRevenue = filteredSales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
        final productProvider = Provider.of<ProductProvider>(context);
        

        return RefreshIndicator(
          onRefresh: () async {
            if (settingsProvider.settings.isLoggedIn) {
              await settingsProvider.syncNow();
            }
            await productProvider.fetchProducts();
            await saleProvider.fetchSales();
            await Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<ProductProvider>(
                  builder: (context, pp, _) => _buildLowStockAlerts(context, pp),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => setState(() => _dateOffset--),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPeriodLabel(period, settingsProvider),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _dateOffset < 0 ? () => setState(() => _dateOffset++) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: _dateOffset < 0 ? null : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatsGrid(context, filteredSales.length, totalRevenue, productProvider.totalInstockWorth, saleProvider, period, start, end),
                const SizedBox(height: 32),
                Text(
                  settingsProvider.l10n('sales_trend'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTotalSalesChart(context, saleProvider, period),
                const SizedBox(height: 32),
                Text(
                  settingsProvider.languageCode == 'my' ? 'အသုံးစရိတ် နှိုင်းယှဉ်ချက်' : 'Expense Trend',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Consumer<ExpenseProvider>(
                  builder: (context, ep, _) => _buildExpenseChart(context, ep, period),
                ),
                const SizedBox(height: 32),
                Text(
                  settingsProvider.l10n('top_selling_${period}'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTopSellingProducts(context, saleProvider, period, start, end),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPeriodLabel(String period, SettingsProvider sp) {
    if (_dateOffset == 0) return sp.l10n('overview');
    
    final start = _getPeriodStart(period);
    final df = DateFormat('MMM d');
    if (period == 'daily') return df.format(start);
    
    final end = _getPeriodEnd(period);
    return '${df.format(start)} - ${df.format(end)}';
  }

  DateTime _getPeriodStart(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (period == 'daily') {
      return today.add(Duration(days: _dateOffset));
    } else if (period == 'weekly') {
      return today.subtract(const Duration(days: 6)).add(Duration(days: _dateOffset * 7));
    } else {
      return today.subtract(const Duration(days: 27)).add(Duration(days: _dateOffset * 28));
    }
  }

  DateTime _getPeriodEnd(String period) {
    final start = _getPeriodStart(period);
    if (period == 'daily') return start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    if (period == 'weekly') return start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return start.add(const Duration(days: 27, hours: 23, minutes: 59, seconds: 59));
  }


  Widget _buildLowStockAlerts(BuildContext context, ProductProvider provider) {
    final lowStockItems = provider.lowStockProducts;
    if (lowStockItems.isEmpty) return const SizedBox.shrink();

    final sp = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sp.l10n('low_stock_alerts'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                ),
                Text(
                  '${lowStockItems.length} ${sp.l10n('items_low_stock')}',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.red[700]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductScreen())),
            child: Text(
              sp.l10n('view_all'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int count, double revenue, double stockWorth, SaleProvider saleProvider, String period, DateTime start, DateTime end) {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final isWide = MediaQuery.of(context).size.width > 600;
    
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          context,
          sp.l10n('transactions'),
          count.toString(),
          Icons.shopping_bag_outlined,
          [const Color(0xFF6366F1), const Color(0xFF818CF8)],
          width: isWide ? (MediaQuery.of(context).size.width - 56) / 2 : double.infinity,
        ),
        _buildStatCard(
          context,
          sp.l10n('revenue'),
          '${revenue.toStringAsFixed(0)} ${sp.settings.currencySymbol}',
          Icons.currency_exchange_outlined,
          [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
          width: isWide ? (MediaQuery.of(context).size.width - 56) / 2 : double.infinity,
        ),
        if (!sp.settings.isProUnlocked || Provider.of<StaffProvider>(context, listen: false).hasPermission('view_profit')) ...[
          FutureBuilder<double>(
            future: saleProvider.getProfit(start, end),
            builder: (context, snapshot) {
              return _buildStatCard(
                context,
                sp.l10n('profit'),
                '${(snapshot.data ?? 0.0).toStringAsFixed(0)} ${sp.settings.currencySymbol}',
                Icons.trending_up_rounded,
                [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                width: isWide ? (MediaQuery.of(context).size.width - 56) / 2 : double.infinity,
              );
            },
          ),
          Consumer<ExpenseProvider>(
            builder: (context, ep, _) {
              final totalExp = ep.getTotalExpenses(start, end);
              return _buildStatCard(
                context,
                sp.l10n('expenses'),
                '${totalExp.toStringAsFixed(0)} ${sp.settings.currencySymbol}',
                Icons.money_off_rounded,
                [const Color(0xFFEF4444), const Color(0xFFF87171)],
                width: isWide ? (MediaQuery.of(context).size.width - 56) / 2 : double.infinity,
              );
            },
          ),
          _buildStatCard(
            context,
            sp.l10n('instock_worth'),
            '${stockWorth.toStringAsFixed(0)} ${sp.settings.currencySymbol}',
            Icons.inventory_2_outlined,
            [const Color(0xFF10B981), const Color(0xFF34D399)],
            width: isWide ? (MediaQuery.of(context).size.width - 56) / 2 : double.infinity,
          ),
        ],
      ],
    );
  }

  Widget _buildProPlaceholder(BuildContext context, SettingsProvider sp) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 32),
          const SizedBox(height: 12),
          Text(
            sp.languageCode == 'my' ? 'PRO ဗားရှင်းတွင်သာ ကြည့်ရှုနိုင်ပါသည်' : 'Available in PRO version',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 4),
          Text(
            sp.languageCode == 'my' ? 'ဆက်တင်တွင် PRO Mode ကို ဖွင့်ပါ' : 'Enable PRO mode in Settings',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, List<Color> colors, {double? width}) {
    return Container(
      width: width ?? double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSalesChart(BuildContext context, SaleProvider provider, String period) {
    final chartData = provider.getSalesForChart(period, offset: _dateOffset);
    return _buildChart(context, chartData, [const Color(0xFF6366F1), const Color(0xFF818CF8)]);
  }

  Widget _buildExpenseChart(BuildContext context, ExpenseProvider provider, String period) {
    final chartData = provider.getExpensesForChart(period, offset: _dateOffset);
    return _buildChart(context, chartData, [const Color(0xFFEF4444), const Color(0xFFF87171)]);
  }

  Widget _buildChart(BuildContext context, List<Map<String, dynamic>> chartData, List<Color> colors) {
    if (chartData.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
        child: const Center(child: Text('No data')),
      );
    }

    // Find max value for normalization
    double maxVal = chartData.fold(0.0, (max, e) => e['value'] > max ? e['value'] : max);
    if (maxVal == 0) maxVal = 1.0;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.light
          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
          : [],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chartData.length,
        itemBuilder: (context, index) {
          final data = chartData[index];
          double heightFactor = data['value'] / maxVal;
          return Container(
            width: 45,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (data['value'] > 0)
                  Text(
                    data['value'] >= 1000 ? '${(data['value']/1000).toStringAsFixed(1)}k' : data['value'].toStringAsFixed(0),
                    style: const TextStyle(fontSize: 8, color: Colors.grey)
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 130 * heightFactor,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(data['label'], style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopSellingProducts(BuildContext context, SaleProvider provider, String period, DateTime start, DateTime end) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getTopSellingProducts(start, end),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, color: Colors.grey.withOpacity(0.3), size: 32),
                const SizedBox(height: 8),
                Text(
                  Provider.of<SettingsProvider>(context).languageCode == 'my' ? 'မှတ်တမ်းမရှိသေးပါ' : 'No data for this period',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: Theme.of(context).brightness == Brightness.light
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                ),
                title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                trailing: Text('${p['total_qty']} ${Provider.of<SettingsProvider>(context).languageCode == 'my' ? 'ခု' : 'Sold'}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              );
            },
          ),
        );
      },
    );
  }

  List<Sale> _filterSales(List<Sale> sales, String period) {
    final start = _getPeriodStart(period);
    final end = _getPeriodEnd(period);
    return sales.where((s) => s.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) && s.timestamp.isBefore(end)).toList();
  }


}
