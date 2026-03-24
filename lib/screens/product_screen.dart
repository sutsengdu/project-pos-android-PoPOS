import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/category_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'category_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final filteredProducts = productProvider.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           p.barcode.contains(_searchQuery);
      final matchesCategory = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(settingsProvider.l10n('products')),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded, color: Color(0xFF6366F1)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen())),
            tooltip: settingsProvider.l10n('categories'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: settingsProvider.languageCode == 'my' ? 'ရှာဖွေရန်...' : 'Search...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        hint: Text(settingsProvider.languageCode == 'my' ? 'အားလုံး' : 'All'),
                        items: [
                          DropdownMenuItem<int?>(value: null, child: Text(settingsProvider.languageCode == 'my' ? 'အားလုံး' : 'All')),
                          ...categoryProvider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey[200]),
                        const SizedBox(height: 16),
                        Text(
                          settingsProvider.languageCode == 'my' ? 'ကုန်ပစ္စည်းမရှိသေးပါ' : 'No products found', 
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[500], fontSize: 18)
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(context, product, settingsProvider);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showProductDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, SettingsProvider settingsProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF6366F1)),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text(
          '${product.price} KS • ${settingsProvider.l10n('stock')}: ${product.stock}',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (v) {
            if (v == 'edit') _showProductDialog(context, product: product);
            if (v == 'delete') _showDeleteDialog(context, product);
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 20), const SizedBox(width: 8), Text(settingsProvider.l10n('edit'))])),
            PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, color: Colors.red, size: 20), const SizedBox(width: 8), Text(settingsProvider.l10n('delete'), style: const TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(product: product),
    );
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settingsProvider.l10n('delete')),
        content: Text('${settingsProvider.languageCode == 'my' ? 'ဖျက်မှာသေချာပါသလား' : 'Are you sure you want to delete'} "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(settingsProvider.l10n('cancel'))),
          TextButton(
            onPressed: () {
              Provider.of<ProductProvider>(context, listen: false).deleteProduct(product.id!);
              Navigator.pop(context);
            },
            child: Text(settingsProvider.l10n('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ProductDialog extends StatefulWidget {
  final Product? product;
  const ProductDialog({super.key, this.product});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _stockController;
  late TextEditingController _barcodeController;
  late TextEditingController _thresholdController;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _costPriceController = TextEditingController(text: widget.product?.costPrice.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _thresholdController = TextEditingController(text: widget.product?.lowStockThreshold.toString() ?? '5');
    _selectedCategoryId = widget.product?.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<CategoryProvider>(context).categories;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.product == null ? settingsProvider.l10n('new_product') : settingsProvider.l10n('edit_product'), style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: settingsProvider.l10n('product_name'), prefixIcon: const Icon(Icons.label_outline)),
              validator: (v) => v!.isEmpty ? settingsProvider.languageCode == 'my' ? 'ဖြည့်သွင်းရန်လိုအပ်သည်' : 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              isExpanded: true,
              decoration: InputDecoration(labelText: settingsProvider.l10n('category'), prefixIcon: const Icon(Icons.category_outlined)),
              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
              validator: (v) => v == null ? settingsProvider.languageCode == 'my' ? 'ဖြည့်သွင်းရန်လိုအပ်သည်' : 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: '${settingsProvider.l10n('price')} (KS)', prefixIcon: const Icon(Icons.payments_outlined)),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? settingsProvider.languageCode == 'my' ? 'ဖြည့်သွင်းရန်လိုအပ်သည်' : 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(labelText: settingsProvider.l10n('stock'), prefixIcon: const Icon(Icons.inventory_2_outlined)),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? settingsProvider.languageCode == 'my' ? 'ဖြည့်သွင်းရန်လိုအပ်သည်' : 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costPriceController,
              decoration: InputDecoration(labelText: '${settingsProvider.l10n('cost_price')} (KS)', prefixIcon: const Icon(Icons.account_balance_wallet_outlined)),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? settingsProvider.languageCode == 'my' ? 'ဖြည့်သွင်းရန်လိုအပ်သည်' : 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: InputDecoration(labelText: settingsProvider.l10n('barcode'), prefixIcon: const Icon(Icons.qr_code_outlined)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _thresholdController,
              decoration: InputDecoration(labelText: settingsProvider.l10n('threshold'), prefixIcon: const Icon(Icons.notifications_active_outlined)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(settingsProvider.l10n('cancel'), style: const TextStyle(color: Color(0xFF64748B)))),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(settingsProvider.l10n('save_product')),
        ),
      ],
    );
  }

  void _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (result != null) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text,
        categoryId: _selectedCategoryId!,
        price: double.parse(_priceController.text),
        costPrice: double.parse(_costPriceController.text),
        stock: int.parse(_stockController.text),
        barcode: _barcodeController.text,
        lowStockThreshold: int.parse(_thresholdController.text),
      );

      if (widget.product == null) {
        Provider.of<ProductProvider>(context, listen: false).addProduct(product);
      } else {
        Provider.of<ProductProvider>(context, listen: false).updateProduct(product);
      }
      Navigator.pop(context);
    }
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isPopped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isPopped) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            _isPopped = true;
            Navigator.pop(context, barcodes.first.rawValue);
          }
        },
      ),
    );
  }
}
