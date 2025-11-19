import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

class TaskService {
  final supabase = Supabase.instance.client;

  Future<List<TaskModel>> getTasks(String userId) async {
    try {
      final response = await supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('due_date', ascending: true);

      return (response as List)
          .map((row) => TaskModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  Future<bool> addTask(TaskModel task) async {
    try {
      await supabase.from('tasks').insert(task.toMap());
      return true;
    } catch (e) {
      print('Error adding task: $e');
      return false;
    }
  }

  Future<bool> updateTask(TaskModel task) async {
    try {
      await supabase.from('tasks').update(task.toMap()).eq('id', task.id);
      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await supabase.from('tasks').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }
}
