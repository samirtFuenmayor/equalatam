// lib/src/features/bi_dashboards/presentation/widgets/kpi_cards.dart

import 'package:flutter/material.dart';
import '../../domain/entities/bi_dashboard.dart';

class KpiCards extends StatelessWidget {
  final BiDashboard metrics;

  const KpiCards({super.key, required this.metrics});

  Widget _card(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 20)),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      children: [
        _card("Envíos", "${metrics.shipments}", Icons.local_shipping),
        _card("Ingresos", "\$${metrics.revenue}", Icons.attach_money),
        _card("Tasa de Entrega", "${(metrics.deliveryRate * 100).toStringAsFixed(1)}%", Icons.check_circle),
        _card("Tiempo Promedio", "${metrics.avgTransitTime} días", Icons.timer),
        _card("Incidencias", "${metrics.incidents}", Icons.warning_amber),
      ],
    );
  }
}
