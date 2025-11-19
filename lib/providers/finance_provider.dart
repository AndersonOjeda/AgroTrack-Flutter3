import 'package:flutter/material.dart';
import '../models/finance_record.dart';
import '../services/finance_service.dart';
import '../services/user_service.dart';

class FinanceProvider extends ChangeNotifier {
  final FinanceService _service = FinanceService();

  bool loading = false;
  List<FinanceRecord> records = [];
  String userId = '';
  String filterType = 'all'; // all, income, expense
  int? filterMonth;
  int? filterYear;

  FinanceProvider() {
    _init();
  }

  Future<void> _init() async {
    loading = true;
    notifyListeners();

    // Obtener usuario actual almacenado en cache/local
    final currentUser = await UserService.getCurrentUser();
    userId = currentUser?.id ?? '';

    if (userId.isEmpty) {
      loading = false;
      notifyListeners();
      return;
    }

    records = await _service.getRecords(userId);

    loading = false;
    notifyListeners();
  }

  List<FinanceRecord> get filteredRecords {
    return records.where((r) {
      final matchesType =
          filterType == 'all' ? true : r.type == filterType;
      final matchesMonth =
          filterMonth == null ? true : r.date.month == filterMonth;
      final matchesYear =
          filterYear == null ? true : r.date.year == filterYear;
      return matchesType && matchesMonth && matchesYear;
    }).toList();
  }

  void setFilters({String? type, int? month, int? year}) {
    filterType = type ?? filterType;
    filterMonth = month;
    filterYear = year;
    notifyListeners();
  }

  void clearFilters() {
    filterType = 'all';
    filterMonth = null;
    filterYear = null;
    notifyListeners();
  }

  double get totalIncome => records
      .where((r) => r.type == 'income')
      .fold<double>(0, (sum, r) => sum + r.amount);

  double get totalExpense => records
      .where((r) => r.type == 'expense')
      .fold<double>(0, (sum, r) => sum + r.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> addRecord(FinanceRecord record) async {
    records.add(record);
    notifyListeners();

    if (userId.isEmpty) return;

    final ok = await _service.addRecord(record);
    if (ok) {
      // Volver a cargar desde la BD remota si se sincroniza exitosamente
      records = await _service.getRecords(userId);
    }
    notifyListeners();
  }

  Future<void> updateRecord(FinanceRecord updated) async {
    records = records.map((r) => r.id == updated.id ? updated : r).toList();
    notifyListeners();

    if (userId.isNotEmpty) {
      final ok = await _service.updateRecord(updated);
      if (ok) {
        records = await _service.getRecords(userId);
      }
    }
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    records.removeWhere((r) => r.id == id);
    notifyListeners();
    if (userId.isNotEmpty) {
      await _service.deleteRecord(id);
    }
  }
}
