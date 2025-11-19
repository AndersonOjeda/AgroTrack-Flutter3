import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? initialTask;

  const TaskFormScreen({super.key, this.initialTask});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String title = widget.initialTask?.title ?? '';
  late String? description = widget.initialTask?.description;
  late DateTime dueDate = widget.initialTask?.dueDate ?? DateTime.now();
  late String priority = widget.initialTask?.priority ?? 'medium';
  late String category = widget.initialTask?.category ?? 'general';
  late String status = widget.initialTask?.status ?? 'pending';
  TimeOfDay? reminderTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialTask?.reminderAt != null) {
      final dt = widget.initialTask!.reminderAt!;
      reminderTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => reminderTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.initialTask == null ? 'Nueva tarea' : 'Editar tarea'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Titulo'),
                initialValue: title,
                validator: (v) => v == null || v.isEmpty
                    ? 'Ingresa un titulo'
                    : null,
                onSaved: (v) => title = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Descripcion (opcional)'),
                initialValue: description,
                maxLines: 3,
                onSaved: (v) => description = v,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha limite',
                        border: OutlineInputBorder(),
                      ),
                      child: InkWell(
                        onTap: _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Text('Baja'),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Media'),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Text('Alta'),
                        ),
                      ],
                      onChanged: (v) => setState(() => priority = v ?? 'medium'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Asociar a',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'clima', child: Text('Clima')),
                  DropdownMenuItem(value: 'inventario', child: Text('Inventario')),
                  DropdownMenuItem(value: 'cultivo', child: Text('Cultivo')),
                ],
                onChanged: (v) => setState(() => category = v ?? 'general'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'completed', child: Text('Completada')),
                ],
                onChanged: (v) => setState(() => status = v ?? 'pending'),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Recordatorio (hora)',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        reminderTime != null
                            ? reminderTime!.format(context)
                            : 'Sin recordatorio',
                      ),
                    ),
                    TextButton(
                      onPressed: _pickTime,
                      child: const Text('Elegir'),
                    ),
                    if (reminderTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => reminderTime = null),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();

                  if (tasks.userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No hay usuario activo. Intenta iniciar sesión nuevamente.')),
                    );
                    return;
                  }

                  final reminderAt = reminderTime == null
                      ? null
                      : DateTime(
                          dueDate.year,
                          dueDate.month,
                          dueDate.day,
                          reminderTime!.hour,
                          reminderTime!.minute,
                        );

                  if (widget.initialTask == null) {
                    final task = TaskModel.createLocal(
                      userId: tasks.userId,
                      title: title,
                      description: description,
                      dueDate: dueDate,
                      priority: priority,
                      status: status,
                      category: category,
                      reminderAt: reminderAt,
                    );
                    await tasks.addTask(task);
                  } else {
                    final updated = widget.initialTask!.copyWith(
                      title: title,
                      description: description,
                      dueDate: dueDate,
                      priority: priority,
                      status: status,
                      category: category,
                      reminderAt: reminderAt,
                    );
                    await tasks.updateTask(updated);
                  }

                  if (mounted) Navigator.pop(context, true);
                },
                child:
                    Text(widget.initialTask == null ? 'Guardar' : 'Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
