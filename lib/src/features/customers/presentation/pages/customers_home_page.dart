import 'package:flutter/material.dart';
import '../widgets/customer_card.dart';

class CustomersHomePage extends StatelessWidget {
  const CustomersHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text("Clientes y CRM")),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Gestión de Clientes",
                      style:
                      TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // LISTA DE CLIENTES -----------------------------------------------------
                  Expanded(
                    child: ListView.separated(
                      itemCount: 12,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => CustomerCard(
                        name: "Cliente $i",
                        document: "DNI 00${i}92",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerProfilePageMock(name: "Cliente $i"),
                            ),
                          );
                        },
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

// Navegación rápida para demo
class CustomerProfilePageMock extends StatelessWidget {
  final String name;
  const CustomerProfilePageMock({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Perfil de $name")),
      body: const Center(child: Text("Aquí va el perfil del cliente")),
    );
  }
}
