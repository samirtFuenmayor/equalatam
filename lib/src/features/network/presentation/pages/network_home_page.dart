import 'package:flutter/material.dart';
import 'branches_page.dart';
import 'hubs_page.dart';
import 'zones_page.dart';
import 'routes_page.dart';

class NetworkHomePage extends StatelessWidget {
  const NetworkHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Gestión de Red Logística')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text('Gestión de Sucursales y Red',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _go(context, 'Sucursales', Icons.store, const BranchesPage()),
                _go(context, 'Centros de Distribución (Hubs)', Icons.home_work, const HubsPage()),
                _go(context, 'Zonas / Cobertura', Icons.map, const ZonesPage()),
                _go(context, 'Rutas Logísticas', Icons.alt_route, const RoutesNetworkPage()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _go(BuildContext context, String title, IconData icon, Widget page) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(title),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
