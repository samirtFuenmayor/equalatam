import 'package:flutter/material.dart';
import '../../domain/entities/receivable.dart';

class ReceivableCard extends StatelessWidget {
  final Receivable receivable;
  final VoidCallback? onPay;
  const ReceivableCard({super.key, required this.receivable, this.onPay});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text('${receivable.customerName} — ${receivable.invoiceId}'),
        subtitle: Text('Vence: ${receivable.dueDate.toLocal().toIso8601String().split("T").first}\nSaldo: \$${receivable.balance.toStringAsFixed(2)}'),
        trailing: Wrap(spacing: 8, children: [
          Text(receivable.status.toUpperCase()),
          ElevatedButton(onPressed: onPay, child: const Text('Pagar')),
        ]),
        isThreeLine: true,
      ),
    );
  }
}
