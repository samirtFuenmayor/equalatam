import 'package:flutter/material.dart';
import '../widgets/waybill_form.dart';

class WaybillCreatePage extends StatelessWidget {
  const WaybillCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Crear Waybill')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Crear Guía / Waybill', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Expanded(child: WaybillForm()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
