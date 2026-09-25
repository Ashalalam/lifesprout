class RtvNoteModel {
  final String id;
  final String rtvNumber;
  final String supplierName;
  final String productName;
  final String batchNumber;
  final int quantity;
  final double returnUnitPrice;
  final String reason; // Expired, Damaged, Recall, Overstock
  final DateTime date;

  RtvNoteModel({
    required this.id,
    required this.rtvNumber,
    required this.supplierName,
    required this.productName,
    required this.batchNumber,
    required this.quantity,
    required this.returnUnitPrice,
    required this.reason,
    required this.date,
  });

  double get totalRefundAmount => quantity * returnUnitPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rtvNumber': rtvNumber,
        'supplierName': supplierName,
        'productName': productName,
        'batchNumber': batchNumber,
        'quantity': quantity,
        'returnUnitPrice': returnUnitPrice,
        'reason': reason,
        'date': date.toIso8601String(),
      };

  factory RtvNoteModel.fromJson(Map<String, dynamic> json) => RtvNoteModel(
        id: json['id'],
        rtvNumber: json['rtvNumber'],
        supplierName: json['supplierName'],
        productName: json['productName'],
        batchNumber: json['batchNumber'],
        quantity: json['quantity'],
        returnUnitPrice: (json['returnUnitPrice'] as num).toDouble(),
        reason: json['reason'],
        date: DateTime.parse(json['date']),
      );
}
