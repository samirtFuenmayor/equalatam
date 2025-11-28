import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/corporate_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Reportes Corporativos')), body: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      const Text('Reportes (mock)', style: TextStyle(fontSize:20, fontWeight: FontWeight.bold)),
      const SizedBox(height:12),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children:[
        const Text('Volumen por estado', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height:10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[
          Column(children: const [Text('Pendientes'), Text('10')]),
          Column(children: const [Text('En tránsito'), Text('7')]),
          Column(children: const [Text('Entregados'), Text('3')]),
        ])
      ]))),
      const SizedBox(height:10),
      ElevatedButton(onPressed: () { /* export mock */ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exportado CSV (mock)'))); }, child: const Text('Exportar CSV'))
    ])));
  }
}
