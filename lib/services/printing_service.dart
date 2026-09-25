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
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppConfig.companyName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.Text(
                        AppConfig.appName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.orange800,
                        ),
                      ),
                      pw.Text('Support: ${AppConfig.technicalSupportEmail}'),
                      pw.Text('WhatsApp: ${AppConfig.whatsappSupportNumber}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.Text('Invoice No: ${invoice.invoiceNumber}'),
                      pw.Text('Date: ${invoice.timestamp.toString().substring(0, 10)}'),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.indigo900),
              pw.SizedBox(height: 12),

              // Patient & Doctor Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Customer Name: ${invoice.customerName}'),
                      pw.Text('Phone: ${invoice.customerPhone}'),
                    ],
                  ),
                  if (invoice.doctorName != null)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Prescribed By:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Dr. ${invoice.doctorName}'),
                        if (invoice.doctorMciNo != null) pw.Text('MCI Reg No: ${invoice.doctorMciNo}'),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Table of Items
              pw.TableHelper.fromTextArray(
                headers: ['S.No', 'Item Description', 'Batch', 'Exp', 'HSN', 'Qty', 'MRP', 'Tax %', 'Amount'],
                data: List.generate(invoice.items.length, (index) {
                  final item = invoice.items[index];
                  final expFormatted = '${item.batch.expDate.month}/${item.batch.expDate.year}';
                  return [
                    '${index + 1}',
                    '${item.product.name}\n${item.product.genericSalt}',
                    item.batch.batchNumber,
                    expFormatted,
                    item.product.hsnCode,
                    '${item.quantity}',
                    '₹${item.unitPrice.toStringAsFixed(2)}',
                    '${item.taxPercent}%',
                    '₹${item.lineTotal.toStringAsFixed(2)}',
                  ];
                }),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 16),

              // Summary & Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Payment Mode: ${invoice.paymentMode.name.toUpperCase()}'),
                      if (invoice.containsRestrictedDrugs)
                        pw.Text('Authorized Pharmacist PIN Verified: Yes',
                            style: pw.TextStyle(color: PdfColors.green900, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _pdfRow('Subtotal:', '₹${invoice.subtotal.toStringAsFixed(2)}'),
                        _pdfRow('Total GST Tax:', '₹${invoice.totalTax.toStringAsFixed(2)}'),
                        if (invoice.discountAmount > 0)
                          _pdfRow('Discount:', '-₹${invoice.discountAmount.toStringAsFixed(2)}'),
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
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Thank you for trusting LIFESPROUT Care — Powered by BillSprout ERP',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Row _pdfRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  static Future<void> printInvoice(InvoiceModel invoice) async {
    final pdfBytes = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }
}
