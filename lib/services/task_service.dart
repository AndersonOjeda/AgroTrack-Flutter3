import '../models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _supabase;
  static const String _table = 'tasks';

  TaskService(this._supabase);

  Future<List<Task>> getTasks(String userId) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('date')
        .order('time');

    return response.map((json) => Task.fromJson(json)).toList();
  }

  Future<List<Task>> getTasksByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .order('date')
        .order('time');

    return response.map((json) => Task.fromJson(json)).toList();
  }

  Future<Task> createTask(Task task) async {
    final response = await _supabase
        .from(_table)
        .insert(task.toJson())
        .select()
        .single();

    return Task.fromJson(response);
  }

  Future<Task> updateTask(Task task) async {
    final response = await _supabase
        .from(_table)
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single();

    return Task.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase.from(_table).delete().eq('id', taskId);
  }

  Future<List<Task>> getDailyTasks(String userId, DateTime date) async {
    return getTasksByDateRange(
      userId,
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
  }

  Future<List<Task>> getWeeklyTasks(String userId, DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
    return getTasksByDateRange(userId, startOfWeek, endOfWeek);
  }
}
