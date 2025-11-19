import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanceProvider>();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Balance General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Ingresos: \$${f.totalIncome.toStringAsFixed(2)}'),
            Text('Gastos:   \$${f.totalExpense.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Balance: \$${f.balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                color: f.balance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
