// lib/src/features/finance_sub3_liquidation/presentation/widgets/liquidation_list.dart

import 'package:flutter/material.dart';
import '../../domain/entities/liquidation.dart';

class LiquidationList extends StatelessWidget {
  final List<Liquidation> liquidations;

  const LiquidationList({super.key, required this.liquidations});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: liquidations.length,
      itemBuilder: (context, index) {
        final l = liquidations[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.sync_alt, color: Colors.blueAccent),
            title: Text(
              "${l.branchOrigin} → ${l.branchDestination}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Envíos: ${l.shipmentsCount}\nMonto: \$${l.amount.toStringAsFixed(2)}",
            ),
            trailing: Text(
              "${l.date.day}/${l.date.month}/${l.date.year}",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
