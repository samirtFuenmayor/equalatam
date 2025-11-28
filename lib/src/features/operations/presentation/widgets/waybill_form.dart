import 'package:flutter/material.dart';
import 'dart:math';

class WaybillForm extends StatefulWidget {
  const WaybillForm({super.key});

  @override
  State<WaybillForm> createState() => _WaybillFormState();
}

class _WaybillFormState extends State<WaybillForm> {
  final _formKey = GlobalKey<FormState>();
  final remitenteCtrl = TextEditingController();
  final destinatarioCtrl = TextEditingController();
  final pesoCtrl = TextEditingController();
  final largoCtrl = TextEditingController();
  final anchoCtrl = TextEditingController();
  final altoCtrl = TextEditingController();
  String generatedCode = '';

  @override
  void dispose() {
    remitenteCtrl.dispose();
    destinatarioCtrl.dispose();
    pesoCtrl.dispose();
    largoCtrl.dispose();
    anchoCtrl.dispose();
    altoCtrl.dispose();
    super.dispose();
  }

  void _generateWaybill() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rnd = Random();
    setState(() {
      generatedCode = 'WB-${rnd.nextInt(900000) + 100000}';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Waybill generado: $generatedCode')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: remitenteCtrl, decoration: const InputDecoration(labelText: 'Remitente (nombre)'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 8),
              TextFormField(controller: destinatarioCtrl, decoration: const InputDecoration(labelText: 'Destinatario (nombre)'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: pesoCtrl, decoration: const InputDecoration(labelText: 'Peso (kg)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: largoCtrl, decoration: const InputDecoration(labelText: 'Largo (cm)'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: anchoCtrl, decoration: const InputDecoration(labelText: 'Ancho (cm)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: altoCtrl, decoration: const InputDecoration(labelText: 'Alto (cm)'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(onPressed: _generateWaybill, icon: const Icon(Icons.qr_code), label: const Text('Generar Waybill')),
                  const SizedBox(width: 12),
                  if (generatedCode.isNotEmpty)
                    SelectableText('Código: $generatedCode', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Previsualización de etiqueta', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 110,
                        color: Colors.grey.shade100,
                        child: Center(child: Text(generatedCode.isEmpty ? 'Aquí se mostrará el código de barras / QR' : 'BARCODE: $generatedCode')),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
