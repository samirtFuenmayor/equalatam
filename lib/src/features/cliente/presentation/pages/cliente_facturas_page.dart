// lib/src/features/cliente/presentation/pages/cliente_facturas_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELO
// ═══════════════════════════════════════════════════════════════════════════════

class _Factura {
  final String  id;
  final String? numeroFactura;
  final String  estado;
  final double  subtotal0;
  final double  subtotal15;
  final double  iva;
  final double  descuento;
  final double  total;
  final String? fechaEmision;
  final String? fechaVencimiento;
  final String? formaPago;
  final String? pedidoNumero;
  final String? observaciones;
  final List<_FacturaDetalle> detalles;

  const _Factura({
    required this.id, this.numeroFactura, required this.estado,
    required this.subtotal0, required this.subtotal15,
    required this.iva, required this.descuento, required this.total,
    this.fechaEmision, this.fechaVencimiento, this.formaPago,
    this.pedidoNumero, this.observaciones, required this.detalles,
  });

  factory _Factura.fromJson(Map<String, dynamic> j) => _Factura(
    id:              j['id'] ?? '',
    numeroFactura:   j['numeroFactura'],
    estado:          j['estado'] ?? '',
    subtotal0:       (j['subtotal0'] as num?)?.toDouble() ?? 0,
    subtotal15:      (j['subtotal15'] as num?)?.toDouble() ?? 0,
    iva:             (j['iva'] as num?)?.toDouble() ?? 0,
    descuento:       (j['descuento'] as num?)?.toDouble() ?? 0,
    total:           (j['total'] as num?)?.toDouble() ?? 0,
    fechaEmision:    j['fechaEmision'],
    fechaVencimiento:j['fechaVencimiento'],
    formaPago:       j['formaPago'],
    pedidoNumero:    j['pedidoNumero'],
    observaciones:   j['observaciones'],
    detalles:        (j['detalles'] as List? ?? [])
        .map((d) => _FacturaDetalle.fromJson(d)).toList(),
  );
}

class _FacturaDetalle {
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  const _FacturaDetalle({required this.descripcion, required this.cantidad,
    required this.precioUnitario, required this.subtotal});
  factory _FacturaDetalle.fromJson(Map<String, dynamic> j) => _FacturaDetalle(
    descripcion:    j['descripcion'] ?? '',
    cantidad:       (j['cantidad'] as num?)?.toDouble() ?? 1,
    precioUnitario: (j['precioUnitario'] as num?)?.toDouble() ?? 0,
    subtotal:       (j['subtotal'] as num?)?.toDouble() ?? 0,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ClienteFacturasPage extends StatefulWidget {
  const ClienteFacturasPage({super.key});
  @override
  State<ClienteFacturasPage> createState() => _ClienteFacturasPageState();
}

class _ClienteFacturasPageState extends State<ClienteFacturasPage> {
  List<_Factura> _facturas  = [];
  double         _deuda     = 0;
  bool           _loading   = true;
  String?        _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs     = await SharedPreferences.getInstance();
      final token     = prefs.getString('eq_token') ?? '';
      final clienteId = prefs.getString('eq_clienteId') ?? '';

      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/financiero/facturas/cliente/$clienteId'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/financiero/facturas/cliente/$clienteId/deuda'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      final facRes  = results[0];
      final deudaRes= results[1];

      if (facRes.statusCode == 200) {
        final list = jsonDecode(utf8.decode(facRes.bodyBytes)) as List;
        final deudaData = deudaRes.statusCode == 200
            ? jsonDecode(utf8.decode(deudaRes.bodyBytes))
            : {'deuda': 0};
        setState(() {
          _facturas = list.map((e) => _Factura.fromJson(e)).toList();
          _deuda    = (deudaData['deuda'] as num?)?.toDouble() ?? 0;
          _loading  = false;
        });
      } else {
        setState(() { _error = 'Error al cargar facturas'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Sin conexión al servidor'; _loading = false; });
    }
  }

  void _verDetalle(_Factura f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FacturaDetalleSheet(factura: f),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [
        _FacHeader(
          total: _facturas.length,
          deuda: _deuda,
          onRefresh: _load,
        ),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _body() {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    if (_error != null) return _FacErrorView(message: _error!, onRetry: _load);
    if (_facturas.isEmpty) return const _FacEmptyView();
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A237E),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _facturas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _FacturaCard(
          f:          _facturas[i],
          onDetalle:  () => _verDetalle(_facturas[i]),
        ),
      ),
    );
  }
}

// ─── HEADER CON DEUDA ─────────────────────────────────────────────────────────
class _FacHeader extends StatelessWidget {
  final int    total;
  final double deuda;
  final VoidCallback onRefresh;
  const _FacHeader({required this.total, required this.deuda, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mis Facturas', style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              Text('$total factura${total == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ])),
            IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
                onPressed: onRefresh),
          ]),
        ),
        // Banner de deuda
        if (deuda > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFC107))),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tienes facturas pendientes',
                    style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 13, color: Color(0xFF92400E))),
                Text('Deuda total: \$${deuda.toStringAsFixed(2)} USD',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB45309))),
              ])),
            ]),
          ),
      ]),
    );
  }
}

// ─── CARD DE FACTURA ──────────────────────────────────────────────────────────
class _FacturaCard extends StatelessWidget {
  final _Factura     f;
  final VoidCallback onDetalle;
  const _FacturaCard({required this.f, required this.onDetalle});

