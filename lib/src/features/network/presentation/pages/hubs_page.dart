import 'package:flutter/material.dart';
import '../widgets/hub_card.dart';

class HubsPage extends StatelessWidget {
  const HubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Centros de Distribución (HUBs)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HUBs / Centros de Distribución',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (_, i) => HubCard(
                  title: 'Hub Logístico ${i + 1}',
                  capacity: '${(i + 1) * 1000} pkg/día',
                  region: 'Región ${['Norte', 'Sur', 'Este', 'Oeste', 'Centro'][i]}',
                  onEdit: () {},
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
