import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../models/finance_record.dart';

class FinanceFormScreen extends StatefulWidget {
  final FinanceRecord? initialRecord;

  const FinanceFormScreen({super.key, this.initialRecord});

  @override
  State<FinanceFormScreen> createState() => _FinanceFormScreenState();
}

class _FinanceFormScreenState extends State<FinanceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String type = widget.initialRecord?.type ?? 'income';
  late String category = widget.initialRecord?.category ?? '';
  late String notes = widget.initialRecord?.notes ?? '';
  late double amount = widget.initialRecord?.amount ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final userId = finance.userId;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.initialRecord == null ? "Nuevo registro" : "Editar registro"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: "Tipo"),
                items: const [
                  DropdownMenuItem(value: "income", child: Text("Ingreso")),
                  DropdownMenuItem(value: "expense", child: Text("Gasto")),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(labelText: "Monto"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Ingrese un monto";
                  if (double.tryParse(v) == null) return "Monto invalido";
                  return null;
                },
                initialValue:
                    widget.initialRecord != null ? widget.initialRecord!.amount.toString() : null,
                onSaved: (v) => amount = double.parse(v!),
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(labelText: "Categoria"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Ingrese una categoria" : null,
                initialValue: widget.initialRecord?.category,
                onSaved: (v) => category = v!,
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Notas (opcional)",
                ),
                initialValue: widget.initialRecord?.notes,
                onSaved: (v) => notes = v ?? '',
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  _formKey.currentState!.save();

                  if (userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No hay usuario activo. Intenta iniciar sesión de nuevo.')),
                    );
                    return;
                  }

                  if (widget.initialRecord == null) {
                    final record = FinanceRecord.createLocal(
                      userId: userId,
                      type: type,
                      amount: amount,
                      category: category,
                      date: DateTime.now(),
                      notes: notes,
                    );

                    await finance.addRecord(record);
                  } else {
                    final updated = widget.initialRecord!.copyWith(
                      type: type,
                      amount: amount,
                      category: category,
                      notes: notes,
                      date: DateTime.now(),
                    );
                    await finance.updateRecord(updated);
                  }

                  if (mounted) Navigator.pop(context, true);
                },
                child: Text(widget.initialRecord == null ? "Guardar" : "Actualizar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
