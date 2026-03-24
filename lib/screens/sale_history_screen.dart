import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sale_provider.dart';
import '../providers/settings_provider.dart';
import '../models/sale.dart';
import '../services/invoice_service.dart';

class SaleHistoryScreen extends StatefulWidget {
  const SaleHistoryScreen({super.key});

  @override
  State<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends State<SaleHistoryScreen> {
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final saleProvider = Provider.of<SaleProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Initial fetch if empty
    if (saleProvider.sales.isEmpty && _searchQuery.isEmpty && _selectedDateRange == null) {
      saleProvider.fetchSales();
    }

    final filteredSales = saleProvider.sales.where((sale) {
      final matchesQuery = sale.id.toString().contains(_searchQuery) ||
          sale.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesDate = true;
      if (_selectedDateRange != null) {
        matchesDate = sale.timestamp.isAfter(_selectedDateRange!.start) &&
            sale.timestamp.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }
      
      return matchesQuery && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(settingsProvider.languageCode == 'my' ? 'အရောင်းမှတ်တမ်း' : 'Sale History'),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range, color: _selectedDateRange != null ? Colors.blue : null),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _selectedDateRange,
              );
              if (picked != null) setState(() => _selectedDateRange = picked);
            },
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedDateRange = null),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: settingsProvider.languageCode == 'my' ? 'ရှာဖွေရန်...' : 'Search sales...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey[200]),
                        const SizedBox(height: 16),
                        Text(settingsProvider.l10n('no_sale_found'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      return _buildSaleCard(context, sale, saleProvider, settingsProvider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, Sale sale, SaleProvider provider, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1)),
        ),
        title: Text('${settings.languageCode == 'my' ? 'အမှတ် -' : 'ID:'} #${sale.id}', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(DateFormat('MMM dd, yyyy • HH:mm').format(sale.timestamp), 
          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${sale.totalAmount.toStringAsFixed(0)} KS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
                Text(
                  sale.paymentMethod,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 12)
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDelete(context, sale.id!, provider, settings),
            ),
          ],
        ),
        onTap: () => _showSaleDetails(context, sale, provider, settings),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, SaleProvider provider, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.languageCode == 'my' ? 'ဖျက်ရန် အတည်ပြုပါ' : 'Confirm Delete'),
        content: Text(settings.languageCode == 'my' ? 'ဤမှတ်တမ်းကို ဖျက်ရန် သေချာပါသလား?' : 'Are you sure you want to delete this sale record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(settings.languageCode == 'my' ? 'မလုပ်တော့ပါ' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await provider.deleteSale(id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(settings.languageCode == 'my' ? 'ဖျက်မည်' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSaleDetails(BuildContext context, Sale sale, SaleProvider provider, SettingsProvider settings) async {
    final details = await provider.getSaleDetails(sale.id!);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(settings.l10n('sale_details'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: details.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : null),
                  itemBuilder: (context, index) {
                    final item = details[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                Text('${item['unit_price']} KS x ${item['quantity']}', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600])),
                              ],
                            ),
                          ),
                          Text(
                            '${(item['unit_price'] * item['quantity']).toStringAsFixed(0)} KS',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        InvoiceService.generateAndShowInvoice(sale, details, settings.settings);
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: Text(settings.l10n('print_receipt')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(settings.l10n('close')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
