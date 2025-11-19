import 'package:flutter/material.dart';

class FinanceFilterBar extends StatelessWidget {
  final String selectedType;
  final int? selectedMonth;
  final int? selectedYear;
  final void Function(String type, int? month, int? year) onFilterChanged;
  final VoidCallback onClear;

  const FinanceFilterBar({
    super.key,
    required this.selectedType,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onFilterChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final months = <int, String>{
      1: 'Ene',
      2: 'Feb',
      3: 'Mar',
      4: 'Abr',
      5: 'May',
      6: 'Jun',
      7: 'Jul',
      8: 'Ago',
      9: 'Sep',
      10: 'Oct',
      11: 'Nov',
      12: 'Dic',
    };

    final currentYear = DateTime.now().year;
    final years = List<int>.generate(5, (i) => currentYear - i);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todos')),
                DropdownMenuItem(value: 'income', child: Text('Ingresos')),
                DropdownMenuItem(value: 'expense', child: Text('Gastos')),
              ],
              onChanged: (v) => onFilterChanged(v ?? 'all', selectedMonth, selectedYear),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<int?>(
              value: selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Mes',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...months.entries.map(
                  (e) => DropdownMenuItem<int?>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                ),
              ],
              onChanged: (v) => onFilterChanged(selectedType, v, selectedYear),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<int?>(
              value: selectedYear,
              decoration: const InputDecoration(
                labelText: 'Año',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...years.map(
                  (y) => DropdownMenuItem<int?>(
                    value: y,
                    child: Text(y.toString()),
                  ),
                ),
              ],
              onChanged: (v) => onFilterChanged(selectedType, selectedMonth, v),
            ),
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
