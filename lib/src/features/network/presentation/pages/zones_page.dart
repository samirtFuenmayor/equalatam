import 'package:flutter/material.dart';
import '../widgets/zone_card.dart';

class ZonesPage extends StatelessWidget {
  const ZonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zonas / Cobertura')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zonas de Cobertura',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: 10,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => ZoneCard(
                  name: 'Zona ${i + 1}',
                  cities: 'Ciudad ${(i * 2) + 1}, Ciudad ${(i * 2) + 2}',
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
