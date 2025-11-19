import 'package:flutter/material.dart';
import '../models/finance_record.dart';

class FinanceChart extends StatelessWidget {
  final List<FinanceRecord> records;

  const FinanceChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final income = records
        .where((r) => r.type == 'income')
        .fold<double>(0, (sum, r) => sum + r.amount);
    final expense = records
        .where((r) => r.type == 'expense')
        .fold<double>(0, (sum, r) => sum + r.amount);
    final maxValue = (income > expense ? income : expense).clamp(1, double.infinity);

    Widget buildBar(double value, Color color, String label) {
      final percent = (value / maxValue).clamp(0.05, 1.0);
      return Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 120 * percent,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "\$${value.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildBar(income, Colors.green, 'Ingresos'),
              buildBar(expense, Colors.red, 'Gastos'),
            ],
          ),
        ),
      ),
    );
  }
}
