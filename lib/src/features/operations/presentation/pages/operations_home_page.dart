import 'package:flutter/material.dart';
import 'waybill_create_page.dart';
import 'routing_page.dart';
import 'tracking_scans_page.dart';
import 'exceptions_page.dart';
import 'commissions_page.dart';
import '../widgets/route_card.dart';

class OperationsHomePage extends StatelessWidget {
  const OperationsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Operaciones / Envíos')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gestión Operativa',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_box),
                        label: const Text('Crear Waybill'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaybillCreatePage())),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.alt_route),
                        label: const Text('Ruteo'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutingPage())),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Escaneos / Tracking'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingScansPage())),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.report_problem),
                        label: const Text('Excepciones'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExceptionsPage())),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payments),
                        label: const Text('Liquidación / Comisiones'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommissionsPage())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Rutas recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => RouteCard(
                        title: 'Ruta ${i + 1} - Origen A -> Destino B',
                        subtitle: 'Duración estimada: ${2 + i} días',
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
