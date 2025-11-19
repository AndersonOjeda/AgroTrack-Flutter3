import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _service = TaskService();

  bool loading = false;
  List<TaskModel> tasks = [];
  String userId = '';

  String statusFilter = 'all'; // all, pending, completed
  String priorityFilter = 'all'; // all, low, medium, high
  bool onlyToday = false;

  TaskProvider() {
    _init();
  }

  Future<void> _init() async {
    loading = true;
    notifyListeners();

    final currentUser = await UserService.getCurrentUser();
    userId = currentUser?.id ?? '';
    if (userId.isEmpty) {
      loading = false;
      notifyListeners();
      return;
    }

    tasks = await _service.getTasks(userId);
    loading = false;
    notifyListeners();
  }

  List<TaskModel> get filteredTasks {
    final now = DateTime.now();
    return tasks.where((t) {
      final matchesStatus =
          statusFilter == 'all' ? true : t.status == statusFilter;
      final matchesPriority =
          priorityFilter == 'all' ? true : t.priority == priorityFilter;
      final matchesToday = onlyToday
          ? t.dueDate.year == now.year &&
              t.dueDate.month == now.month &&
              t.dueDate.day == now.day
          : true;
      return matchesStatus && matchesPriority && matchesToday;
    }).toList()
      ..sort((a, b) {
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        final cmpPriority = (priorityOrder[a.priority] ?? 3)
            .compareTo(priorityOrder[b.priority] ?? 3);
        if (cmpPriority != 0) return cmpPriority;
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  int get pendingCount =>
      tasks.where((t) => t.status == 'pending').length;
  int get completedCount =>
      tasks.where((t) => t.status == 'completed').length;
  int get overdueCount {
    final now = DateTime.now();
    return tasks
        .where((t) =>
            t.status == 'pending' &&
            t.dueDate.isBefore(
              DateTime(now.year, now.month, now.day + 1),
            ))
        .length;
  }

  void setFilters({
    String? status,
    String? priority,
    bool? today,
  }) {
    statusFilter = status ?? statusFilter;
    priorityFilter = priority ?? priorityFilter;
    onlyToday = today ?? onlyToday;
    notifyListeners();
  }

  void clearFilters() {
    statusFilter = 'all';
    priorityFilter = 'all';
    onlyToday = false;
    notifyListeners();
  }

  Future<void> addTask(TaskModel task) async {
    tasks.add(task);
    notifyListeners();
    if (userId.isEmpty) return;

    final ok = await _service.addTask(task);
    if (ok) {
      tasks = await _service.getTasks(userId);
    }
    notifyListeners();
  }

  Future<void> updateTask(TaskModel task) async {
    tasks = tasks.map((t) => t.id == task.id ? task : t).toList();
    notifyListeners();
    if (userId.isNotEmpty) {
      final ok = await _service.updateTask(task);
      if (ok) {
        tasks = await _service.getTasks(userId);
      }
    }
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    if (userId.isNotEmpty) {
      await _service.deleteTask(id);
    }
  }

  Future<void> toggleComplete(TaskModel task) async {
    final updated = task.copyWith(
      status: task.status == 'completed' ? 'pending' : 'completed',
    );
    await updateTask(updated);
  }
}
