class Vehicle {
  final int? id; // primary key, autoincrement (null before insert)
  final String number; // e.g. "GA08V6970"
  final int partyId; // foreign key → Party
  final String type; // "Truck" | "Tractor" | "Tipper" | "Other"
  final DateTime createdAt;

  Vehicle({
    this.id,
    required this.number,
    required this.partyId,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Vehicle copyWith({
    int? id,
    String? number,
    int? partyId,
    String? type,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      number: number ?? this.number,
      partyId: partyId ?? this.partyId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'partyId': partyId,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int?,
      number: json['number'] as String,
      partyId: json['partyId'] as int,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'Vehicle(id: $id, number: $number)';
}
