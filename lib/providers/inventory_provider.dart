import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/batch_model.dart';
import '../models/rtv_model.dart';
import '../models/stock_transfer_model.dart';

class InventoryProvider extends ChangeNotifier {
  final List<ProductModel> _products = [];
  final List<RtvNoteModel> _rtvNotes = [];
  final List<StockTransferModel> _transfers = [];
  String _pricingTier = 'Retail'; // mutable — user can switch tier at runtime

  List<ProductModel> get products => List.unmodifiable(_products);
  List<RtvNoteModel> get rtvNotes => List.unmodifiable(_rtvNotes);
  List<StockTransferModel> get transfers => List.unmodifiable(_transfers);
  String get pricingTier => _pricingTier;

  void setPricingTier(String tier) {
    _pricingTier = tier;
    notifyListeners();
  }

  InventoryProvider() {
    _loadFromDisk();
  }

  /// Adds a brand-new product to the catalogue and persists to disk.
  void addProduct(ProductModel product) {
    _products.add(product);
    _saveToDisk();
    notifyListeners();
  }

  /// Adds a new [batch] to an existing product and persists to disk.
  void addBatchToProduct(String productId, BatchModel batch) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index < 0) return;
    _products[index].batches.add(batch);
    _saveToDisk();
    notifyListeners();
  }

  /// Update stock quantity for an existing batch (e.g. stock-in).
  void addStockToBatch({
    required String productId,
    required String batchId,
    required int additionalQty,
  }) {
    final pIdx = _products.indexWhere((p) => p.id == productId);
    if (pIdx < 0) return;
    final bIdx =
        _products[pIdx].batches.indexWhere((b) => b.id == batchId);
    if (bIdx < 0) return;
    _products[pIdx].batches[bIdx].stockCount += additionalQty;
    _saveToDisk();
    notifyListeners();
  }

  List<ProductModel> searchProducts(String query) {
    if (query.trim().isEmpty) return _products;
    final q = query.toLowerCase().trim();
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.genericSalt.toLowerCase().contains(q) ||
          p.barcode.contains(q) ||
          p.hsnCode.contains(q);
    }).toList();
  }

  List<BatchModel> getNearExpiryBatches() {
    final List<BatchModel> nearExpiryList = [];
    for (var p in _products) {
      for (var b in p.batches) {
        if (b.isNearExpiry || b.isExpired) {
          nearExpiryList.add(b);
        }
      }
    }
    return nearExpiryList;
  }

  void createRtvNote({
    required String supplierName,
    required ProductModel product,
    required BatchModel batch,
    required int quantity,
    required String reason,
  }) {
    if (quantity <= 0 || quantity > batch.stockCount) return;
    batch.stockCount -= quantity;

    final rtv = RtvNoteModel(
      id: 'rtv_${DateTime.now().millisecondsSinceEpoch}',
      rtvNumber: 'RTV-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      supplierName: supplierName,
      productName: product.name,
      batchNumber: batch.batchNumber,
      quantity: quantity,
      returnUnitPrice: batch.purchasePrice,
      reason: reason,
      date: DateTime.now(),
    );

    _rtvNotes.add(rtv);
    _saveToDisk();
    notifyListeners();
  }

  void createStockTransfer({
    required String destinationBranch,
    required ProductModel product,
    required BatchModel batch,
    required int quantity,
  }) {
    if (quantity <= 0 || quantity > batch.stockCount) return;
    batch.stockCount -= quantity;

    final transfer = StockTransferModel(
      id: 'trf_${DateTime.now().millisecondsSinceEpoch}',
      transferNumber: 'TRF-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      sourceBranch: 'Main Store / Central Warehouse',
      destinationBranch: destinationBranch,
      productName: product.name,
      batchNumber: batch.batchNumber,
      quantity: quantity,
      timestamp: DateTime.now(),
    );

    _transfers.add(transfer);
    _saveToDisk();
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = jsonEncode(_products.map((p) => p.toJson()).toList());
      final rtvJson = jsonEncode(_rtvNotes.map((r) => r.toJson()).toList());
      final trfJson = jsonEncode(_transfers.map((t) => t.toJson()).toList());

      await prefs.setString('inv_products', productsJson);
      await prefs.setString('inv_rtv', rtvJson);
      await prefs.setString('inv_transfers', trfJson);
    } catch (_) {}
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsStr = prefs.getString('inv_products');
      final rtvStr = prefs.getString('inv_rtv');
      final trfStr = prefs.getString('inv_transfers');

      if (productsStr != null) {
        final List list = jsonDecode(productsStr);
        _products.clear();
        _products.addAll(list.map((e) => ProductModel.fromJson(e)).toList());
      } else {
        _seedSampleInventory();
      }

      if (rtvStr != null) {
        final List list = jsonDecode(rtvStr);
        _rtvNotes.clear();
        _rtvNotes.addAll(list.map((e) => RtvNoteModel.fromJson(e)).toList());
      }

      if (trfStr != null) {
        final List list = jsonDecode(trfStr);
        _transfers.clear();
        _transfers.addAll(list.map((e) => StockTransferModel.fromJson(e)).toList());
      }
    } catch (_) {
      _seedSampleInventory();
    }
    notifyListeners();
  }

  void _seedSampleInventory() {
    _products.clear();
    _products.addAll([
      ProductModel(
        id: 'prod_1',
        name: 'Amoxicillin 500mg Capsules',
        genericSalt: 'Amoxicillin Trihydrate',
        barcode: '8901234567890',
        hsnCode: '30041010',
        taxPercent: 12.0,
        manufacturer: 'LIFESPROUT Pharma Labs',
        isScheduleH: true,
        batches: [
          BatchModel(
            id: 'b_101',
            batchNumber: 'AMX-2024-09',
            mfgDate: DateTime(2024, 1, 15),
            expDate: DateTime(2026, 12, 31),
            mrp: 120.0,
            purchasePrice: 75.0,
            wholesalePrice: 95.0,
            stockCount: 150,
            rackLocation: 'Rack A-2',
          ),
          BatchModel(
            id: 'b_102',
            batchNumber: 'AMX-2024-03',
            mfgDate: DateTime(2024, 2, 1),
            expDate: DateTime(2026, 10, 15),
            mrp: 120.0,
            purchasePrice: 75.0,
            wholesalePrice: 95.0,
            stockCount: 45,
            rackLocation: 'Rack A-2',
          ),
        ],
      ),
      ProductModel(
        id: 'prod_2',
        name: 'Paracetamol 650mg Tablets (Dolo/Calpol)',
        genericSalt: 'Paracetamol (Acetaminophen)',
        barcode: '8901234567891',
        hsnCode: '30049060',
        taxPercent: 12.0,
        manufacturer: 'CareSprout Remedies',
        isScheduleH: false,
        batches: [
          BatchModel(
            id: 'b_201',
            batchNumber: 'PCM-650-A',
            mfgDate: DateTime(2024, 3, 10),
            expDate: DateTime(2027, 5, 20),
            mrp: 32.50,
            purchasePrice: 18.0,
            wholesalePrice: 24.0,
            stockCount: 500,
            rackLocation: 'Rack B-1',
          ),
        ],
      ),
      ProductModel(
        id: 'prod_3',
        name: 'Alprazolam 0.5mg Tablets',
        genericSalt: 'Alprazolam',
        barcode: '8901234567892',
        hsnCode: '30049099',
        taxPercent: 12.0,
        manufacturer: 'Lifesprout Neuro',
        isScheduleH1: true,
        isNarcotic: true,
        batches: [
          BatchModel(
            id: 'b_301',
            batchNumber: 'ALP-H1-88',
            mfgDate: DateTime(2024, 5, 1),
            expDate: DateTime(2026, 11, 30),
            mrp: 85.0,
            purchasePrice: 40.0,
            wholesalePrice: 60.0,
            stockCount: 80,
            rackLocation: 'Vault Lock Box 3',
          ),
        ],
      ),
      ProductModel(
        id: 'prod_4',
        name: 'Metformin 500mg Sustained Release',
        genericSalt: 'Metformin Hydrochloride',
        barcode: '8901234567893',
        hsnCode: '30049080',
        taxPercent: 12.0,
        manufacturer: 'Diabetes Care Ltd',
        isScheduleH: true,
        batches: [
          BatchModel(
            id: 'b_401',
            batchNumber: 'MET-SR-44',
            mfgDate: DateTime(2024, 2, 10),
            expDate: DateTime(2026, 10, 05),
            mrp: 65.0,
            purchasePrice: 32.0,
            wholesalePrice: 45.0,
            stockCount: 320,
            rackLocation: 'Rack C-4',
          ),
        ],
      ),
      ProductModel(
        id: 'prod_5',
        name: 'Digital Blood Pressure Monitor',
        genericSalt: 'Medical Device / Hardware',
        barcode: '8901234567894',
        hsnCode: '90189099',
        taxPercent: 18.0,
        manufacturer: 'Lifesprout HealthTech',
        isScheduleH: false,
        batches: [
          BatchModel(
            id: 'b_501',
            batchNumber: 'BPM-2024-X',
            mfgDate: DateTime(2024, 1, 1),
            expDate: DateTime(2030, 1, 1),
            mrp: 1850.0,
            purchasePrice: 1100.0,
            wholesalePrice: 1400.0,
            stockCount: 25,
            rackLocation: 'Showcase Shelf 1',
          ),
        ],
      ),
    ]);
  }
}
