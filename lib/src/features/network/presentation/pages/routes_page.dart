import 'package:flutter/material.dart';
import '../widgets/route_network_card.dart';

class RoutesNetworkPage extends StatelessWidget {
  const RoutesNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutas Logísticas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rutas Operativas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: 8,
                itemBuilder: (_, i) => RouteNetworkCard(
                  routeName: 'Ruta ${(i + 1)}',
                  origin: 'Sucursal ${(i + 1)}',
                  destination: 'Sucursal ${(i + 2)}',
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
