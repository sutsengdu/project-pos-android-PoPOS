import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/sale_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/category_provider.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/invoice_service.dart';
import 'product_screen.dart'; // For BarcodeScannerScreen
import 'main_screen.dart';
import 'dart:io';
import '../providers/staff_provider.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Product> _searchResults = [];
  int? _browseCategoryId;
  bool _isBrowsing = false;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
    final hasSearchContent = _isBrowsing || _searchResults.isNotEmpty;
    final hideCartAndCheckout = _isSearchFocused && hasSearchContent;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(settingsProvider.l10n('new_sale')),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => MainScreen.of(context)?.openDrawer(),
          ),
        ),
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
          _buildCategoryFilter(context),
          if (hasSearchContent)
            hideCartAndCheckout
              ? Expanded(child: _buildProductList(context))
              : Flexible(flex: 1, child: _buildProductList(context)),
              if (!hideCartAndCheckout) ...[
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
                              subtitle: Text('\$${item.price} x ${item.quantity}', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600])),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20),
                                    onPressed: () => saleProvider.updateQuantity(product.id!, -1),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1), size: 20),
                                    onPressed: () => saleProvider.updateQuantity(product.id!, 1),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(item.price * item.quantity).toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
        focusNode: _searchFocusNode,
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

  Widget _buildCategoryFilter(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryProvider.categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : categoryProvider.categories[index - 1];
          final isSelected = _browseCategoryId == category?.id && (isAll ? _browseCategoryId == null : true) && _isBrowsing;
          
          if (isAll && !_isBrowsing && _browseCategoryId == null) {
             // Not browsing yet
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: _browseCategoryId == (isAll ? null : category?.id) && _isBrowsing,
              label: Text(isAll ? (settingsProvider.languageCode == 'my' ? 'အားလုံး' : 'All') : category!.name),
              onSelected: (selected) {
                setState(() {
                  _isBrowsing = true;
                  _browseCategoryId = isAll ? null : category?.id;
                  _searchResults = [];
                  _searchController.clear();
                });
              },
              backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
              selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
              checkmarkColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: (_browseCategoryId == (isAll ? null : category?.id) && _isBrowsing) 
                    ? const Color(0xFF6366F1) 
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: (_browseCategoryId == (isAll ? null : category?.id) && _isBrowsing) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    
    List<Product> displayProducts = _searchResults;
    if (_isBrowsing) {
      displayProducts = productProvider.products.where((p) => 
        _browseCategoryId == null || p.categoryId == _browseCategoryId
      ).toList();
    }

    if (displayProducts.isEmpty) return const SizedBox.shrink();

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Container(
      constraints: isKeyboardOpen ? null : BoxConstraints(maxHeight: isLandscape ? 120 : 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isBrowsing ? settingsProvider.l10n('products') : settingsProvider.l10n('search_results'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6366F1)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() {
                    _isBrowsing = false;
                    _searchResults = [];
                    _searchController.clear();
                  }),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: ListView.separated(
                itemCount: displayProducts.length,
                separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white10 : null),
                itemBuilder: (context, index) {
                  final product = displayProducts[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      child: const Icon(Icons.add_rounded, color: Color(0xFF6366F1), size: 18),
                    ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${product.price} ${settingsProvider.settings.currencySymbol} • ${settingsProvider.l10n('stock')}: ${product.stock}', style: const TextStyle(fontSize: 11)),
                    onTap: () {
                      if (product.stock > 0) {
                        Provider.of<SaleProvider>(context, listen: false).addToCart(product);
                        if (!_isBrowsing) {
                          _searchController.clear();
                          _onSearch('');
                          FocusScope.of(context).unfocus();
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(settingsProvider.l10n('out_of_stock'))));
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, SaleProvider saleProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final total = saleProvider.getTotalWithTax(settingsProvider.settings.taxRate).toStringAsFixed(0);

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
                      '$total ${settingsProvider.settings.currencySymbol}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sub: ${saleProvider.subTotal.toStringAsFixed(0)} | Tax: ${settingsProvider.settings.taxRate.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: saleProvider.cartItems.isEmpty ? null : () => _completeSale(context, saleProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: saleProvider.cartItems.isEmpty ? Colors.grey : const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(settingsProvider.l10n('complete_sale'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                     settingsProvider.languageCode == 'my' ? 'စုစုပေါင်း (Subtotal)' : 'Subtotal', 
                     style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])
                   ),
                   Text(
                     '${saleProvider.subTotal.round()} ${settingsProvider.settings.currencySymbol}',
                     style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])
                   ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                     settingsProvider.languageCode == 'my' ? 'လျှော့စျေး (Discount)' : 'Discount',
                     style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])
                   ),
                   InkWell(
                     onTap: () => _showDiscountDialog(context, saleProvider),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.orange.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.orange.withOpacity(0.3)),
                       ),
                       child: Text(
                         '-${saleProvider.discountValue.round()} ${settingsProvider.settings.currencySymbol}${saleProvider.discountType == 'percentage' ? ' (${saleProvider.discountAmount.round()}%)' : ''}',
                         style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)
                       ),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                     'Tax (${settingsProvider.settings.taxRate.round()}%)', 
                     style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])
                   ),
                   Text(
                     '${((saleProvider.subTotal - saleProvider.discountValue) * (settingsProvider.settings.taxRate / 100)).round()} ${settingsProvider.settings.currencySymbol}',
                     style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])
                   ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(settingsProvider.l10n('total_amount'), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600])),
                   Text(
                    '$total ${settingsProvider.settings.currencySymbol}',
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
    final roundedTotal = saleProvider.getTotalWithTax(settingsProvider.settings.taxRate).round();
    final TextEditingController amountController = TextEditingController(text: roundedTotal.toString());
    final TextEditingController customerController = TextEditingController();
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final TextEditingController cashierController = TextEditingController(text: staffProvider.currentStaff?.name ?? '');
    String paymentMethod = 'Cash';
    double change = 0.0;

    final itemsToInvoice = <Map<String, dynamic>>[];
    final products = Provider.of<ProductProvider>(context, listen: false).products;
    saleProvider.cartItems.forEach((id, item) {
      final p = products.firstWhere((prod) => prod.id == item.productId);
      itemsToInvoice.add({
        'product_name': p.name,
        'price': item.price,
        'quantity': item.quantity,
      });
    });
    bool _isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: Text(settingsProvider.l10n('payment')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${settingsProvider.l10n('total_amount')}: $roundedTotal ${settingsProvider.settings.currencySymbol}', 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                ),
                Text(
                  'Sub: ${saleProvider.subTotal.round()} | Tax: ${roundedTotal - saleProvider.subTotal.round()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: customerController,
                  decoration: InputDecoration(
                    labelText: settingsProvider.l10n('customer_name'),
                    hintText: '(${settingsProvider.l10n('optional')})',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cashierController,
                  decoration: InputDecoration(
                    labelText: settingsProvider.languageCode == 'my' ? 'ငွေကိုင်အမည်' : 'Cashier Name',
                    hintText: '(${settingsProvider.l10n('optional')})',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [500, 1000, 5000, 10000, 20000].map((val) => 
                      InkWell(
                        onTap: () {
                          amountController.text = val.toString();
                          final paid = val.toDouble();
                          setState(() => change = paid - roundedTotal);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$val', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 4),
                              Icon(Icons.payments_outlined, size: 14, color: const Color(0xFF6366F1).withOpacity(0.7)),
                            ],
                          ),
                        ),
                      )
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: settingsProvider.l10n('amount_paid'),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                           amountController.clear();
                           setState(() => change = -roundedTotal.toDouble());
                        },
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final paid = double.tryParse(v) ?? 0;
                      setState(() => change = paid - roundedTotal);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('${settingsProvider.l10n('change')}: ${ (change < 0 ? 0 : change).round() } ${settingsProvider.settings.currencySymbol}',
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
              onPressed: _isProcessing || (paymentMethod == 'Cash' && (double.tryParse(amountController.text) ?? 0) < roundedTotal)
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      try {
                        final paid = double.tryParse(amountController.text) ?? 0.0;
                        final savedSale = await saleProvider.completeSale(
                          context,
                          totalAmount: roundedTotal.toDouble(),
                          discountAmount: saleProvider.discountAmount,
                          discountType: saleProvider.discountType,
                          paymentMethod: paymentMethod,
                          amountPaid: paid,
                          change: paid - roundedTotal,
                          customerName: customerController.text.isNotEmpty ? customerController.text : null,
                          cashierName: cashierController.text.isNotEmpty ? cashierController.text : staffProvider.currentStaff?.name,
                        );
                        
                        if (context.mounted) Navigator.pop(context);
                        
                        if (savedSale != null) {
                          _showInvoiceDialog(context, itemsToInvoice, savedSale);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => _isProcessing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: _isProcessing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(settingsProvider.l10n('confirm_payment')),
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

  void _showDiscountDialog(BuildContext context, SaleProvider saleProvider) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final TextEditingController controller = TextEditingController(
      text: saleProvider.discountAmount == 0 ? '' : saleProvider.discountAmount.toStringAsFixed(0)
    );
    String type = saleProvider.discountType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(settingsProvider.languageCode == 'my' ? 'လျှော့စျေး သတ်မှတ်ရန်' : 'Set Discount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleButtons(
                borderRadius: BorderRadius.circular(12),
                constraints: const BoxConstraints(minHeight: 40, minWidth: 80),
                isSelected: [type == 'percentage', type == 'fixed'],
                onPressed: (index) {
                  setState(() => type = index == 0 ? 'percentage' : 'fixed');
                },
                children: const [
                  Text('%'),
                  Text('Fixed'),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: type == 'percentage' ? 'Percentage (%)' : 'Amount (${settingsProvider.settings.currencySymbol})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                saleProvider.setDiscount(0, 'fixed');
                Navigator.pop(context);
              },
              child: Text(settingsProvider.languageCode == 'my' ? 'ဖျက်မည်' : 'Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text) ?? 0.0;
                saleProvider.setDiscount(val, type);
                Navigator.pop(context);
              },
              child: Text(settingsProvider.l10n('confirm')),
            ),
          ],
        ),
      ),
    );
  }
}
