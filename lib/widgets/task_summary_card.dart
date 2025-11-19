import 'package:flutter/material.dart';

class TaskSummaryCard extends StatelessWidget {
  final int pending;
  final int completed;
  final int overdue;

  const TaskSummaryCard({
    super.key,
    required this.pending,
    required this.completed,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat('Pendientes', pending, Colors.orange),
            _buildStat('Completadas', completed, Colors.green),
            _buildStat('Vencidas', overdue, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
