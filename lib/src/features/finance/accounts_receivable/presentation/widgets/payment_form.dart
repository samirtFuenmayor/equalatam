import 'package:flutter/material.dart';
import '../../domain/entities/payment.dart';

class PaymentForm extends StatefulWidget {
  final String receivableId;
  final double maxAmount;
  final void Function(Payment) onSubmit;
  const PaymentForm({super.key, required this.receivableId, required this.maxAmount, required this.onSubmit});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String _method = 'transfer';

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amt = double.tryParse(_amountCtrl.text) ?? 0.0;
    final p = Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      receivableId: widget.receivableId,
      method: _method,
      reference: 'MANUAL-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      amount: amt,
      status: 'pending',
    );
    widget.onSubmit(p);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto'), validator: (v){
            final val = double.tryParse(v ?? '');
            if (val == null || val <= 0) return 'Monto inválido';
            if (val > widget.maxAmount) return 'Supera saldo pendiente';
            return null;
          }),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(
            value: _method,
            items: const [
              DropdownMenuItem(value: 'transfer', child: Text('Transferencia')),
              DropdownMenuItem(value: 'card', child: Text('Tarjeta')),
              DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
              DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
            ],
            onChanged: (v) => setState(()=> _method = v ?? 'transfer'),
            decoration: const InputDecoration(labelText: 'Método'),
          ),
          const SizedBox(height:12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            const SizedBox(width:8),
            ElevatedButton(onPressed: _submit, child: const Text('Registrar pago (mock)')),
          ])
        ]),
      )),
    );
  }
}
