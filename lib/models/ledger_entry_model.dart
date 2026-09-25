enum LedgerType { debit, credit }

class LedgerEntryModel {
  final String id;
  final DateTime date;
  final String accountName; // Sales, Inventory, Cash, GST Payable, Bank
  final String description;
  final double amount;
  final LedgerType type;
  final String referenceId; // Invoice ID or Purchase Note ID

  LedgerEntryModel({
    required this.id,
    required this.date,
    required this.accountName,
    required this.description,
    required this.amount,
    required this.type,
    required this.referenceId,
  });

  LedgerEntryModel copyWith({
    String? id,
    DateTime? date,
    String? accountName,
    String? description,
    double? amount,
    LedgerType? type,
    String? referenceId,
  }) =>
      LedgerEntryModel(
        id: id ?? this.id,
        date: date ?? this.date,
        accountName: accountName ?? this.accountName,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        referenceId: referenceId ?? this.referenceId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'accountName': accountName,
        'description': description,
        'amount': amount,
        'type': type.name,
        'referenceId': referenceId,
      };

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) =>
      LedgerEntryModel(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        accountName: json['accountName'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: LedgerType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => LedgerType.debit,
        ),
        referenceId: json['referenceId'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerEntryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
