import 'package:uuid/uuid.dart';

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String priority; // low, medium, high
  final String status; // pending, completed
  final String category; // general, clima, inventario, cultivo
  final DateTime? reminderAt;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.category,
    required this.createdAt,
    this.description,
    this.reminderAt,
  });

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? status,
    String? category,
    DateTime? reminderAt,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      reminderAt: reminderAt ?? this.reminderAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: DateTime.parse(map['due_date'] as String),
      priority: map['priority'] as String? ?? 'medium',
      status: map['status'] as String? ?? 'pending',
      category: map['category'] as String? ?? 'general',
      reminderAt: map['reminder_at'] != null
          ? DateTime.tryParse(map['reminder_at'] as String)
          : null,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'priority': priority,
      'status': status,
      'category': category,
      'reminder_at': reminderAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static TaskModel createLocal({
    required String userId,
    required String title,
    String? description,
    required DateTime dueDate,
    String priority = 'medium',
    String status = 'pending',
    String category = 'general',
    DateTime? reminderAt,
  }) {
    return TaskModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      status: status,
      category: category,
      reminderAt: reminderAt,
      createdAt: DateTime.now(),
    );
  }
}
