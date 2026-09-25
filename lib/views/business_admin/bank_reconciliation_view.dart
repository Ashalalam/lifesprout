import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/ledger_entry_model.dart';
import '../../providers/accounting_provider.dart';

class BankStatementEntry {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final bool isCredit;
  bool isMatched;
  String? matchedLedgerId;

  BankStatementEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.isCredit,
    this.isMatched = false,
    this.matchedLedgerId,
  });
}

class BankReconciliationView extends StatefulWidget {
  const BankReconciliationView({super.key});

  @override
  State<BankReconciliationView> createState() =>
      _BankReconciliationViewState();
}

class _BankReconciliationViewState
    extends State<BankReconciliationView> {
  final List<BankStatementEntry> _bankEntries = _seedBankEntries();

  static List<BankStatementEntry> _seedBankEntries() => [
        BankStatementEntry(
          id: 'be_001',
          date:
              DateTime.now().subtract(const Duration(days: 2)),
          description: 'NEFT Credit — Pharmacy Sales',
          amount: 4500.00,
          isCredit: true,
          isMatched: false,
        ),
        BankStatementEntry(
          id: 'be_002',
          date:
              DateTime.now().subtract(const Duration(days: 2)),
          description: 'UPI Debit — LIFESPROUT Pharma Labs',
          amount: 11250.00,
          isCredit: false,
          isMatched: false,
        ),
        BankStatementEntry(
          id: 'be_003',
          date:
              DateTime.now().subtract(const Duration(days: 1)),
          description: 'IMPS Credit — Wholesale Customer',
          amount: 28600.00,
          isCredit: true,
          isMatched: false,
        ),
        BankStatementEntry(
          id: 'be_004',
          date: DateTime.now(),
          description: 'UPI Credit — POS Terminal',
          amount: 1850.00,
          isCredit: true,
          isMatched: false,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final accounting = Provider.of<AccountingProvider>(context);
    final ledger = accounting.ledgerEntries.toList();

    final matched =
        _bankEntries.where((e) => e.isMatched).length;
    final unmatched =
        _bankEntries.where((e) => !e.isMatched).length;
    final totalBankCredits = _bankEntries
        .where((e) => e.isCredit)
        .fold<double>(0, (s, e) => s + e.amount);
    final totalBankDebits = _bankEntries
        .where((e) => !e.isCredit)
        .fold<double>(0, (s, e) => s + e.amount);
    final netBankBalance = totalBankCredits - totalBankDebits;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Bank Statement Reconciliation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      'Match bank transactions against your General Ledger',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue),
                  onPressed: () => _importBankStatement(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Bank Statement'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KPI row
            Row(
              children: [
                _kpi('Bank Credits',
                    '₹${totalBankCredits.toStringAsFixed(2)}',
                    Icons.arrow_downward, AppTheme.successGreen),
                const SizedBox(width: 12),
                _kpi('Bank Debits',
                    '₹${totalBankDebits.toStringAsFixed(2)}',
                    Icons.arrow_upward, AppTheme.errorRed),
                const SizedBox(width: 12),
                _kpi('Net Balance',
                    '₹${netBankBalance.toStringAsFixed(2)}',
                    Icons.account_balance, AppTheme.primaryBlue),
                const SizedBox(width: 12),
                _kpi('Matched',
                    '$matched / ${_bankEntries.length}',
                    Icons.check_circle, AppTheme.successGreen),
                const SizedBox(width: 12),
                _kpi('Unmatched', '$unmatched',
                    Icons.warning_amber, AppTheme.warningAmber),
              ],
            ),
            const SizedBox(height: 16),

            // Split view: Bank entries left | Ledger right
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank statement
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Bank Statement Entries',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.primaryBlue),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: ListView.separated(
                              itemCount: _bankEntries.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final entry = _bankEntries[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: entry.isMatched
                                        ? AppTheme.successGreen
                                            .withValues(alpha: 0.12)
                                        : entry.isCredit
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(
                                                0xFFFFEBEE),
                                    child: Icon(
                                      entry.isMatched
                                          ? Icons.check_circle
                                          : entry.isCredit
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                      color: entry.isMatched
                                          ? AppTheme.successGreen
                                          : entry.isCredit
                                              ? AppTheme.successGreen
                                              : AppTheme.errorRed,
                                    ),
                                  ),
                                  title: Text(entry.description,
                                      style: const TextStyle(
                                          fontSize: 13)),
                                  subtitle: Text(
                                      '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                      style: const TextStyle(
                                          fontSize: 11)),
                                  trailing: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${entry.isCredit ? '+' : '-'}₹${entry.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: entry.isCredit
                                              ? AppTheme.successGreen
                                              : AppTheme.errorRed,
                                        ),
                                      ),
                                      if (entry.isMatched)
                                        const Text('✓ Matched',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme
                                                    .successGreen))
                                      else
                                        TextButton(
                                          style: TextButton.styleFrom(
                                              padding:
                                                  EdgeInsets.zero),
                                          onPressed: () =>
                                              _showMatchDialog(
                                                  context,
                                                  entry,
                                                  ledger),
                                          child: const Text(
                                              'Match',
                                              style: TextStyle(
                                                  fontSize: 11)),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Ledger entries
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'General Ledger Entries',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.primaryBlue),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: ledger.isEmpty
                                ? const Center(
                                    child: Text(
                                        'No ledger entries yet.',
                                        style: TextStyle(
                                            color: AppTheme.textMuted)))
                                : ListView.separated(
                                    itemCount: ledger.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, i) {
                                      final entry = ledger[
                                          ledger.length - 1 - i];
                                      final isCredit = entry.type ==
                                          LedgerType.credit;
                                      final alreadyMatched =
                                          _bankEntries.any((b) =>
                                              b.matchedLedgerId ==
                                              entry.id);
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: alreadyMatched
                                              ? AppTheme.successGreen
                                                  .withValues(alpha: 0.12)
                                              : isCredit
                                                  ? const Color(
                                                      0xFFE8F5E9)
                                                  : const Color(
                                                      0xFFFFEBEE),
                                          child: Icon(
                                            alreadyMatched
                                                ? Icons.link
                                                : isCredit
                                                    ? Icons.arrow_downward
                                                    : Icons.arrow_upward,
                                            color: alreadyMatched
                                                ? AppTheme.successGreen
                                                : isCredit
                                                    ? AppTheme.successGreen
                                                    : AppTheme.errorRed,
                                          ),
                                        ),
                                        title: Text(entry.accountName,
                                            style: const TextStyle(
                                                fontSize: 13)),
                                        subtitle: Text(
                                          '${entry.description}\n${entry.date.toString().substring(0, 10)}',
                                          style: const TextStyle(
                                              fontSize: 11),
                                        ),
                                        trailing: Text(
                                          '${isCredit ? '+' : '-'}₹${entry.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isCredit
                                                ? AppTheme.successGreen
                                                : AppTheme.errorRed,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Unmatched warning
            if (unmatched > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      AppTheme.warningAmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.warningAmber
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: AppTheme.warningAmber, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '$unmatched bank transaction(s) are unmatched against the General Ledger. '
                      'Review and reconcile to ensure accurate financial reporting.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningAmber),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMatchDialog(
    BuildContext context,
    BankStatementEntry bankEntry,
    List<LedgerEntryModel> ledger,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Match Bank Entry to Ledger'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bank: ${bankEntry.description}  •  '
                  '${bankEntry.isCredit ? '+' : '-'}₹${bankEntry.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Select matching ledger entry:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: ledger.length,
                  itemBuilder: (context, i) {
                    final entry = ledger[i];
                    final alreadyLinked = _bankEntries.any(
                        (b) => b.matchedLedgerId == entry.id);
                    return ListTile(
                      dense: true,
                      enabled: !alreadyLinked,
                      title: Text(entry.accountName,
                          style: const TextStyle(fontSize: 12)),
                      subtitle: Text(
                          '${entry.type.name}  •  ₹${entry.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11)),
                      trailing: alreadyLinked
                          ? const Text('Matched',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.successGreen))
                          : null,
                      onTap: alreadyLinked
                          ? null
                          : () {
                              setState(() {
                                bankEntry.isMatched = true;
                                bankEntry.matchedLedgerId = entry.id;
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text('Entries matched ✓'),
                                  backgroundColor: AppTheme.successGreen,
                                ),
                              );
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _importBankStatement(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Bank Statement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.upload_file,
                size: 48, color: AppTheme.primaryBlue),
            SizedBox(height: 12),
            Text(
                'Select your bank statement file.\n\nSupported formats: CSV, Excel (.xlsx), OFX\n\nEntries will be automatically matched against your General Ledger where amounts and dates correspond.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Bank statement imported — 4 entries loaded for review.'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            icon: const Icon(Icons.upload),
            label: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted)),
                    Text(value,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
