import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/batch_model.dart';
import '../models/invoice_model.dart';

class PosProvider extends ChangeNotifier {
  final List<InvoiceItem> _cartItems = [];
  String _customerName = 'Walk-in Customer';
  String _customerPhone = '+447747571513';
  String? _doctorName = 'Dr. A. Smith';
  String? _doctorMciNo = 'MCI-88492';
  double _discountAmount = 0.0;
  PaymentMode _paymentMode = PaymentMode.cash;
  String _pricingTier = 'Retail'; // Retail, Wholesale, Distributor, Loyalty

  List<InvoiceItem> get cartItems => List.unmodifiable(_cartItems);
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String? get doctorName => _doctorName;
  String? get doctorMciNo => _doctorMciNo;
  double get discountAmount => _discountAmount;
  String get pricingTier => _pricingTier;

  void setPricingTier(String tier) {
    _pricingTier = tier;
    notifyListeners();
  }
  PaymentMode get paymentMode => _paymentMode;

  double get subtotal => _cartItems.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get totalTax => _cartItems.fold(0.0, (sum, i) => sum + i.taxAmount);
  double get grandTotal => subtotal - _discountAmount;

  bool get requiresPharmacistPin =>
      _cartItems.any((item) => item.product.requiresPharmacistPin);

  void setCustomerDetails(String name, String phone, {String? docName, String? docMci}) {
    _customerName = name.isEmpty ? 'Walk-in Customer' : name;
    _customerPhone = phone.isEmpty ? '+447747571513' : phone;
    _doctorName = docName;
    _doctorMciNo = docMci;
    notifyListeners();
  }

  void setPaymentMode(PaymentMode mode) {
    _paymentMode = mode;
    notifyListeners();
  }

  void setDiscount(double amount) {
    _discountAmount = amount;
    notifyListeners();
  }

  void addToCart(ProductModel product, {BatchModel? selectedBatch}) {
    final batchToUse = selectedBatch ?? product.fefoBatch;
    if (batchToUse == null) return;

    // Apply correct price based on active pricing tier
    final double unitPrice = _resolvePriceTier(product, batchToUse);

    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id && item.batch.id == batchToUse.id,
    );

    if (existingIndex >= 0) {
      if (_cartItems[existingIndex].quantity < batchToUse.stockCount) {
        _cartItems[existingIndex].quantity++;
      }
    } else {
      _cartItems.add(
        InvoiceItem(
          product: product,
          batch: batchToUse,
          quantity: 1,
          unitPrice: unitPrice,
          taxPercent: product.taxPercent,
        ),
      );
    }
    notifyListeners();
  }

  /// Returns the correct unit price for the active pricing tier.
  double _resolvePriceTier(ProductModel product, BatchModel batch) {
    switch (_pricingTier) {
      case 'Wholesale':
        return batch.wholesalePrice > 0 ? batch.wholesalePrice : batch.mrp;
      case 'Distributor':
        // Distributor gets 10% below wholesale
        final ws =
            batch.wholesalePrice > 0 ? batch.wholesalePrice : batch.mrp;
        return ws * 0.90;
      case 'Loyalty':
        // Loyalty customers get 5% discount on MRP
        return batch.mrp * 0.95;
      case 'Retail':
      default:
        return batch.mrp;
    }
  }

  void updateQuantity(InvoiceItem item, int newQty) {
    if (newQty <= 0) {
      _cartItems.remove(item);
    } else if (newQty <= item.batch.stockCount) {
      item.quantity = newQty;
    }
    notifyListeners();
  }

  void removeFromCart(InvoiceItem item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _discountAmount = 0.0;
    _customerName = 'Walk-in Customer';
    _customerPhone = '+447747571513';
    notifyListeners();
  }

  InvoiceModel checkout({required bool isOnline, String? pinApprovedBy}) {
    final invoiceNum = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final invoice = InvoiceModel(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: invoiceNum,
      timestamp: DateTime.now(),
      customerName: _customerName,
      customerPhone: _customerPhone,
      doctorName: _doctorName,
      doctorMciNo: _doctorMciNo,
      items: List.from(_cartItems),
      discountAmount: _discountAmount,
      paymentMode: _paymentMode,
      isSynced: isOnline,
      pharmacistPinApprovedBy: pinApprovedBy,
    );

    // Deduct stock locally
    for (var item in _cartItems) {
      item.batch.stockCount -= item.quantity;
    }

    clearCart();
    return invoice;
  }
}
