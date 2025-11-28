import 'package:flutter/material.dart';

class CotizadorForm extends StatefulWidget {
  final void Function(Map<String, dynamic> params) onCalculate;
  const CotizadorForm({super.key, required this.onCalculate});

  @override
  State<CotizadorForm> createState() => _CotizadorFormState();
}

class _CotizadorFormState extends State<CotizadorForm> {
  final _formKey = GlobalKey<FormState>();
  final _pesoCtrl = TextEditingController(text: '1.0');
  final _lCtrl = TextEditingController(text: '10');
  final _wCtrl = TextEditingController(text: '10');
  final _hCtrl = TextEditingController(text: '10');
  String _originZone = 'local';
  String _destZone = 'national';
  String _service = 'economy';
  final _declaredCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _lCtrl.dispose();
    _wCtrl.dispose();
    _hCtrl.dispose();
    _declaredCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final params = {
      'weightKg': double.parse(_pesoCtrl.text),
      'lengthCm': double.parse(_lCtrl.text),
      'widthCm': double.parse(_wCtrl.text),
      'heightCm': double.parse(_hCtrl.text),
      'originZone': _originZone,
      'destZone': _destZone,
      'service': _service,
      'declaredValue': double.tryParse(_declaredCtrl.text) ?? 0.0,
    };
    widget.onCalculate(params);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(children: [
            Row(children: [
              Expanded(child: TextFormField(controller: _pesoCtrl, decoration: const InputDecoration(labelText: 'Peso (kg)'), keyboardType: TextInputType.number, validator: (v) => (v==null||v.isEmpty)?'Requerido':null)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _lCtrl, decoration: const InputDecoration(labelText: 'Largo (cm)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _wCtrl, decoration: const InputDecoration(labelText: 'Ancho (cm)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _hCtrl, decoration: const InputDecoration(labelText: 'Alto (cm)'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: _originZone, items: const [
                DropdownMenuItem(value: 'local',child: Text('Local')),
                DropdownMenuItem(value: 'regional',child: Text('Regional')),
                DropdownMenuItem(value: 'national',child: Text('Nacional')),
                DropdownMenuItem(value: 'international',child: Text('Internacional')),
              ], onChanged: (v) => setState(()=> _originZone = v ?? 'local'), decoration: const InputDecoration(labelText: 'Zona Origen'))),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(value: _destZone, items: const [
                DropdownMenuItem(value: 'local',child: Text('Local')),
                DropdownMenuItem(value: 'regional',child: Text('Regional')),
                DropdownMenuItem(value: 'national',child: Text('Nacional')),
                DropdownMenuItem(value: 'international',child: Text('Internacional')),
              ], onChanged: (v) => setState(()=> _destZone = v ?? 'national'), decoration: const InputDecoration(labelText: 'Zona Destino'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: _service, items: const [
                DropdownMenuItem(value: 'economy', child: Text('Económico')),
                DropdownMenuItem(value: 'express', child: Text('Express')),
              ], onChanged: (v) => setState(()=> _service = v ?? 'economy'), decoration: const InputDecoration(labelText: 'Servicio'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _declaredCtrl, decoration: const InputDecoration(labelText: 'Valor declarado (USD)'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              ElevatedButton(onPressed: _submit, child: const Text('Calcular')),
            ]),
          ]),
        ),
      ),
    );
  }
}
