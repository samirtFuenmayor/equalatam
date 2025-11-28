import 'package:flutter/material.dart';
import '../../domain/entities/invoice.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;

  const InvoiceCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text("Factura #${invoice.id}"),
        subtitle: Text(invoice.customerName),
        trailing: Text("\$${invoice.total.toStringAsFixed(2)}"),
      ),
    );
  }
}
