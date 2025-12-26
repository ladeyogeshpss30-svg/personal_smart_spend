import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../models/analytics_models.dart';

class ReportPdfService {
  // =====================================================
  // ✅ RUPEE FORMATTER (UNICODE SAFE)
  // =====================================================
  static String rupee(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  // =====================================================
  // CATEGORY SUMMARY REPORT (LEGACY)
  // =====================================================
  static Future<File> generateReportPdf({
    required String title,
    required List<CategoryAnalytics> data,
    required double total,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          _buildHeader(title),
          pw.SizedBox(height: 16),
          _buildCategoryTable(data, total),
          pw.SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/Expense_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // =====================================================
  // DATE RANGE TRANSACTION REPORT (FINAL)
  // =====================================================
  static Future<File> generateDateRangeReport({
    required DateTime from,
    required DateTime to,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final pdf = pw.Document();
    final format = DateFormat('dd MMM yyyy');

    final Map<String, double> categoryTotals = {};
    double grandTotal = 0;

    for (final tx in transactions) {
      final category = tx['category_name'] as String;
      final amount = (tx['amount'] as num).toDouble();
      grandTotal += amount;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + amount;
    }

    final int transactionCount = transactions.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            'Personal Smart Spend',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'From ${format.format(from)} to ${format.format(to)}',
            style: pw.TextStyle(fontSize: 12),
          ),

          pw.SizedBox(height: 8),
          pw.Text('Total Transactions: $transactionCount'),
          pw.Text(
            'Total Amount: ${rupee(grandTotal)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.Divider(),
          pw.SizedBox(height: 16),

          // ===============================
          // TRANSACTIONS TABLE
          // ===============================
          pw.Text(
            'Transactions',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildTransactionTableWithTotal(
            transactions,
            grandTotal,
          ),

          pw.SizedBox(height: 24),

          // ===============================
          // CATEGORY SUMMARY
          // ===============================
          pw.Text(
            'Category-wise Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildCategorySummaryTable(
            categoryTotals,
            grandTotal,
          ),

          pw.SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/PSS_Date_Range_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // =====================================================
  // TRANSACTION TABLE WITH CENTERED TOTAL ROW
  // =====================================================
  static pw.Widget _buildTransactionTableWithTotal(
    List<Map<String, dynamic>> txns,
    double total,
  ) {
    final rows = <pw.TableRow>[];

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cell('Date', bold: true),
          _cell('Category', bold: true),
          _cell('Note', bold: true),
          _cell('Amount', bold: true),
        ],
      ),
    );

    for (final t in txns) {
      rows.add(
        pw.TableRow(
          children: [
            _cell(t['date'].toString().substring(0, 10)),
            _cell(t['category_name']),
            _cell((t['note'] ?? '').toString()),
            _cell(rupee((t['amount'] as num).toDouble())),
          ],
        ),
      );
    }

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              'TOTAL',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(),
          pw.SizedBox(),
          _cell(
            rupee(total),
            bold: true,
            align: pw.TextAlign.right,
          ),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(4),
        3: pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  // =====================================================
  // CELL HELPER
  // =====================================================
  static pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // =====================================================
  // CATEGORY SUMMARY TABLE
  // =====================================================
  static pw.Widget _buildCategorySummaryTable(
    Map<String, double> data,
    double total,
  ) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(width: 0.5),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColors.grey300),
      headers: const ['Category', 'Percentage', 'Amount'],
      data: [
        ...data.entries.map((e) {
          final percent = (e.value / total) * 100;
          return [
            e.key,
            '${percent.toStringAsFixed(1)}%',
            rupee(e.value),
          ];
        }),
        ['TOTAL', '100%', rupee(total)],
      ],
    );
  }

  // =====================================================
  // BASIC CATEGORY TABLE (LEGACY SUPPORT)
  // =====================================================
  static pw.Widget _buildCategoryTable(
    List<CategoryAnalytics> data,
    double total,
  ) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(width: 0.5),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColors.grey300),
      headers: const ['Category', 'Percentage', 'Amount'],
      data: [
        ...data.map((item) {
          final percent = (item.totalAmount / total) * 100;
          return [
            item.categoryName,
            '${percent.toStringAsFixed(1)}%',
            rupee(item.totalAmount),
          ];
        }),
        ['TOTAL', '100%', rupee(total)],
      ],
    );
  }

  // =====================================================
  // HEADER
  // =====================================================
  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Personal Smart Spend',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(title),
        pw.Divider(),
      ],
    );
  }

  // =====================================================
  // FOOTER
  // =====================================================
  static pw.Widget _buildFooter() {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Generated on ${DateTime.now().day}-'
        '${DateTime.now().month}-'
        '${DateTime.now().year}',
        style: pw.TextStyle(fontSize: 10),
      ),
    );
  }
}
