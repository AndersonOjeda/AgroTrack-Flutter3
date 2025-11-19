import 'package:flutter/material.dart';

class FinanceExportButtons extends StatelessWidget {
  const FinanceExportButtons({super.key});

  void _showPlaceholder(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label aun no disponible. Proxima version.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar PDF'),
              onPressed: () => _showPlaceholder(context, 'Exportar PDF'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.table_chart),
              label: const Text('Exportar Excel'),
              onPressed: () => _showPlaceholder(context, 'Exportar Excel'),
            ),
          ),
        ],
      ),
    );
  }
}
