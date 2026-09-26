import 'product_model.dart';
import 'batch_model.dart';

enum PaymentMode { cash, card, upi, split, credit }

class InvoiceItem {
  final ProductModel product;
  final BatchModel batch;
  int quantity;
  int freeQuantity;       // Free goods / schemes (not charged)
  double unitPrice;
  double taxPercent;
  double lineDiscount;    // Item-level discount amount (₹)

  InvoiceItem({
    required this.product,
    required this.batch,
    required this.quantity,
    this.freeQuantity = 0,
    required this.unitPrice,
    required this.taxPercent,
    this.lineDiscount = 0.0,
  });

  /// Billed quantity only (free qty is not charged)
  int get billedQuantity => quantity;

  double get grossLineTotal  => quantity * unitPrice;
  double get lineTotal       => grossLineTotal - lineDiscount;
  double get taxAmount       => lineTotal * (taxPercent / (100 + taxPercent));
  double get taxableValue    => lineTotal - taxAmount;
  double get cgst            => taxAmount / 2;
  double get sgst            => taxAmount / 2;

  /// Display string e.g. "3 strips + 1 Free"
  String get quantityDisplay {
    if (freeQuantity > 0) return '$quantity + $freeQuantity Free';
    return '$quantity';
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'batch': batch.toJson(),
        'quantity': quantity,
        'freeQuantity': freeQuantity,
        'unitPrice': unitPrice,
        'taxPercent': taxPercent,
        'lineDiscount': lineDiscount,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        product: ProductModel.fromJson(json['product']),
        batch: BatchModel.fromJson(json['batch']),
        quantity: json['quantity'],
        freeQuantity: json['freeQuantity'] ?? 0,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        taxPercent: (json['taxPercent'] as num).toDouble(),
        lineDiscount: (json['lineDiscount'] as num? ?? 0).toDouble(),
      );
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final DateTime timestamp;
  final String customerName;
  final String customerPhone;
  final String? doctorName;
  final String? doctorMciNo;
  final List<InvoiceItem> items;
  final double discountAmount;   // Invoice-level discount (₹)
  final PaymentMode paymentMode;
  final bool isSynced;
  final String? pharmacistPinApprovedBy;
  final String branch;           // Dispensing branch name

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.timestamp,
    required this.customerName,
    required this.customerPhone,
    this.doctorName,
    this.doctorMciNo,
    required this.items,
    this.discountAmount = 0.0,
    required this.paymentMode,
    this.isSynced = false,
    this.pharmacistPinApprovedBy,
    this.branch = 'Main Store',
  });

  double get subtotal    => items.fold(0, (s, i) => s + i.lineTotal);
  double get totalTax    => items.fold(0, (s, i) => s + i.taxAmount);
  double get totalLineDiscounts => items.fold(0, (s, i) => s + i.lineDiscount);
  double get grandTotal  => subtotal - discountAmount;

  bool get containsRestrictedDrugs =>
      items.any((i) => i.product.requiresPharmacistPin);

  bool get hasFreeItems =>
      items.any((i) => i.freeQuantity > 0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'timestamp': timestamp.toIso8601String(),
        'customerName': customerName,
        'customerPhone': customerPhone,
        'doctorName': doctorName,
        'doctorMciNo': doctorMciNo,
        'items': items.map((i) => i.toJson()).toList(),
        'discountAmount': discountAmount,
        'paymentMode': paymentMode.name,
        'isSynced': isSynced,
        'pharmacistPinApprovedBy': pharmacistPinApprovedBy,
        'branch': branch,
      };

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        id: json['id'],
        invoiceNumber: json['invoiceNumber'],
        timestamp: DateTime.parse(json['timestamp']),
        customerName: json['customerName'],
        customerPhone: json['customerPhone'],
        doctorName: json['doctorName'],
        doctorMciNo: json['doctorMciNo'],
        items: (json['items'] as List)
            .map((i) => InvoiceItem.fromJson(i))
            .toList(),
        discountAmount: (json['discountAmount'] as num).toDouble(),
        paymentMode: PaymentMode.values.firstWhere(
          (e) => e.name == json['paymentMode'],
          orElse: () => PaymentMode.cash,
        ),
        isSynced: json['isSynced'] ?? false,
        pharmacistPinApprovedBy: json['pharmacistPinApprovedBy'],
        branch: json['branch'] ?? 'Main Store',
      );
}
