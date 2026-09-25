import 'batch_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String genericSalt; // e.g. Paracetamol 500mg
  final String barcode;
  final String hsnCode;
  final double taxPercent; // 0, 5, 12, 18, 28
  final String manufacturer;
  final bool isScheduleH;
  final bool isScheduleH1;
  final bool isNarcotic;
  final List<BatchModel> batches;

  ProductModel({
    required this.id,
    required this.name,
    required this.genericSalt,
    required this.barcode,
    required this.hsnCode,
    required this.taxPercent,
    required this.manufacturer,
    this.isScheduleH = false,
    this.isScheduleH1 = false,
    this.isNarcotic = false,
    required this.batches,
  });

  bool get requiresPharmacistPin => isScheduleH || isScheduleH1 || isNarcotic;

  // FEFO Sorting: Return batch closest to expiry first (ignoring already expired ones)
  BatchModel? get fefoBatch {
    final validBatches = batches.where((b) => b.stockCount > 0 && !b.isExpired).toList();
    if (validBatches.isEmpty) return null;
    validBatches.sort((a, b) => a.expDate.compareTo(b.expDate));
    return validBatches.first;
  }

  int get totalStock => batches.fold(0, (sum, b) => sum + b.stockCount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'genericSalt': genericSalt,
        'barcode': barcode,
        'hsnCode': hsnCode,
        'taxPercent': taxPercent,
        'manufacturer': manufacturer,
        'isScheduleH': isScheduleH,
        'isScheduleH1': isScheduleH1,
        'isNarcotic': isNarcotic,
        'batches': batches.map((b) => b.toJson()).toList(),
      };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'],
        name: json['name'],
        genericSalt: json['genericSalt'],
        barcode: json['barcode'],
        hsnCode: json['hsnCode'],
        taxPercent: (json['taxPercent'] as num).toDouble(),
        manufacturer: json['manufacturer'],
        isScheduleH: json['isScheduleH'] ?? false,
        isScheduleH1: json['isScheduleH1'] ?? false,
        isNarcotic: json['isNarcotic'] ?? false,
        batches: (json['batches'] as List)
            .map((b) => BatchModel.fromJson(b))
            .toList(),
      );
}
