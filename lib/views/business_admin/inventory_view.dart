import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/batch_model.dart';
import '../../providers/inventory_provider.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryBlue,
            tabs: const [
              Tab(icon: Icon(Icons.inventory_2), text: 'FEFO Stock & Batches'),
              Tab(icon: Icon(Icons.assignment_return), text: 'Return To Vendor (RTV)'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'Inter-Branch Transfers'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Stock & Batches
          _buildStockTab(context, inventoryProvider),
          // Tab 2: RTV Debit Notes
          _buildRtvTab(context, inventoryProvider),
          // Tab 3: Stock Transfers
          _buildTransfersTab(context, inventoryProvider),
        ],
      ),
    );
  }

  Widget _buildStockTab(BuildContext context, InventoryProvider inventoryProvider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FEFO Inventory & Batch Register',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber),
                    onPressed: () => _showCreateRtvModal(context, inventoryProvider),
                    icon: const Icon(Icons.assignment_return),
                    label: const Text('Return to Vendor (RTV)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                    onPressed: () => _showStockTransferModal(context, inventoryProvider),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Inter-Branch Transfer'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expiry Alert Banner
          Builder(builder: (context) {
            final nearExpiryList = inventoryProvider.getNearExpiryBatches();
            if (nearExpiryList.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningAmber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.warningAmber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'FEFO WARNING: ${nearExpiryList.length} medicine batch(es) are nearing expiry within 90 days. Prioritize these batches for fast POS dispatching.',
                      style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Table of Stock & FEFO Batches
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: inventoryProvider.products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = inventoryProvider.products[index];
                  return ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      child: const Icon(Icons.medication, color: AppTheme.primaryBlue),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Generic Salt: ${product.genericSalt} | HSN: ${product.hsnCode} | GST: ${product.taxPercent}% | Total Stock: ${product.totalStock}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (product.isScheduleH || product.isScheduleH1)
                          Chip(
                            label: Text(product.isScheduleH1 ? 'SCH H1' : 'SCH H'),
                            backgroundColor: AppTheme.errorRed.withValues(alpha: 0.15),
                            labelStyle: const TextStyle(color: AppTheme.errorRed, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                    children: [
                      Container(
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Batches (FEFO Sorted):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                            ),
                            const SizedBox(height: 8),
                            Table(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1.5),
                                2: FlexColumnWidth(1.5),
                                3: FlexColumnWidth(1),
                                4: FlexColumnWidth(1),
                                5: FlexColumnWidth(1.5),
                              },
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Color(0xFFECEFF1)),
                                  children: [
                                    Padding(padding: EdgeInsets.all(6), child: Text('Batch No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Mfg Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Exp Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Rack Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                                ...product.batches.map((batch) {
                                  final expText = '${batch.expDate.month}/${batch.expDate.year}';
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(6), child: Text(batch.batchNumber, style: const TextStyle(fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text('${batch.mfgDate.month}/${batch.mfgDate.year}', style: const TextStyle(fontSize: 12))),
                                      Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Text(
                                          expText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: batch.isNearExpiry ? AppTheme.errorRed : Colors.black87,
                                            fontWeight: batch.isNearExpiry ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      Padding(padding: const EdgeInsets.all(6), child: Text('₹${batch.mrp}', style: const TextStyle(fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text('${batch.stockCount}', style: const TextStyle(fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text(batch.rackLocation, style: const TextStyle(fontSize: 12))),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRtvTab(BuildContext context, InventoryProvider inventoryProvider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Return to Vendor (RTV) Debit Notes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.warningAmber),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber),
                onPressed: () => _showCreateRtvModal(context, inventoryProvider),
                icon: const Icon(Icons.add),
                label: const Text('+ Issue RTV Debit Note'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: inventoryProvider.rtvNotes.isEmpty
                ? const Center(
                    child: Text('No Return to Vendor debit notes issued yet.'),
                  )
                : Card(
                    child: ListView.separated(
                      itemCount: inventoryProvider.rtvNotes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final rtv = inventoryProvider.rtvNotes[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFF3E0),
                            child: Icon(Icons.assignment_return, color: AppTheme.warningAmber),
                          ),
                          title: Text('${rtv.rtvNumber} — ${rtv.productName}'),
                          subtitle: Text(
                            'Supplier: ${rtv.supplierName} | Batch: ${rtv.batchNumber}\nQty Returned: ${rtv.quantity} | Reason: ${rtv.reason}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '₹${rtv.totalRefundAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.warningAmber),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransfersTab(BuildContext context, InventoryProvider inventoryProvider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Inter-Branch Stock Movement Register',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                onPressed: () => _showStockTransferModal(context, inventoryProvider),
                icon: const Icon(Icons.add),
                label: const Text('+ Create Branch Transfer'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: inventoryProvider.transfers.isEmpty
                ? const Center(
                    child: Text('No inter-branch stock transfers logged.'),
                  )
                : Card(
                    child: ListView.separated(
                      itemCount: inventoryProvider.transfers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final trf = inventoryProvider.transfers[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE3F2FD),
                            child: Icon(Icons.swap_horiz, color: AppTheme.primaryBlue),
                          ),
                          title: Text('${trf.transferNumber} — ${trf.productName}'),
                          subtitle: Text(
                            'From: ${trf.sourceBranch} ➔ To: ${trf.destinationBranch}\nBatch: ${trf.batchNumber} | Qty: ${trf.quantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Chip(
                            label: Text(trf.status),
                            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateRtvModal(BuildContext context, InventoryProvider inventoryProvider) {
    if (inventoryProvider.products.isEmpty) return;
    ProductModel selectedProduct = inventoryProvider.products.first;
    BatchModel? selectedBatch = selectedProduct.fefoBatch;
    final qtyCtrl = TextEditingController(text: '10');
    final supplierCtrl = TextEditingController(text: 'Lifesprout Wholesale Depot');
    final reasonCtrl = TextEditingController(text: 'Nearing Expiry / Return Request');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Text('Issue Return to Vendor (RTV) Debit Note'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<ProductModel>(
                  isExpanded: true,
                  value: selectedProduct,
                  items: inventoryProvider.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (p) {
                    if (p != null) {
                      setModalState(() {
                        selectedProduct = p;
                        selectedBatch = p.fefoBatch;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (selectedProduct.batches.isNotEmpty)
                  DropdownButton<BatchModel>(
                    isExpanded: true,
                    value: selectedBatch ?? selectedProduct.batches.first,
                    items: selectedProduct.batches.map((b) => DropdownMenuItem(value: b, child: Text('Batch: ${b.batchNumber} (Stock: ${b.stockCount})'))).toList(),
                    onChanged: (b) => setModalState(() => selectedBatch = b),
                  ),
                const SizedBox(height: 8),
                TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier Vendor Name')),
                const SizedBox(height: 8),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity to Return')),
                const SizedBox(height: 8),
                TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Return Reason')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber),
                onPressed: () {
                  if (selectedBatch != null) {
                    inventoryProvider.createRtvNote(
                      supplierName: supplierCtrl.text,
                      product: selectedProduct,
                      batch: selectedBatch!,
                      quantity: int.tryParse(qtyCtrl.text) ?? 1,
                      reason: reasonCtrl.text,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Issue Debit Note'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStockTransferModal(BuildContext context, InventoryProvider inventoryProvider) {
    if (inventoryProvider.products.isEmpty) return;
    ProductModel selectedProduct = inventoryProvider.products.first;
    BatchModel? selectedBatch = selectedProduct.fefoBatch;
    final qtyCtrl = TextEditingController(text: '20');
    final branchCtrl = TextEditingController(text: 'Lifesprout Branch #2 - Downtown Sector');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Text('Create Inter-Branch Stock Transfer Pass'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<ProductModel>(
                  isExpanded: true,
                  value: selectedProduct,
                  items: inventoryProvider.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (p) {
                    if (p != null) {
                      setModalState(() {
                        selectedProduct = p;
                        selectedBatch = p.fefoBatch;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (selectedProduct.batches.isNotEmpty)
                  DropdownButton<BatchModel>(
                    isExpanded: true,
                    value: selectedBatch ?? selectedProduct.batches.first,
                    items: selectedProduct.batches.map((b) => DropdownMenuItem(value: b, child: Text('Batch: ${b.batchNumber} (Stock: ${b.stockCount})'))).toList(),
                    onChanged: (b) => setModalState(() => selectedBatch = b),
                  ),
                const SizedBox(height: 8),
                TextField(controller: branchCtrl, decoration: const InputDecoration(labelText: 'Destination Branch Store')),
                const SizedBox(height: 8),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity to Transfer')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (selectedBatch != null) {
                    inventoryProvider.createStockTransfer(
                      destinationBranch: branchCtrl.text,
                      product: selectedProduct,
                      batch: selectedBatch!,
                      quantity: int.tryParse(qtyCtrl.text) ?? 1,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Dispatch Stock Pass'),
              ),
            ],
          );
        },
      ),
    );
  }
}
