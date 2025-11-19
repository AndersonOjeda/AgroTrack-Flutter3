import 'package:uuid/uuid.dart';

class FinanceRecord {
  final String id;
  final String userId;
  final String type; // 'income' o 'expense'
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final bool isSynced;

  FinanceRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.isSynced = true,
  });

  FinanceRecord copyWith({
    String? id,
    String? userId,
    String? type,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
    bool? isSynced,
  }) {
    return FinanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory FinanceRecord.fromMap(Map<String, dynamic> map) {
    return FinanceRecord(
      id: map['id'],
      userId: map['user_id'],
      type: map['type'],
      amount: map['amount'].toDouble(),
      category: map['category'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      isSynced: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  static FinanceRecord createLocal({
    required String userId,
    required String type,
    required double amount,
    required String category,
    required DateTime date,
    String? notes,
  }) {
    return FinanceRecord(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      amount: amount,
      category: category,
      date: date,
      notes: notes,
      isSynced: false,
    );
  }
}
