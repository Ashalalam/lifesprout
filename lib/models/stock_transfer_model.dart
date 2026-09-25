class StockTransferModel {
  final String id;
  final String transferNumber;
  final String sourceBranch;
  final String destinationBranch;
  final String productName;
  final String batchNumber;
  final int quantity;
  final DateTime timestamp;
  final String status; // Pending, In Transit, Received

  StockTransferModel({
    required this.id,
    required this.transferNumber,
    required this.sourceBranch,
    required this.destinationBranch,
    required this.productName,
    required this.batchNumber,
    required this.quantity,
    required this.timestamp,
    this.status = 'In Transit',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'transferNumber': transferNumber,
        'sourceBranch': sourceBranch,
        'destinationBranch': destinationBranch,
        'productName': productName,
        'batchNumber': batchNumber,
        'quantity': quantity,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  factory StockTransferModel.fromJson(Map<String, dynamic> json) => StockTransferModel(
        id: json['id'],
        transferNumber: json['transferNumber'],
        sourceBranch: json['sourceBranch'],
        destinationBranch: json['destinationBranch'],
        productName: json['productName'],
        batchNumber: json['batchNumber'],
        quantity: json['quantity'],
        timestamp: DateTime.parse(json['timestamp']),
        status: json['status'] ?? 'In Transit',
      );
}
