import 'package:flutter/material.dart';
import '../widgets/shipment_history_table.dart';
import '../widgets/interaction_card.dart';

class CustomerProfilePage extends StatelessWidget {
  final String name;

  const CustomerProfilePage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(title: Text("Perfil de $name")),
      body: Row(
        children: [
          // INFO BÁSICA ---------------------------------------------------------
          if (isDesktop)
            SizedBox(
              width: 300,
              child: _buildProfileSidebar(),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  const Text("Historial de Envíos",
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  const ShipmentHistoryTable(),

                  const SizedBox(height: 30),

                  const Text("Interacciones y CRM",
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: List.generate(
                      5,
                          (i) => InteractionCard(
                        title: "Llamada o Reclamo #$i",
                        description:
                        "Detalle breve de la interacción realizada con el cliente.",
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

  Widget _buildProfileSidebar() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            SizedBox(height: 14),
            Text("Cliente Empresarial",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            ListTile(
              title: Text("RUC"),
              subtitle: Text("1234567890"),
            ),
            ListTile(
              title: Text("Dirección"),
              subtitle: Text("Av. Principal 123"),
            ),
            ListTile(
              title: Text("Descuento Preferencial"),
              subtitle: Text("12%"),
            ),
          ],
        ),
      ),
    );
  }
}
