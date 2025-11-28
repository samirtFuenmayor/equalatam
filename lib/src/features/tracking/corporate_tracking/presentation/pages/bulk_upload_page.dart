import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/corporate_bloc.dart';
import '../bloc/corporate_event.dart';

class BulkUploadPage extends StatefulWidget {
  final String clientRef;
  const BulkUploadPage({super.key, required this.clientRef});
  @override State<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends State<BulkUploadPage> {
  final _ctrl = TextEditingController();

  @override void dispose(){ _ctrl.dispose(); super.dispose(); }

  void _upload() {
    final csv = _ctrl.text;
    if (csv.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pegue contenido CSV'))); return; }
    context.read<CorporateBloc>().add(UploadCsvEvent(csv, widget.clientRef));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV subido (mock)')));
    Navigator.pop(context);
  }

  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Subir CSV (mock)')), body: Padding(padding: const EdgeInsets.all(18), child: Column(children:[
      const Text('Formato esperado: WAYBILL,ORIGEN,DESTINO (uno por línea)'),
      const SizedBox(height:8),
      Expanded(child: TextFormField(controller: _ctrl, maxLines: 20, decoration: const InputDecoration(border: OutlineInputBorder()))),
      const SizedBox(height:8),
      Row(mainAxisAlignment: MainAxisAlignment.end, children:[ ElevatedButton(onPressed: _upload, child: const Text('Subir CSV')) ])
    ])));
  }
}
