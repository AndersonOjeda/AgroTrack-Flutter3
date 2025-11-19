// lib/services/finance_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/finance_record.dart';

class FinanceService {
  final supabase = Supabase.instance.client;

  Future<List<FinanceRecord>> getRecords(String userId) async {
    try {
      final response = await supabase
          .from('finance')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((row) => FinanceRecord.fromMap(row))
          .toList();
    } catch (e) {
      print('Error getting finance records: $e');
      return [];
    }
  }

  Future<bool> addRecord(FinanceRecord record) async {
    try {
      await supabase.from('finance').insert(record.toMap());
      return true;
    } catch (e) {
      print('Error adding finance record: $e');
      return false;
    }
  }

  Future<bool> updateRecord(FinanceRecord record) async {
    try {
      await supabase.from('finance').update(record.toMap()).eq('id', record.id);
      return true;
    } catch (e) {
      print('Error updating finance record: $e');
      return false;
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      await supabase.from('finance').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting finance record: $e');
      return false;
    }
  }
}
