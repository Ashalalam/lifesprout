import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/ota_service.dart';
import '../common/support_contact_modal.dart';
import '../common/sync_status_badge.dart';
import 'pos_billing_view.dart';
import 'inventory_view.dart';
import 'schedule_h_register_view.dart';
import 'gst_accounting_view.dart';
import 'stock_transfer_view.dart';
import 'purchase_order_view.dart';
import 'bank_reconciliation_view.dart';

class BusinessAdminLayout extends StatefulWidget {
  const BusinessAdminLayout({super.key});

  @override
  State<BusinessAdminLayout> createState() => _BusinessAdminLayoutState();
}

class _BusinessAdminLayoutState extends State<BusinessAdminLayout> {
  int _selectedIndex = 0;
  String _industryMode = 'Pharma Mode';

  // ── Navigation destinations and their views ─────────────────────────────
  static const _destinations = [
    _NavDest(Icons.point_of_sale, 'POS Billing'),
    _NavDest(Icons.inventory_2_outlined, 'FEFO Inventory'),
    _NavDest(Icons.verified_outlined, 'Schedule H Log'),
    _NavDest(Icons.account_balance_outlined, 'GST Accounting'),
    _NavDest(Icons.compare_arrows, 'Stock Transfer'),
    _NavDest(Icons.shopping_bag_outlined, 'Purchase Orders'),
    _NavDest(Icons.account_balance_wallet_outlined, 'Bank Recon'),
  ];

  final List<Widget> _views = const [
    PosBillingView(),
    InventoryView(),
    ScheduleHRegisterView(),
    GstAccountingView(),
    StockTransferView(),
    PurchaseOrderView(),
    BankReconciliationView(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final ota = Provider.of<OtaService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/lifesprout_logo.jpg',
              height: 36,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.local_pharmacy, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppConfig.appName} — Store Operations',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'LIFESPROUT Care | $_industryMode',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const SyncStatusBadge(),
          const SizedBox(width: 12),
          if (ota.versionInfo.updateAvailable)
            TextButton.icon(
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.accentOrange),
              onPressed: () => _showOtaUpdateModal(context, ota),
              icon: const Icon(Icons.system_update,
                  color: AppTheme.accentOrange),
              label: const Text('OTA Update Ready',
                  style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: const Icon(Icons.headset_mic),
            tooltip: 'Support Desk',
            onPressed: () => SupportContactModal.show(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (val) {
              if (val == 'logout') auth.logout();
              if (val == 'support') SupportContactModal.show(context);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                    'User: ${auth.currentUser?.name}\nRole: ${auth.currentUser?.roleDisplay}'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'support', child: Text('Support Desk')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // ── Sidebar Navigation Rail ──────────────────────────────────
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) =>
                setState(() => _selectedIndex = idx),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme:
                const IconThemeData(color: AppTheme.primaryBlue, size: 26),
            unselectedIconTheme:
                const IconThemeData(color: Colors.grey, size: 22),
            destinations: _destinations
                .asMap()
                .entries
                .map((e) => NavigationRailDestination(
                      icon: Icon(e.value.icon),
                      selectedIcon: Icon(e.value.icon,
                          color: e.key == 2
                              ? AppTheme.errorRed
                              : AppTheme.primaryBlue),
                      label: Text(e.value.label,
                          style: const TextStyle(fontSize: 11)),
                    ))
                .toList(),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune,
                        color: AppTheme.primaryBlue),
                    tooltip:
                        'Switch Industry Engine (Pharma/Retail/Wholesale)',
                    onPressed: () => _showIndustryModePicker(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // ── Main Content ──────────────────────────────────────────────
          Expanded(child: _views[_selectedIndex]),
        ],
      ),
    );
  }

  void _showOtaUpdateModal(BuildContext context, OtaService ota) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.system_update_alt, color: AppTheme.accentOrange),
            SizedBox(width: 10),
            Text('Over-The-Air (OTA) Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'New Build: ${ota.versionInfo.latestVersion}  '
                '(Current: ${ota.versionInfo.currentVersion})'),
            const SizedBox(height: 12),
            const Text('Release Highlights:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(ota.versionInfo.releaseNotes),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange),
            onPressed: () {
              ota.applyUpdate();
              Navigator.pop(ctx);
            },
            child: const Text('Apply OTA Patch Now'),
          ),
        ],
      ),
    );
  }

  void _showIndustryModePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Multi-Industry Dynamic Engine'),
        children: [
          'Pharma Mode (Default)',
          'Retail Supermarket',
          'Wholesale Distribution',
          'FMCG & Manufacturing',
          'Restaurant & Hospitality',
        ].map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _industryMode = mode);
              Navigator.pop(ctx);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    mode == _industryMode
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Text(mode, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavDest {
  final IconData icon;
  final String label;
  const _NavDest(this.icon, this.label);
}
