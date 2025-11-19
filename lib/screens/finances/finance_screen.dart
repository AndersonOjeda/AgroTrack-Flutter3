import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../widgets/finance_summary_card.dart';
import '../../widgets/finance_filter_bar.dart';
import '../../widgets/finance_chart.dart';
import '../../widgets/finance_export_buttons.dart';
import '../../widgets/finance_alert_banner.dart';
import 'finance_form_screen.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final records = finance.filteredRecords;

    return Scaffold(
      appBar: AppBar(title: const Text('Finanzas')),
      body: finance.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const FinanceAlertBanner(),
                const FinanceSummaryCard(),
                const SizedBox(height: 12),
                FinanceFilterBar(
                  selectedType: finance.filterType,
                  selectedMonth: finance.filterMonth,
                  selectedYear: finance.filterYear,
                  onFilterChanged: (type, month, year) {
                    finance.setFilters(type: type, month: month, year: year);
                  },
                  onClear: finance.clearFilters,
                ),
                const SizedBox(height: 8),
                FinanceChart(records: records),
                const SizedBox(height: 8),
                const FinanceExportButtons(),

                Expanded(
                  child: records.isEmpty
                      ? const Center(
                          child: Text(
                            "No hay registros todavia.\nPresiona + para agregar uno.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final r = records[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(
                                  "${r.category} - \$${r.amount.toStringAsFixed(2)}",
                                ),
                                subtitle: Text(
                                  r.type == "income" ? "Ingreso" : "Gasto",
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
                                            builder: (_) => FinanceFormScreen(initialRecord: r),
                                          ),
                                        );
                                        if (updated == true && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Registro actualizado')),
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
                                            title: const Text('Eliminar'),
                                            content: const Text('Deseas eliminar este registro?'),
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
                                          await finance.deleteRecord(r.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Registro eliminado')),
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
            MaterialPageRoute(builder: (_) => const FinanceFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
