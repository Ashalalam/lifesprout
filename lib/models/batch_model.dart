class BatchModel {
  final String id;
  final String batchNumber;
  final DateTime mfgDate;
  final DateTime expDate;
  final double mrp;
  final double purchasePrice;
  final double wholesalePrice;
  int stockCount;
  final String rackLocation;

  BatchModel({
    required this.id,
    required this.batchNumber,
    required this.mfgDate,
    required this.expDate,
    required this.mrp,
    required this.purchasePrice,
    required this.wholesalePrice,
    required this.stockCount,
    required this.rackLocation,
  });

  bool get isExpired => DateTime.now().isAfter(expDate);

  int get daysUntilExpiry => expDate.difference(DateTime.now()).inDays;

  bool get isNearExpiry => daysUntilExpiry >= 0 && daysUntilExpiry <= 90;

  Map<String, dynamic> toJson() => {
        'id': id,
        'batchNumber': batchNumber,
        'mfgDate': mfgDate.toIso8601String(),
        'expDate': expDate.toIso8601String(),
        'mrp': mrp,
        'purchasePrice': purchasePrice,
        'wholesalePrice': wholesalePrice,
        'stockCount': stockCount,
        'rackLocation': rackLocation,
      };

  factory BatchModel.fromJson(Map<String, dynamic> json) => BatchModel(
        id: json['id'],
        batchNumber: json['batchNumber'],
        mfgDate: DateTime.parse(json['mfgDate']),
        expDate: DateTime.parse(json['expDate']),
        mrp: (json['mrp'] as num).toDouble(),
        purchasePrice: (json['purchasePrice'] as num).toDouble(),
        wholesalePrice: (json['wholesalePrice'] as num).toDouble(),
        stockCount: json['stockCount'],
        rackLocation: json['rackLocation'],
      );
}
