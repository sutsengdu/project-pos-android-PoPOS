import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sale.dart';
import '../models/product.dart';

import '../models/shop_settings.dart';

import 'package:flutter/services.dart' show rootBundle;

class InvoiceService {
  static String _shapeMyanmar(String text) {
    if (text.isEmpty) return text;
    // Advance reordering for 'e' vowel (U+1031) to assist non-shaping PDF renderers.
    // Unicode: Consonant [\u1000-\u102a\u103f] + Medials [\u103b-\u103e]* + Vowel 'e' [\u1031]
    // Visual: Vowel 'e' [\u1031] + Consonant + Medials
    final regExp = RegExp(r'([\u1000-\u102a\u103f\u1040-\u1049][\u103b-\u103e]*)\u1031');
    return text.replaceAllMapped(regExp, (m) => '\u1031${m.group(1)}');
  }

  static Future<pw.Document> _buildDocument(Sale sale, List<Map<String, dynamic>> items, ShopSettings settings) async {
    final pdf = pw.Document();
    final robotoData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final mmData = await rootBundle.load("assets/fonts/NotoSansMyanmar-Regular.ttf");
    final robotoFont = pw.Font.ttf(robotoData);
    final mmFont = pw.Font.ttf(mmData);

    final shopName = _shapeMyanmar(settings.name);
    final shopAddress = _shapeMyanmar(settings.address);
    final footerMsg = _shapeMyanmar(settings.footerMessage);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          final fontFallback = [mmFont];
          final boldStyle = pw.TextStyle(font: robotoFont, fontFallback: fontFallback, fontWeight: pw.FontWeight.bold, fontSize: 14);
          final style = pw.TextStyle(font: robotoFont, fontFallback: fontFallback, fontSize: 10);
          final titleStyle = pw.TextStyle(font: robotoFont, fontFallback: fontFallback, fontWeight: pw.FontWeight.bold, fontSize: 11);
          
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text(shopName, style: boldStyle, textAlign: pw.TextAlign.center)),
              if (settings.address.isNotEmpty) pw.Center(child: pw.Text(shopAddress, style: style, textAlign: pw.TextAlign.center)),
              if (settings.phone.isNotEmpty) pw.Center(child: pw.Text('Tel: ${settings.phone}', style: style, textAlign: pw.TextAlign.center)),
              if (settings.email.isNotEmpty) pw.Center(child: pw.Text('Email: ${settings.email}', style: style, textAlign: pw.TextAlign.center)),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.Text('Invoice #: ${sale.id}', style: style),
              pw.Text('Date: ${sale.timestamp.toString().substring(0, 16)}', style: style),
              pw.Text('Payment: ${sale.paymentMethod}', style: style),
              pw.Divider(),
              pw.Table.fromTextArray(
                border: null,
                headerStyle: titleStyle,
                cellStyle: style,
                headers: ['Item', 'Qty', 'Total'],
                data: items.map((item) => [
                  _shapeMyanmar(item['product_name']),
                  item['quantity'].toString(),
                  '${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                ]).toList(),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: style),
                  pw.Text('${items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity'])).toStringAsFixed(0)} ${settings.currencySymbol}', style: style),
                ],
              ),
              if (sale.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount ${sale.discountType == 'percentage' ? '(${sale.discountAmount.toStringAsFixed(0)}%)' : ''}:', style: style),
                    pw.Text('-${(items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity'])) - (sale.totalAmount / (1 + settings.taxRate / 100))).toStringAsFixed(0)} ${settings.currencySymbol}', style: style),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax (${settings.taxRate.toStringAsFixed(0)}%):', style: style),
                  pw.Text('${(sale.totalAmount - (sale.totalAmount / (1 + settings.taxRate / 100))).toStringAsFixed(0)} ${settings.currencySymbol}', style: style),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Total:', style: titleStyle),
                   pw.Text('${sale.totalAmount.toStringAsFixed(0)} ${settings.currencySymbol}', style: titleStyle),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Paid:', style: style),
                  pw.Text('${sale.amountPaid.toStringAsFixed(0)} ${settings.currencySymbol}', style: style),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Change:', style: style),
                  pw.Text('${(sale.change < 0 ? 0 : sale.change).toStringAsFixed(0)} ${settings.currencySymbol}', style: style),
                ],
              ),
              pw.SizedBox(height: 20),
              if (settings.footerMessage.isNotEmpty)
                pw.Center(child: pw.Text(footerMsg, style: pw.TextStyle(font: robotoFont, fontFallback: fontFallback, fontSize: 10, fontStyle: pw.FontStyle.italic), textAlign: pw.TextAlign.center)),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> printToThermal(Sale sale, List<Map<String, dynamic>> items, ShopSettings settings) async {
    final pdf = await _buildDocument(sale, items, settings);
    // Optimized for 58mm (roll57) thermal printers
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'receipt_${sale.id}',
      format: PdfPageFormat.roll57,
    );
  }

  static Future<void> generateAndShowInvoice(Sale sale, List<Map<String, dynamic>> items, ShopSettings settings) async {
    final pdf = await _buildDocument(sale, items, settings);
    // Use roll57 as default for mini thermal printers, but layoutPdf allows system selection
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(), 
      name: 'invoice_${sale.id}',
      format: PdfPageFormat.roll57
    );
  }

  static Future<void> shareInvoice(Sale sale, List<Map<String, dynamic>> items, ShopSettings settings) async {
    final pdf = await _buildDocument(sale, items, settings);
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/invoice_${sale.id}.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Invoice for Sale #${sale.id}');
  }
}
