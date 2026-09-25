import 'product_model.dart';
import 'batch_model.dart';

enum PaymentMode { cash, card, upi, split, credit }

class InvoiceItem {
  final ProductModel product;
  final BatchModel batch;
  int quantity;
  double unitPrice;
  double taxPercent;

  InvoiceItem({
    required this.product,
    required this.batch,
    required this.quantity,
    required this.unitPrice,
    required this.taxPercent,
  });

  double get lineTotal => quantity * unitPrice;
  double get taxAmount => lineTotal * (taxPercent / (100 + taxPercent));
  double get taxableValue => lineTotal - taxAmount;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'batch': batch.toJson(),
        'quantity': quantity,
        'unitPrice': unitPrice,
        'taxPercent': taxPercent,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        product: ProductModel.fromJson(json['product']),
        batch: BatchModel.fromJson(json['batch']),
        quantity: json['quantity'],
        unitPrice: (json['unitPrice'] as num).toDouble(),
        taxPercent: (json['taxPercent'] as num).toDouble(),
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
  final double discountAmount;
  final PaymentMode paymentMode;
  final bool isSynced;
  final String? pharmacistPinApprovedBy;

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
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  double get totalTax => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get grandTotal => subtotal - discountAmount;

  bool get containsRestrictedDrugs =>
      items.any((item) => item.product.requiresPharmacistPin);

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
      );
}
