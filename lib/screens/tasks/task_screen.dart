import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/task_provider.dart';
import '../../widgets/task_filter_bar.dart';
import '../../widgets/task_summary_card.dart';
import 'task_form_screen.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final list = tasks.filteredTasks;

    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: tasks.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TaskSummaryCard(
                  pending: tasks.pendingCount,
                  completed: tasks.completedCount,
                  overdue: tasks.overdueCount,
                ),
                const SizedBox(height: 8),
                TaskFilterBar(
                  status: tasks.statusFilter,
                  priority: tasks.priorityFilter,
                  onlyToday: tasks.onlyToday,
                  onChanged: (status, priority, today) =>
                      tasks.setFilters(status: status, priority: priority, today: today),
                  onClear: tasks.clearFilters,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay tareas.\nPresiona + para agregar.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final t = list[index];
                            final isOverdue = t.dueDate.isBefore(DateTime.now()) &&
                                t.status == 'pending';
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: Checkbox(
                                  value: t.status == 'completed',
                                  onChanged: (_) => tasks.toggleComplete(t),
                                ),
                                title: Text(
                                  t.title,
                                  style: t.status == 'completed'
                                      ? const TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (t.description != null && t.description!.isNotEmpty)
                                      Text(t.description!),
                                    Text(
                                      'Fecha: ${t.dueDate.day}/${t.dueDate.month}  •  Prioridad: ${t.priority}  •  ${t.category}',
                                      style: TextStyle(
                                        color: isOverdue ? Colors.red : null,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final updated = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TaskFormScreen(initialTask: t),
                                          ),
                                        );
                                        if (updated == true && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Tarea actualizada')),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Eliminar tarea'),
                                            content: const Text('¿Deseas eliminar esta tarea?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await tasks.deleteTask(t.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Tarea eliminada')),
                                            );
                                          }
                                        }
                                      },
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
