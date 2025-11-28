import 'package:flutter/material.dart';
import '../widgets/scan_list.dart';

class TrackingScansPage extends StatelessWidget {
  const TrackingScansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Tracking / Escaneos')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Registro de Escaneos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  ScanList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
