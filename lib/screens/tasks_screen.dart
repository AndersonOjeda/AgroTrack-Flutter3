import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService(Supabase.instance.client);
  List<Task> _tasks = [];
  bool _isWeeklyView = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final tasks = _isWeeklyView
          ? await _taskService.getWeeklyTasks(user.id, _selectedDate)
          : await _taskService.getDailyTasks(user.id, _selectedDate);
      setState(() => _tasks = tasks);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las tareas: \${e.toString()}')),
      );
    }
  }

  void _toggleView() {
    setState(() {
      _isWeeklyView = !_isWeeklyView;
      _loadTasks();
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadTasks();
      });
    }
  }

  String _getDateRangeText() {
    if (_isWeeklyView) {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '\${DateFormat('d MMM').format(startOfWeek)} - \${DateFormat('d MMM, y').format(endOfWeek)}';
    }
    return DateFormat('d MMMM, y').format(_selectedDate);
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        actions: [
          IconButton(
            icon: Icon(_isWeeklyView ? Icons.calendar_view_day : Icons.calendar_view_week),
            onPressed: _toggleView,
            tooltip: _isWeeklyView ? 'Vista diaria' : 'Vista semanal',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_getDateRangeText()),
                ),
                Text(_isWeeklyView ? 'Vista Semanal' : 'Vista Diaria'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: double.infinity,
                      color: _getPriorityColor(task.priority),
                    ),
                    title: Text(task.title),
                    subtitle: Text(
                      '\${DateFormat('d MMM, y').format(task.date)} - \${task.time}\\n\${task.description}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          // Navegar a la pantalla de edición
                        } else if (value == 'delete') {
                          await _taskService.deleteTask(task.id);
                          _loadTasks();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla de creación de tarea
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}