import 'package:flutter/material.dart';
import '../widgets/branch_card.dart';

class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sucursales')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Listado de Sucursales',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => BranchCard(
                  title: 'Sucursal ${i + 1}',
                  address: 'Calle ${i + 10} y Av. Principal',
                  phone: '09${i + 1234567}',
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
