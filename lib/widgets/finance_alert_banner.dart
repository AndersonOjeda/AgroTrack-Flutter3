import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class FinanceAlertBanner extends StatelessWidget {
  const FinanceAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final hasNegativeBalance = finance.balance < 0;
    final hasPendingSync = finance.records.any((r) => !r.isSynced);

    if (!hasNegativeBalance && !hasPendingSync) return const SizedBox.shrink();

    final message = [
      if (hasNegativeBalance) 'Balance negativo, revisa tus gastos.',
      if (hasPendingSync) 'Hay registros pendientes por sincronizar.',
    ].join(' ');

    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
