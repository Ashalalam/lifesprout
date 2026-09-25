import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/ledger_entry_model.dart';
import '../models/invoice_model.dart';

// ── Credit / Debit Note model ──────────────────────────────────────────────
class CreditDebitNote {
  final String id;
  final String noteNumber;
  final DateTime date;
  final String type; // 'credit' | 'debit'
  final String reason;
  final String referenceInvoice;
  final double amount;

  CreditDebitNote({
    required this.id,
    required this.noteNumber,
    required this.date,
    required this.type,
    required this.reason,
    required this.referenceInvoice,
    required this.amount,
  });
}

class AccountingProvider extends ChangeNotifier {
  final List<LedgerEntryModel> _ledgerEntries = [];
  final List<InvoiceModel> _salesInvoices = [];
  final List<CreditDebitNote> _cdNotes = [];

  List<LedgerEntryModel> get ledgerEntries => List.unmodifiable(_ledgerEntries);
  List<InvoiceModel> get salesInvoices => List.unmodifiable(_salesInvoices);
  List<CreditDebitNote> get creditDebitNotes => List.unmodifiable(_cdNotes);

  AccountingProvider() {
    _seedSampleLedger();
  }

  // ── Invoice sale ──────────────────────────────────────────────────────────
  void recordInvoiceSale(InvoiceModel invoice) {
    _salesInvoices.add(invoice);
    _ledgerEntries.add(
      LedgerEntryModel(
        id: 'led_${DateTime.now().millisecondsSinceEpoch}_1',
        date: invoice.timestamp,
        accountName: 'Sales Income Account',
        description: 'POS Sale Invoice #${invoice.invoiceNumber}',
        amount: invoice.grandTotal,
        type: LedgerType.credit,
        referenceId: invoice.id,
      ),
    );
    _ledgerEntries.add(
      LedgerEntryModel(
        id: 'led_${DateTime.now().millisecondsSinceEpoch}_2',
        date: invoice.timestamp,
        accountName: 'Output GST Payable Account',
        description: 'GST Collected on Invoice #${invoice.invoiceNumber}',
        amount: invoice.totalTax,
        type: LedgerType.credit,
        referenceId: invoice.id,
      ),
    );
    notifyListeners();
  }

  String generateGstr1Json() {
    final Map<String, dynamic> gstr1Data = {
      'gstin': '07AAAAA0000A1Z5',
      'fp': '${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().year}',
      'version': 'GST3.0.4',
      'hash': 'hash',
      'b2c': _salesInvoices.map((inv) {
        return {
          'inum': inv.invoiceNumber,
          'idt': inv.timestamp.toIso8601String().substring(0, 10),
          'val': inv.grandTotal,
          'tax': inv.totalTax,
          'pos': '07',
          'typ': 'OE',
          'itms': inv.items.map((it) => {
                'hsn': it.product.hsnCode,
                'txval': it.taxableValue,
                'rt': it.taxPercent,
                'iamt': it.taxAmount,
                'camt': it.taxAmount / 2,
                'samt': it.taxAmount / 2,
                'csamt': 0,
              }).toList(),
        };
      }).toList(),
    };
    // Use proper JSON encoding — NOT .toString()
    return const JsonEncoder.withIndent('  ').convert(gstr1Data);
  }

  // ── Credit / Debit Notes ──────────────────────────────────────────────────
  void addCreditNote({
    required String reason,
    required String referenceInvoice,
    required double amount,
  }) {
    final note = CreditDebitNote(
      id: 'cdn_${DateTime.now().millisecondsSinceEpoch}',
      noteNumber:
          'CN-${DateTime.now().year}-${(_cdNotes.length + 1).toString().padLeft(4, '0')}',
      date: DateTime.now(),
      type: 'credit',
      reason: reason,
      referenceInvoice: referenceInvoice,
      amount: amount,
    );
    _cdNotes.add(note);
    // Post reversal ledger entry
    _ledgerEntries.add(LedgerEntryModel(
      id: 'led_cn_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      accountName: 'Sales Returns Account',
      description: 'Credit Note ${note.noteNumber} — $reason',
      amount: amount,
      type: LedgerType.debit,
      referenceId: referenceInvoice,
    ));
    notifyListeners();
  }

  void addDebitNote({
    required String reason,
    required String referenceInvoice,
    required double amount,
  }) {
    final note = CreditDebitNote(
      id: 'dbn_${DateTime.now().millisecondsSinceEpoch}',
      noteNumber:
          'DN-${DateTime.now().year}-${(_cdNotes.length + 1).toString().padLeft(4, '0')}',
      date: DateTime.now(),
      type: 'debit',
      reason: reason,
      referenceInvoice: referenceInvoice,
      amount: amount,
    );
    _cdNotes.add(note);
    // Post debit note ledger entry
    _ledgerEntries.add(LedgerEntryModel(
      id: 'led_dn_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      accountName: 'Purchase Adjustments Account',
      description: 'Debit Note ${note.noteNumber} — $reason',
      amount: amount,
      type: LedgerType.credit,
      referenceId: referenceInvoice,
    ));
    notifyListeners();
  }

  void _seedSampleLedger() {
    _ledgerEntries.addAll([
      LedgerEntryModel(
        id: 'led_1',
        date: DateTime.now().subtract(const Duration(days: 2)),
        accountName: 'Inventory Purchase Account',
        description: 'Purchase Batch AMX-2024-09 from Lifesprout Labs',
        amount: 11250.0,
        type: LedgerType.debit,
        referenceId: 'PO-9912',
      ),
      LedgerEntryModel(
        id: 'led_2',
        date: DateTime.now().subtract(const Duration(days: 1)),
        accountName: 'Sales Income Account',
        description: 'POS Walk-in Pharmacy Sale',
        amount: 4500.0,
        type: LedgerType.credit,
        referenceId: 'INV-10022',
      ),
    ]);
  }
}
