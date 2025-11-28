import 'package:flutter/material.dart';

class ReconciliationItem extends StatelessWidget {
  final Map<String, dynamic> extract;
  final VoidCallback? onMatch;
  const ReconciliationItem({super.key, required this.extract, this.onMatch});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${extract['description']} — \$${(extract['amount'] as num).toStringAsFixed(2)}'),
        subtitle: Text('ID: ${extract['extractId']} — ${extract['date']}'),
        trailing: extract['matched'] == true ? const Text('Conciliado') : ElevatedButton(onPressed: onMatch, child: const Text('Conciliar')),
      ),
    );
  }
}
