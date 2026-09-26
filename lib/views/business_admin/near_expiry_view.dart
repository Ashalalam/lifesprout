import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/inventory_provider.dart';

class NearExpiryView extends StatefulWidget {
  const NearExpiryView({super.key});

  @override
  State<NearExpiryView> createState() => _NearExpiryViewState();
}

class _NearExpiryViewState extends State<NearExpiryView> {
  int _filterDays = 90; // 30 | 60 | 90 | 180 | 365

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);

    // Gather all batches that expire within the filter window, sorted by expiry
    final alerts = <_ExpiryAlert>[];
    for (final product in inventory.products) {
      for (final batch in product.batches) {
        final days = batch.expDate.difference(DateTime.now()).inDays;
        if (days <= _filterDays) {
          alerts.add(_ExpiryAlert(
            productName: product.name,
            genericSalt: product.genericSalt,
            batchNumber: batch.batchNumber,
            expDate: batch.expDate,
            daysLeft: days,
            stockCount: batch.stockCount,
            mrp: batch.mrp,
            rackLocation: batch.rackLocation,
            isExpired: batch.isExpired,
            productId: product.id,
            batchId: batch.id,
          ));
        }
      }
    }
    alerts.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    final expiredCount  = alerts.where((a) => a.isExpired).length;
    final criticalCount = alerts.where((a) => !a.isExpired && a.daysLeft <= 30).length;
    final warningCount  = alerts.where((a) => !a.isExpired && a.daysLeft > 30 && a.daysLeft <= 60).length;
    final nearCount     = alerts.where((a) => !a.isExpired && a.daysLeft > 60).length;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Near Expiry Stock Monitor',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue),
                    ),
                    Text(
                      'FEFO Priority Alert — act before stock expires',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
                // Filter chips
                Wrap(
                  spacing: 6,
                  children: [30, 60, 90, 180]
                      .map((d) => FilterChip(
                            label: Text('${d}d'),
                            selected: _filterDays == d,
                            selectedColor:
                                AppTheme.primaryBlue.withValues(alpha: 0.15),
                            onSelected: (_) =>
                                setState(() => _filterDays = d),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Summary KPIs ──────────────────────────────────────────────────
            Row(
              children: [
                _kpi('Expired', '$expiredCount', AppTheme.errorRed,
                    Icons.dangerous),
                const SizedBox(width: 10),
                _kpi('Critical (<30d)', '$criticalCount',
                    AppTheme.warningAmber, Icons.warning_amber),
                const SizedBox(width: 10),
                _kpi('Warning (<60d)', '$warningCount',
                    const Color(0xFFD97706), Icons.schedule),
                const SizedBox(width: 10),
                _kpi('Near (≤${_filterDays}d)', '$nearCount',
                    AppTheme.primaryBlue, Icons.watch_later_outlined),
              ],
            ),
            const SizedBox(height: 16),

            // ── Batch list ────────────────────────────────────────────────────
            if (alerts.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified,
                          size: 64, color: AppTheme.successGreen),
                      const SizedBox(height: 16),
                      const Text(
                        'No batches expiring within this period!',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successGreen),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All your stock expires beyond $_filterDays days.',
                        style: const TextStyle(
                            color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        color: const Color(0xFFECEFF1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text('Batch No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text('Expiry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('Days Left', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('MRP (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text('Rack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: alerts.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final a = alerts[i];
                            return _AlertRow(alert: a);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Legend ────────────────────────────────────────────────────────
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                children: [
                  _legend('Expired', AppTheme.errorRed),
                  _legend('Critical (<30d)', AppTheme.warningAmber),
                  _legend('Warning (30–60d)', const Color(0xFFD97706)),
                  _legend('Near Expiry (60–90d)', AppTheme.primaryBlue),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _ExpiryAlert {
  final String productName;
  final String genericSalt;
  final String batchNumber;
  final DateTime expDate;
  final int daysLeft;
  final int stockCount;
  final double mrp;
  final String rackLocation;
  final bool isExpired;
  final String productId;
  final String batchId;

  const _ExpiryAlert({
    required this.productName,
    required this.genericSalt,
    required this.batchNumber,
    required this.expDate,
    required this.daysLeft,
    required this.stockCount,
    required this.mrp,
    required this.rackLocation,
    required this.isExpired,
    required this.productId,
    required this.batchId,
  });

  Color get rowColor {
    if (isExpired)        return AppTheme.errorRed.withValues(alpha: 0.06);
    if (daysLeft <= 30)   return AppTheme.warningAmber.withValues(alpha: 0.06);
    if (daysLeft <= 60)   return const Color(0xFFFFF3E0);
    return const Color(0xFFF3F4F6);
  }

  Color get textColor {
    if (isExpired)      return AppTheme.errorRed;
    if (daysLeft <= 30) return AppTheme.warningAmber;
    if (daysLeft <= 60) return const Color(0xFFD97706);
    return AppTheme.primaryBlue;
  }
}

class _AlertRow extends StatelessWidget {
  final _ExpiryAlert alert;
  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: alert.rowColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(alert.genericSalt,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(alert.batchNumber,
                style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${alert.expDate.day}/${alert.expDate.month}/${alert.expDate.year}',
              style: TextStyle(
                  fontSize: 12,
                  color: alert.textColor,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: alert.textColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                alert.isExpired ? 'EXPIRED' : '${alert.daysLeft}d',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: alert.textColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${alert.stockCount}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: alert.stockCount == 0
                      ? AppTheme.textMuted
                      : AppTheme.textDark),
            ),
          ),
          Expanded(
            child: Text('₹${alert.mrp.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(alert.rackLocation,
                style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: alert.isExpired
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                    ),
                    onPressed: () => _showWriteOffDialog(context),
                    icon: const Icon(Icons.delete_sweep, size: 14),
                    label: const Text('Write Off', style: TextStyle(fontSize: 11)),
                  )
                : OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warningAmber,
                      side: const BorderSide(color: AppTheme.warningAmber),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                    ),
                    onPressed: () => _showReturnDialog(context),
                    icon: const Icon(Icons.assignment_return, size: 14),
                    label: const Text('Return/RTV', style: TextStyle(fontSize: 11)),
                  ),
          ),
        ],
      ),
    );
  }

  void _showWriteOffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Write Off Expired Stock'),
        content: Text(
          'Write off ${alert.stockCount} units of "${alert.productName}" '
          '(Batch: ${alert.batchNumber})?\n\n'
          'This action will zero the stock count and log the write-off.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Write-off logged for ${alert.batchNumber} — ${alert.stockCount} units.'),
                  backgroundColor: AppTheme.errorRed,
                ),
              );
            },
            child: const Text('Confirm Write-Off'),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return to Vendor (RTV)'),
        content: Text(
          'Initiate a Return-to-Vendor note for "${alert.productName}" '
          '(Batch: ${alert.batchNumber}, ${alert.daysLeft} days left)?\n\n'
          'Go to Inventory → RTV Notes to complete the return.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningAmber),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Go to RTV'),
          ),
        ],
      ),
    );
  }
}
