import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/invoice_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/accounting_provider.dart';
import '../../services/sync_service.dart';
import '../../services/printing_service.dart';
import '../../services/support_service.dart';
import '../common/pharmacist_pin_dialog.dart';
import '../common/barcode_scanner_modal.dart';

class PosBillingView extends StatefulWidget {
  const PosBillingView({super.key});

  @override
  State<PosBillingView> createState() => _PosBillingViewState();
}

class _PosBillingViewState extends State<PosBillingView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();
  final TextEditingController _custNameCtrl = TextEditingController(text: 'Walk-in Customer');
  final TextEditingController _custPhoneCtrl = TextEditingController(text: '+447747571513');
  final TextEditingController _docNameCtrl = TextEditingController(text: 'Dr. A. Smith');
  final TextEditingController _docMciCtrl = TextEditingController(text: 'MCI-88492');

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final posProvider = Provider.of<PosProvider>(context);
    final filteredProducts = inventoryProvider.searchProducts(_searchQuery);

    return Row(
      children: [
        // Left Column: Catalog Search & Products Grid
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fast Search & Barcode Scan Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Scan Barcode or Search Product / Generic Salt (e.g. Paracetamol)...',
                          prefixIcon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryBlue),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Camera barcode scanner button
                    Tooltip(
                      message: 'Open Camera Barcode Scanner',
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                        onPressed: () async {
                          final code =
                              await BarcodeScannerModal.show(context);
                          if (code != null && mounted) {
                            _searchCtrl.text = code;
                            setState(() => _searchQuery = code);
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Scan'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: inventoryProvider.pricingTier,
                      items: ['Retail', 'Wholesale', 'Distributor', 'Loyalty']
                          .map((t) => DropdownMenuItem(value: t, child: Text('$t Tier')))
                          .toList(),
                      onChanged: (tier) {
                        if (tier != null) inventoryProvider.setPricingTier(tier);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Product Grid / List
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching medicines or items found.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final fefoBatch = product.fefoBatch;
                            final isOutOfStock = fefoBatch == null || fefoBatch.stockCount <= 0;

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: product.requiresPharmacistPin
                                      ? AppTheme.errorRed.withValues(alpha: 0.4)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (product.isScheduleH || product.isScheduleH1)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  product.isScheduleH1 ? 'SCH H1' : 'SCH H',
                                                  style: const TextStyle(
                                                    color: AppTheme.errorRed,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Salt: ${product.genericSalt}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        if (fefoBatch != null)
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE8F5E9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'FEFO: ${fefoBatch.batchNumber}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2E7D32),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Exp: ${fefoBatch.expDate.month}/${fefoBatch.expDate.year}',
                                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '₹${fefoBatch?.mrp.toStringAsFixed(2) ?? '0.00'}',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                            Text(
                                              'Stock: ${product.totalStock}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isOutOfStock ? AppTheme.errorRed : AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isOutOfStock ? Colors.grey : AppTheme.primaryBlue,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          onPressed: isOutOfStock
                                              ? null
                                              : () {
                                                  posProvider.addToCart(product);
                                                },
                                          icon: const Icon(Icons.add_shopping_cart, size: 14),
                                          label: const Text('Add', style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Right Column: POS Cart & Checkout Panel
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Billing Cart',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                      if (posProvider.cartItems.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => posProvider.clearCart(),
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorRed),
                          label: const Text('Clear', style: TextStyle(color: AppTheme.errorRed, fontSize: 11)),
                        ),
                    ],
                  ),
                  const Divider(height: 12),

                  // Customer & Doctor Linkage Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _custNameCtrl,
                          decoration: const InputDecoration(labelText: 'Customer Name', isDense: true),
                          onChanged: (val) => posProvider.setCustomerDetails(val, _custPhoneCtrl.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _custPhoneCtrl,
                          decoration: const InputDecoration(labelText: 'Phone No', isDense: true),
                          onChanged: (val) => posProvider.setCustomerDetails(_custNameCtrl.text, val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _docNameCtrl,
                          decoration: const InputDecoration(labelText: 'Doctor Name (Rx)', isDense: true),
                          onChanged: (val) => posProvider.setCustomerDetails(
                            _custNameCtrl.text,
                            _custPhoneCtrl.text,
                            docName: val,
                            docMci: _docMciCtrl.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _docMciCtrl,
                          decoration: const InputDecoration(labelText: 'MCI Reg No', isDense: true),
                          onChanged: (val) => posProvider.setCustomerDetails(
                            _custNameCtrl.text,
                            _custPhoneCtrl.text,
                            docName: _docNameCtrl.text,
                            docMci: val,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Cart Item List
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: posProvider.cartItems.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Cart is empty. Click "+ Add" on items.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: posProvider.cartItems.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = posProvider.cartItems[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  item.product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                subtitle: Text(
                                  'Batch: ${item.batch.batchNumber} | Tax: ${item.taxPercent}%',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                                      onPressed: () => posProvider.updateQuantity(item, item.quantity - 1),
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 18),
                                      onPressed: () => posProvider.updateQuantity(item, item.quantity + 1),
                                    ),
                                    Text(
                                      '₹${item.lineTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 12),

                  // Summary Calculation & Payment Mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 12)),
                      Text('₹${posProvider.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total GST Tax:', style: TextStyle(fontSize: 12)),
                      Text('₹${posProvider.totalTax.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Discount (₹): ', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _discountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, hintText: '0.00'),
                          onChanged: (val) {
                            final d = double.tryParse(val) ?? 0.0;
                            posProvider.setDiscount(d);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                      Text(
                        '₹${posProvider.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Payment Mode Buttons
                  Wrap(
                    spacing: 4,
                    children: PaymentMode.values.map((mode) {
                      final isSelected = posProvider.paymentMode == mode;
                      return ChoiceChip(
                        label: Text(mode.name.toUpperCase()),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryBlue,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 10),
                        onSelected: (_) => posProvider.setPaymentMode(mode),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: posProvider.requiresPharmacistPin ? AppTheme.errorRed : AppTheme.primaryBlue,
                      ),
                      onPressed: posProvider.cartItems.isEmpty
                          ? null
                          : () => _handleCheckout(context, posProvider),
                      icon: Icon(
                        posProvider.requiresPharmacistPin ? Icons.security : Icons.check_circle,
                        size: 18,
                      ),
                      label: Text(
                        posProvider.requiresPharmacistPin ? 'Authorize & Pay Invoice' : 'Complete Sale & Print',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCheckout(BuildContext context, PosProvider posProvider) async {
    final syncService = Provider.of<SyncService>(context, listen: false);
    final accountingProvider = Provider.of<AccountingProvider>(context, listen: false);

    String? pinApprovedBy;

    // Check if Schedule H/H1 pin authorization is needed
    if (posProvider.requiresPharmacistPin) {
      final approved = await PharmacistPinDialog.show(context);
      if (!approved) return; // Cancelled
      pinApprovedBy = 'Pharmacist PIN #1234';
    }

    final invoice = posProvider.checkout(
      isOnline: syncService.isOnline,
      pinApprovedBy: pinApprovedBy,
    );

    // Queue in sync service and record in accounting ledger
    syncService.queueInvoiceForSync(invoice);
    accountingProvider.recordInvoiceSale(invoice);

    // Guard BuildContext use after async gap with a mounted check on the State
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    _showInvoiceSuccessDialog(this.context, invoice);
  }
  void _showInvoiceSuccessDialog(BuildContext context, InvoiceModel invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
            SizedBox(width: 10),
            Text('Invoice Billed Successfully!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice No: ${invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Customer: ${invoice.customerName} (${invoice.customerPhone})'),
            Text('Grand Total: ₹${invoice.grandTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Choose receipt distribution channel:', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: AppTheme.primaryBlue),
            tooltip: 'Print A4 PDF / ESC Thermal',
            onPressed: () {
              PrintingService.printInvoice(invoice);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            onPressed: () {
              SupportService.shareInvoiceWhatsApp(invoice);
            },
            icon: const Icon(Icons.send),
            label: const Text('Send WhatsApp Receipt'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Next Transaction'),
          ),
        ],
      ),
    );
  }
}
