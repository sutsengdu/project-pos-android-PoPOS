import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/sale_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/invoice_service.dart';
import 'product_screen.dart'; // For BarcodeScannerScreen
import 'dart:io';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final allProducts = Provider.of<ProductProvider>(context, listen: false).products;
    setState(() {
      _searchResults = allProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || p.barcode.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(settingsProvider.l10n('new_sale')),
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF6366F1)),
              onPressed: _scanBarcode,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildManualSearch(context),
          if (_searchResults.isNotEmpty) _buildSearchResults(context),
          Expanded(
            child: Consumer<SaleProvider>(
              builder: (context, saleProvider, child) {
                final items = saleProvider.cartItems.values.toList();
                final products = Provider.of<ProductProvider>(context).products;

                if (items.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(settingsProvider.l10n('cart_empty'), style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(settingsProvider.l10n('scan_to_begin'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 13), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final product = products.firstWhere((p) => p.id == item.productId);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark ? [] : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                          child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6366F1), size: 20),
                        ),
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('\$${item.unitPrice} x ${item.quantity}', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () => saleProvider.removeFromCart(product.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Consumer<SaleProvider>(builder: (context, sp, _) => _buildCheckoutSection(context, sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSearch(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: settingsProvider.l10n('search_product'),
          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _onSearch('');
                },
              )
            : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: _onSearch,
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      constraints: BoxConstraints(maxHeight: isLandscape ? 120 : 180),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white10 : null),
          itemBuilder: (context, index) {
            final product = _searchResults[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                child: const Icon(Icons.add_rounded, color: Color(0xFF6366F1)),
              ),
              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('\$${product.price} • ${settingsProvider.l10n('stock')}: ${product.stock}', style: TextStyle(color: isDark ? Colors.white54 : null)),
              onTap: () {
                if (product.stock > 0) {
                  Provider.of<SaleProvider>(context, listen: false).addToCart(product);
                  _searchController.clear();
                  _onSearch('');
                  FocusScope.of(context).unfocus();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(settingsProvider.l10n('out_of_stock'))));
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, SaleProvider saleProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isLandscape ? 8 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: isLandscape 
        ? Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settingsProvider.l10n('total_amount'), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[600])),
                    Text(
                      '${saleProvider.totalAmount.toStringAsFixed(0)} KS',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: saleProvider.cartItems.isEmpty ? null : () => _completeSale(context, saleProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: saleProvider.cartItems.isEmpty ? Colors.grey : const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(settingsProvider.l10n('complete_sale'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(settingsProvider.l10n('total_amount'), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600])),
                  Text(
                    '${saleProvider.totalAmount.toStringAsFixed(0)} KS',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: saleProvider.cartItems.isEmpty ? null : () => _completeSale(context, saleProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: saleProvider.cartItems.isEmpty ? Colors.grey : const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(settingsProvider.l10n('complete_sale'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
    );
  }

  void _scanBarcode() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcode != null) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final product = await productProvider.getProductByBarcode(barcode);

      if (product != null) {
        if (product.stock > 0) {
          Provider.of<SaleProvider>(context, listen: false).addToCart(product);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(settingsProvider.l10n('out_of_stock'))),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(settingsProvider.l10n('not_found'))),
        );
      }
    }
  }

  void _completeSale(BuildContext context, SaleProvider saleProvider) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final total = saleProvider.totalAmount;
    String paymentMethod = 'Cash';
    final TextEditingController amountController = TextEditingController(text: total.toStringAsFixed(0));
    double change = 0.0;

    final itemsToInvoice = <Map<String, dynamic>>[];
    final products = Provider.of<ProductProvider>(context, listen: false).products;
    saleProvider.cartItems.forEach((id, item) {
      final p = products.firstWhere((prod) => prod.id == item.productId);
      itemsToInvoice.add({
        'product_name': p.name,
        'unit_price': item.unitPrice,
        'quantity': item.quantity,
      });
    });
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: Text(settingsProvider.l10n('payment')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${settingsProvider.l10n('total_amount')}: ${total.toStringAsFixed(0)} KS', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: paymentMethod,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'Cash', child: Text(settingsProvider.l10n('cash'))),
                    DropdownMenuItem(value: 'MMQR', child: Text(settingsProvider.l10n('mmqr_pay'))),
                    DropdownMenuItem(value: 'Other', child: Text(settingsProvider.l10n('other'))),
                  ],
                  onChanged: (v) => setState(() => paymentMethod = v!),
                ),
                if (paymentMethod == 'Cash') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(labelText: settingsProvider.l10n('amount_paid')),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final paid = double.tryParse(v) ?? 0;
                      setState(() => change = paid - total);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('${settingsProvider.l10n('change')}: ${ (change < 0 ? 0 : change).toStringAsFixed(0) } KS',
                      style: TextStyle(color: change < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                ],
                if (paymentMethod == 'MMQR') ...[
                  const SizedBox(height: 16),
                  if (settingsProvider.settings.mmqrImagePath != null && 
                      settingsProvider.settings.mmqrImagePath!.isNotEmpty &&
                      File(settingsProvider.settings.mmqrImagePath!).existsSync())
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(File(settingsProvider.settings.mmqrImagePath!), fit: BoxFit.contain),
                      ),
                    )
                  else
                    Text(
                      settingsProvider.languageCode == 'my' ? 'QR ပုံ မတွေ့ပါ (Setting တွင် အရင်တင်ပါ)' : 'No QR image found. Please upload in Settings.',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(settingsProvider.l10n('cancel'))),
            ElevatedButton(
              onPressed: (paymentMethod == 'Cash' && (double.tryParse(amountController.text) ?? 0) < total)
                  ? null
                  : () async {
                      final paid = double.tryParse(amountController.text) ?? 0.0;
                      final savedSale = await saleProvider.completeSale(
                        context,
                        paymentMethod: paymentMethod,
                        amountPaid: paid,
                        change: paid - total,
                      );
                      Navigator.pop(context);
                      if (savedSale != null) {
                        _showInvoiceDialog(context, itemsToInvoice, savedSale);
                      }
                    },
              child: Text(settingsProvider.l10n('confirm_payment')),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context, List<Map<String, dynamic>> items, Sale sale) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settingsProvider.l10n('sale_success')),
        content: Text(settingsProvider.l10n('gen_invoice')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(settingsProvider.l10n('close'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
              InvoiceService.generateAndShowInvoice(sale, items, settings);
            },
            child: Text(settingsProvider.l10n('view_invoice')),
          ),
        ],
      ),
    );
  }
}
