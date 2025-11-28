import 'package:flutter/material.dart';
import '../widgets/route_card.dart';

class RoutingPage extends StatelessWidget {
  const RoutingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Ruteo y Logística')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Asignación de Rutas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  const Text('Sugerencias automáticas basadas en origen/destino y capacidad'),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 8,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => RouteCard(
                        title: 'Ruta sugerida #${i + 1}',
                        subtitle: 'Hub ${i % 3 + 1} • Tiempo ${i + 1} día(s)',
                        onTap: () {},
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
