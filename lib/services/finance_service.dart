import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class FinanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener todas las transacciones del usuario
  Future<List<Transaction>> getTransactions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo transacciones: $e');
      return [];
    }
  }

  // Obtener transacciones por rango de fechas
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo transacciones por fecha: $e');
      return [];
    }
  }

  // Agregar nueva transacción
  Future<bool> addTransaction(Transaction transaction) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final data = transaction.toJson();
      data['user_id'] = userId;
      data.remove('id'); // Supabase generará el ID

      await _supabase.from('transactions').insert(data);
      return true;
    } catch (e) {
      print('Error agregando transacción: $e');
      return false;
    }
  }

  // Actualizar transacción
  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await _supabase
          .from('transactions')
          .update(transaction.toJson())
          .eq('id', transaction.id)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error actualizando transacción: $e');
      return false;
    }
  }

  // Eliminar transacción
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await _supabase
          .from('transactions')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error eliminando transacción: $e');
      return false;
    }
  }

  // Calcular resumen financiero
  Future<FinancialSummary> getFinancialSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<Transaction> transactions;

      if (startDate != null && endDate != null) {
        transactions = await getTransactionsByDateRange(startDate, endDate);
      } else {
        transactions = await getTransactions();
      }

      double totalIngresos = 0;
      double totalGastos = 0;
      Map<String, double> ingresosPorCategoria = {};
      Map<String, double> gastosPorCategoria = {};

      for (var transaction in transactions) {
        if (transaction.type == 'ingreso') {
          totalIngresos += transaction.amount;
          ingresosPorCategoria[transaction.category] =
              (ingresosPorCategoria[transaction.category] ?? 0) +
              transaction.amount;
        } else {
          totalGastos += transaction.amount;
          gastosPorCategoria[transaction.category] =
              (gastosPorCategoria[transaction.category] ?? 0) +
              transaction.amount;
        }
      }

      return FinancialSummary(
        totalIngresos: totalIngresos,
        totalGastos: totalGastos,
        balance: totalIngresos - totalGastos,
        ingresosPorCategoria: ingresosPorCategoria,
        gastosPorCategoria: gastosPorCategoria,
      );
    } catch (e) {
      print('Error calculando resumen financiero: $e');
      return FinancialSummary(
        totalIngresos: 0,
        totalGastos: 0,
        balance: 0,
        ingresosPorCategoria: {},
        gastosPorCategoria: {},
      );
    }
  }

  // Obtener categorías de ingresos
  List<String> getIncomeCategories() {
    return [
      'Venta de Cosecha',
      'Venta de Productos',
      'Subsidios',
      'Inversión',
      'Otros Ingresos',
    ];
  }

  // Obtener categorías de gastos
  List<String> getExpenseCategories() {
    return [
      'Semillas',
      'Fertilizantes',
      'Pesticidas',
      'Riego',
      'Mano de Obra',
      'Maquinaria',
      'Transporte',
      'Combustible',
      'Mantenimiento',
      'Otros Gastos',
    ];
  }
}
