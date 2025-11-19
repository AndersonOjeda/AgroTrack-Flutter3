import 'package:flutter/material.dart';

class TaskFilterBar extends StatelessWidget {
  final String status;
  final String priority;
  final bool onlyToday;
  final void Function(String status, String priority, bool onlyToday) onChanged;
  final VoidCallback onClear;

  const TaskFilterBar({
    super.key,
    required this.status,
    required this.priority,
    required this.onlyToday,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todos')),
                DropdownMenuItem(value: 'pending', child: Text('Pendientes')),
                DropdownMenuItem(value: 'completed', child: Text('Completadas')),
              ],
              onChanged: (v) => onChanged(v ?? 'all', priority, onlyToday),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todas')),
                DropdownMenuItem(value: 'high', child: Text('Alta')),
                DropdownMenuItem(value: 'medium', child: Text('Media')),
                DropdownMenuItem(value: 'low', child: Text('Baja')),
              ],
              onChanged: (v) => onChanged(status, v ?? 'all', onlyToday),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              const Text('Solo hoy'),
              Switch(
                value: onlyToday,
                onChanged: (v) => onChanged(status, priority, v),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Limpiar filtros',
            onPressed: onClear,
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
    );
  }
}