  (Color, String, IconData) get _estadoInfo => switch (f.estado) {
    'BORRADOR' => (const Color(0xFF6B7280), 'Borrador', Icons.edit_outlined),
    'EMITIDA'  => (const Color(0xFFF59E0B), 'Emitida', Icons.receipt_outlined),
    'PAGADA'   => (const Color(0xFF2E7D32), 'Pagada', Icons.check_circle_outline),
    'ANULADA'  => (const Color(0xFFC62828), 'Anulada', Icons.cancel_outlined),
    'VENCIDA'  => (const Color(0xFFE65100), 'Vencida', Icons.schedule_outlined),
    _          => (const Color(0xFF6B7280), f.estado, Icons.receipt_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _estadoInfo;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: f.estado == 'EMITIDA'
                  ? const Color(0xFFFBBF24) : const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabecera
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.numeroFactura ?? 'BORRADOR', style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  fontFamily: 'monospace',
                  color: f.numeroFactura != null
                      ? const Color(0xFF1A1A2E) : const Color(0xFF9CA3AF))),
              if (f.pedidoNumero != null)
                Text('Pedido: ${f.pedidoNumero}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ])),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(label, style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ])),
          ]),
        ),
        // Montos
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('IVA', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              Text('\$${f.iva.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
            ])),
            Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TOTAL', style: TextStyle(
                    fontSize: 10, color: Color(0xFF9CA3AF))),
                Text('\$${f.total.toStringAsFixed(2)}', style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E))),
              ]),
            )),
          ]),
        ),
        // Fechas
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            if (f.fechaEmision != null) ...[
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text('Emisión: ${f.fechaEmision}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(width: 12),
            ],
            if (f.formaPago != null) ...[
              const Icon(Icons.payment_outlined, size: 12, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(f.formaPago!.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ],
          ]),
        ),
        // Botón ver detalle
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: onDetalle,
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A237E),
                side: const BorderSide(color: Color(0xFFC5CAE9)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10)),
            icon: const Icon(Icons.receipt_long_outlined, size: 16),
            label: const Text('Ver detalle', style: TextStyle(fontSize: 13)),
          )),
        ),
      ]),
    );
  }
}

// ─── SHEET DETALLE ────────────────────────────────────────────────────────────
class _FacturaDetalleSheet extends StatelessWidget {
  final _Factura factura;
  const _FacturaDetalleSheet({required this.factura});

  @override
  Widget build(BuildContext context) {
    final f = factura;
    return Container(
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.numeroFactura ?? 'BORRADOR', style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                if (f.pedidoNumero != null)
                  Text('Pedido: ${f.pedidoNumero}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ])),
              IconButton(icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 20),

            // Fechas
            if (f.fechaEmision != null || f.fechaVencimiento != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Row(children: [
                  if (f.fechaEmision != null)
                    Expanded(child: Column(children: [
                      const Text('Emisión', style: TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF))),
                      Text(f.fechaEmision!, style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                    ])),
                  if (f.fechaVencimiento != null) ...[
                    Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
                    Expanded(child: Column(children: [
                      const Text('Vencimiento', style: TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF))),
                      Text(f.fechaVencimiento!, style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                    ])),
                  ],
                ]),
              ),
            const SizedBox(height: 16),

            // Detalles
            const Text('Detalle', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
            const SizedBox(height: 10),
            ...f.detalles.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.descripcion, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                  Text('${d.cantidad.toStringAsFixed(0)} × \$${d.precioUnitario.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ])),
                Text('\$${d.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 13, color: Color(0xFF374151))),
              ]),
            )),

            const Divider(height: 24),

            // Totales
            _TotalRow('Subtotal 0%',  f.subtotal0),
            _TotalRow('Subtotal 15%', f.subtotal15),
            if (f.descuento > 0) _TotalRow('Descuento', f.descuento, isNegative: true),
            _TotalRow('IVA 15%',      f.iva),
            const Divider(height: 16),
            _TotalRow('TOTAL', f.total, isBold: true, color: const Color(0xFF1A237E)),

            if (f.observaciones != null && f.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFFDE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFF176))),
                child: Text(f.observaciones!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
              ),
            ],
            const SizedBox(height: 8),
          ]),
        )),
      ]),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double valor;
  final bool   isBold;
  final bool   isNegative;
  final Color  color;
  const _TotalRow(this.label, this.valor,
      {this.isBold = false, this.isNegative = false,
        this.color = const Color(0xFF374151)});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(
          fontSize: isBold ? 15 : 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isBold ? const Color(0xFF1A1A2E) : const Color(0xFF6B7280)))),
      Text('${isNegative ? '-' : ''}\$${valor.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: isBold ? 18 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isNegative ? const Color(0xFFC62828) : color)),
    ]),
  );
}

// ─── VISTAS AUXILIARES ────────────────────────────────────────────────────────
class _FacEmptyView extends StatelessWidget {
  const _FacEmptyView();
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6), shape: BoxShape.circle),
          child: const Icon(Icons.receipt_long_outlined,
              size: 48, color: Color(0xFF1A237E))),
      const SizedBox(height: 16),
      const Text('No tienes facturas', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      const Text('Tus facturas aparecerán aquí una vez emitidas',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          textAlign: TextAlign.center),
    ]),
  ));
}

class _FacErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FacErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded,
              size: 48, color: Color(0xFFC62828))),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reintentar')),
    ]),
  ));
}