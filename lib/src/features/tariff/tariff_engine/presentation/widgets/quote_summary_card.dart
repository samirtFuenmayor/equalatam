import 'package:flutter/material.dart';
import '../../domain/entities/tariff_quote.dart';

class QuoteSummaryCard extends StatelessWidget {
  final TariffQuote quote;
  const QuoteSummaryCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Resumen de cotización', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Peso real: ${quote.pesoRealKg} kg'),
          Text('Peso volumétrico: ${quote.pesoVolumetricoKg} kg'),
          Text('Peso facturable: ${quote.pesoChargeableKg} kg'),
          Text('Servicio: ${quote.service}'),
          Text('Costo base: \$${quote.baseCost.toStringAsFixed(2)}'),
          Text('Impuesto: \$${quote.tax.toStringAsFixed(2)}'),
          const Divider(),
          Text('Total: \$${quote.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
