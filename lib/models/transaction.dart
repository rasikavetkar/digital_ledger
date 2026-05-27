class Transaction {
  final int? id; // primary key, autoincrement (null before insert)
  final int? vehicleId; // foreign key → Vehicle (optional)
  final DateTime date;
  final int quantity; // number of sand loads
  final double amount;
  final String type; // "credit" | "debit"
  final String? remarks; // nullable
  final DateTime createdAt;

  Transaction({
    this.id,
    this.vehicleId,
    required this.date,
    required this.quantity,
    required this.amount,
    required this.type,
    this.remarks,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Transaction copyWith({
    int? id,
    int? vehicleId,
    DateTime? date,
    int? quantity,
    double? amount,
    String? type,
    String? remarks,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'amount': amount,
      'type': type,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int?,
      vehicleId: json['vehicleId'] as int,
      date: DateTime.parse(json['date'] as String),
      quantity: json['quantity'] as int,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'Transaction(id: $id, vehicleId: $vehicleId, type: $type, amount: $amount)';
}
