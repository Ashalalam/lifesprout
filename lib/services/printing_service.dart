import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../config/app_config.dart';
import '../models/invoice_model.dart';

class PrintingService {
  static Future<Uint8List> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppConfig.companyName,
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900),
                      ),
                      pw.Text(
                        AppConfig.appName,
                        style: pw.TextStyle(
                            fontSize: 12, color: PdfColors.orange800),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Branch: ${invoice.branch}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                          'Support: ${AppConfig.technicalSupportEmail}',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(
                          'WhatsApp: ${AppConfig.whatsappSupportNumber}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800),
                      ),
                      pw.Text('Invoice No: ${invoice.invoiceNumber}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                          'Date: ${invoice.timestamp.toString().substring(0, 10)}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(
                          'Time: ${invoice.timestamp.hour.toString().padLeft(2, '0')}:${invoice.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.indigo900),
              pw.SizedBox(height: 8),

              // ── Customer & Doctor ──────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Billed To:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10)),
                      pw.Text('Name: ${invoice.customerName}',
                          style: const pw.TextStyle(fontSize: 10)),
                      if (invoice.customerPhone.isNotEmpty)
                        pw.Text('Phone: ${invoice.customerPhone}',
                            style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  if (invoice.doctorName != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Prescribed By:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10)),
                        pw.Text('Dr. ${invoice.doctorName}',
                            style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.doctorMciNo != null)
                          pw.Text('MCI Reg: ${invoice.doctorMciNo}',
                              style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 12),

              // ── Item table ─────────────────────────────────────────────────
              pw.TableHelper.fromTextArray(
                headers: [
                  'S.No',
                  'Medicine / Item',
                  'HSN',
                  'Batch',
                  'Exp',
                  'Pack',
                  'Qty',
                  'Free',
                  'MRP (₹)',
                  'Disc (₹)',
                  'Tax%',
                  'Amt (₹)',
                ],
                data: List.generate(invoice.items.length, (idx) {
                  final item = invoice.items[idx];
                  final expFmt =
                      '${item.batch.expDate.month}/${item.batch.expDate.year}';
                  final packLabel = item.product.packagingLabel;
                  return [
                    '${idx + 1}',
                    '${item.product.name}\n${item.product.genericSalt}',
                    item.product.hsnCode,
                    item.batch.batchNumber,
                    expFmt,
                    packLabel,
                    '${item.quantity}',
                    item.freeQuantity > 0 ? '${item.freeQuantity}' : '—',
                    '₹${item.unitPrice.toStringAsFixed(2)}',
                    item.lineDiscount > 0
                        ? '₹${item.lineDiscount.toStringAsFixed(2)}'
                        : '—',
                    '${item.taxPercent.toStringAsFixed(0)}%',
                    '₹${item.lineTotal.toStringAsFixed(2)}',
                  ];
                }),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 8),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.indigo900),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignments: {
                  0: pw.Alignment.center,
                  6: pw.Alignment.center,
                  7: pw.Alignment.center,
                  10: pw.Alignment.center,
                },
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FixedColumnWidth(24),
                  2: const pw.FixedColumnWidth(52),
                  4: const pw.FixedColumnWidth(40),
                  5: const pw.FixedColumnWidth(44),
                  6: const pw.FixedColumnWidth(24),
                  7: const pw.FixedColumnWidth(28),
                  10: const pw.FixedColumnWidth(32),
                },
              ),
              pw.SizedBox(height: 12),

              // ── Totals ─────────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left — payment + pharmacist note
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          'Payment Mode: ${invoice.paymentMode.name.toUpperCase()}',
                          style: const pw.TextStyle(fontSize: 10)),
                      if (invoice.containsRestrictedDrugs)
                        pw.Text(
                          'Authorised Pharmacist PIN Verified ✓',
                          style: pw.TextStyle(
                              color: PdfColors.green900,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9),
                        ),
                      if (invoice.hasFreeItems)
                        pw.Text(
                          'Includes promotional free goods.',
                          style: const pw.TextStyle(
                              color: PdfColors.orange800, fontSize: 9),
                        ),
                    ],
                  ),

                  // Right — amount summary
                  pw.Container(
                    width: 210,
                    child: pw.Column(
                      children: [
                        _pdfRow('Subtotal (before disc):',
                            '₹${(invoice.subtotal + invoice.discountAmount + invoice.totalLineDiscounts).toStringAsFixed(2)}'),
                        if (invoice.totalLineDiscounts > 0)
                          _pdfRow('Item Discounts:',
                              '-₹${invoice.totalLineDiscounts.toStringAsFixed(2)}'),
                        if (invoice.discountAmount > 0)
                          _pdfRow('Invoice Discount:',
                              '-₹${invoice.discountAmount.toStringAsFixed(2)}'),
                        _pdfRow('Taxable Value:',
                            '₹${invoice.items.fold<double>(0, (s, i) => s + i.taxableValue).toStringAsFixed(2)}'),
                        _pdfRow('CGST:',
                            '₹${invoice.items.fold<double>(0, (s, i) => s + i.cgst).toStringAsFixed(2)}'),
                        _pdfRow('SGST:',
                            '₹${invoice.items.fold<double>(0, (s, i) => s + i.sgst).toStringAsFixed(2)}'),
                        _pdfRow('Total GST:',
                            '₹${invoice.totalTax.toStringAsFixed(2)}'),
                        pw.Divider(),
                        _pdfRow(
                          'Grand Total:',
                          '₹${invoice.grandTotal.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // ── HSN summary table ──────────────────────────────────────────
              pw.Text('HSN-wise Tax Summary:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.SizedBox(height: 4),
              _buildHsnSummary(invoice),
              pw.SizedBox(height: 8),

              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Thank you for trusting ${AppConfig.companyName} — Powered by ${AppConfig.appName}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── HSN summary ────────────────────────────────────────────────────────────
  static pw.Widget _buildHsnSummary(InvoiceModel invoice) {
    final Map<String, _HsnRow> hsnMap = {};
    for (final item in invoice.items) {
      final key = '${item.product.hsnCode}|${item.taxPercent}';
      hsnMap.putIfAbsent(
          key,
          () => _HsnRow(
                hsn: item.product.hsnCode,
                rate: item.taxPercent,
                taxableValue: 0,
                cgst: 0,
                sgst: 0,
              ));
      hsnMap[key]!.taxableValue += item.taxableValue;
      hsnMap[key]!.cgst += item.cgst;
      hsnMap[key]!.sgst += item.sgst;
    }

    return pw.TableHelper.fromTextArray(
      headers: ['HSN Code', 'Tax Rate', 'Taxable Value', 'CGST', 'SGST', 'Total Tax'],
      data: hsnMap.values.map((r) => [
        r.hsn,
        '${r.rate.toStringAsFixed(0)}%',
        '₹${r.taxableValue.toStringAsFixed(2)}',
        '₹${r.cgst.toStringAsFixed(2)}',
        '₹${r.sgst.toStringAsFixed(2)}',
        '₹${(r.cgst + r.sgst).toStringAsFixed(2)}',
      ]).toList(),
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
      cellStyle: const pw.TextStyle(fontSize: 8),
    );
  }

  static pw.Row _pdfRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: 9)),
        pw.Text(value,
            style: pw.TextStyle(
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: 9)),
      ],
    );
  }

  static Future<void> printInvoice(InvoiceModel invoice) async {
    final pdfBytes = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes);
  }
}

class _HsnRow {
  final String hsn;
  final double rate;
  double taxableValue;
  double cgst;
  double sgst;
  _HsnRow({
    required this.hsn,
    required this.rate,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
  });
}
