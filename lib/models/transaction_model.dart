class Transaction {
  final String id;
  final String type; // 'ingreso' o 'gasto'
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String? farmId;
  final String? cropId;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.farmId,
    this.cropId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'farmId': farmId,
      'cropId': cropId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      type: json['type'] ?? 'gasto',
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      farmId: json['farmId'],
      cropId: json['cropId'],
    );
  }

  Transaction copyWith({
    String? id,
    String? type,
    String? category,
    double? amount,
    String? description,
    DateTime? date,
    String? farmId,
    String? cropId,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      farmId: farmId ?? this.farmId,
      cropId: cropId ?? this.cropId,
    );
  }
}

class FinancialSummary {
  final double totalIngresos;
  final double totalGastos;
  final double balance;
  final Map<String, double> ingresosPorCategoria;
  final Map<String, double> gastosPorCategoria;

  FinancialSummary({
    required this.totalIngresos,
    required this.totalGastos,
    required this.balance,
    required this.ingresosPorCategoria,
    required this.gastosPorCategoria,
  });
}
