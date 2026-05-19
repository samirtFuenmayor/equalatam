// lib/src/features/cliente/presentation/pages/cliente_facturas_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELOS
// ═══════════════════════════════════════════════════════════════════════════════

class _FacturaDetalle {
  final String  descripcion;
  final double  cantidad;
  final double  precioUnitario;
  final double  subtotal;
  final bool    gravaIva;
  final int?    orden;

  const _FacturaDetalle({
    required this.descripcion, required this.cantidad,
    required this.precioUnitario, required this.subtotal,
    required this.gravaIva, this.orden,
  });

  factory _FacturaDetalle.fromJson(Map<String, dynamic> j) => _FacturaDetalle(
    descripcion:    j['descripcion'] ?? '',
    cantidad:       (j['cantidad'] as num?)?.toDouble() ?? 1,
    precioUnitario: (j['precioUnitario'] as num?)?.toDouble() ?? 0,
    subtotal:       (j['subtotal'] as num?)?.toDouble() ?? 0,
    gravaIva:       j['gravaIva'] as bool? ?? true,
    orden:          j['orden'] as int?,
  );
}

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
  final String? emisorRuc;
  final String? emisorRazonSocial;
  final String? clienteNombre;
  final String? clienteIdentificacion;
  final String? clienteEmail;
  final String? clienteDireccion;
  final String  creadoEn;
  final List<_FacturaDetalle> detalles;

  const _Factura({
    required this.id, this.numeroFactura, required this.estado,
    required this.subtotal0, required this.subtotal15,
    required this.iva, required this.descuento, required this.total,
    this.fechaEmision, this.fechaVencimiento, this.formaPago,
    this.pedidoNumero, this.observaciones, this.emisorRuc,
    this.emisorRazonSocial, this.clienteNombre, this.clienteIdentificacion,
    this.clienteEmail, this.clienteDireccion, required this.creadoEn,
    required this.detalles,
  });

  factory _Factura.fromJson(Map<String, dynamic> j) => _Factura(
    id:                   j['id'] ?? '',
    numeroFactura:        j['numeroFactura'],
    estado:               j['estado'] ?? '',
    subtotal0:            (j['subtotal0'] as num?)?.toDouble() ?? 0,
    subtotal15:           (j['subtotal15'] as num?)?.toDouble() ?? 0,
    iva:                  (j['iva'] as num?)?.toDouble() ?? 0,
    descuento:            (j['descuento'] as num?)?.toDouble() ?? 0,
    total:                (j['total'] as num?)?.toDouble() ?? 0,
    fechaEmision:         j['fechaEmision'],
    fechaVencimiento:     j['fechaVencimiento'],
    formaPago:            j['formaPago'],
    pedidoNumero:         j['pedidoNumero'],
    observaciones:        j['observaciones'],
    emisorRuc:            j['emisorRuc'],
    emisorRazonSocial:    j['emisorRazonSocial'],
    clienteNombre:        j['clienteNombre'],
    clienteIdentificacion:j['clienteIdentificacion'],
    clienteEmail:         j['clienteEmail'],
    clienteDireccion:     j['clienteDireccion'],
    creadoEn:             j['creadoEn'] ?? '',
    detalles:             (j['detalles'] as List? ?? [])
        .map((d) => _FacturaDetalle.fromJson(d as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => (a.orden ?? 0).compareTo(b.orden ?? 0)),
  );

  bool get esEmitida  => estado == 'EMITIDA';
  bool get esPagada   => estado == 'PAGADA';
  bool get esAnulada  => estado == 'ANULADA';
  bool get esVencida  => estado == 'VENCIDA';
  bool get esBorrador => estado == 'BORRADOR';
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ClienteFacturasPage extends StatefulWidget {
  const ClienteFacturasPage({super.key});
  @override
  State<ClienteFacturasPage> createState() => _ClienteFacturasPageState();
}

class _ClienteFacturasPageState extends State<ClienteFacturasPage>
    with SingleTickerProviderStateMixin {

  List<_Factura> _facturas  = [];
  double         _deuda     = 0;
  bool           _loading   = true;
  String?        _error;
  String         _clienteId = '';

  late final TabController _tabCtrl;
  final _tabs = ['Todas', 'Emitida', 'Pagada', 'Vencida'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<_Factura> get _filtradas {
    final idx = _tabCtrl.index;
    if (idx == 0) return _facturas;
    final estado = switch (idx) {
      1 => 'EMITIDA',
      2 => 'PAGADA',
      3 => 'VENCIDA',
      _ => '',
    };
    return _facturas.where((f) => f.estado == estado).toList();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      _clienteId  = prefs.getString('eq_clienteId') ?? '';

      if (_clienteId.isEmpty) {
        final meRes = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/clientes/me'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (meRes.statusCode == 200) {
          final data = jsonDecode(utf8.decode(meRes.bodyBytes));
          _clienteId = data['id'] ?? '';
          await prefs.setString('eq_clienteId', _clienteId);
        }
      }

      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/financiero/facturas/cliente/$_clienteId'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/financiero/facturas/cliente/$_clienteId/deuda'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      if (!mounted) return;

      if (results[0].statusCode == 200) {
        final list = jsonDecode(utf8.decode(results[0].bodyBytes)) as List;
        double deuda = 0;
        if (results[1].statusCode == 200) {
          final d = jsonDecode(utf8.decode(results[1].bodyBytes));
          deuda = (d['deuda'] as num?)?.toDouble() ?? 0;
        }
        setState(() {
          _facturas = list
              .map((e) => _Factura.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
          _deuda   = deuda;
          _loading = false;
        });
      } else {
        setState(() {
          _error   = 'Error al cargar facturas (${results[0].statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Sin conexión al servidor'; _loading = false; });
    }
  }

  void _verDetalle(_Factura f) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FacturaDetalleSheet(factura: f),
  );

  void _snack(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [
        // Header + banner deuda
        _FacHeader(
            total: _facturas.length, deuda: _deuda, onRefresh: _load),

        // Tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller:          _tabCtrl,
            isScrollable:        true,
            tabAlignment:        TabAlignment.start,
            labelColor:          const Color(0xFF1A237E),
            unselectedLabelColor:const Color(0xFF9CA3AF),
            indicatorColor:      const Color(0xFF1A237E),
            indicatorWeight:     2.5,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
            tabs: _tabs.map((t) {
              final count = switch (t) {
                'Emitida' => _facturas.where((f) => f.esEmitida).length,
                'Pagada'  => _facturas.where((f) => f.esPagada).length,
                'Vencida' => _facturas.where((f) => f.esVencida).length,
                _         => _facturas.length,
              };
              return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(t),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: t == 'Vencida'
                            ? const Color(0xFFC62828)
                            : const Color(0xFF1A237E),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$count', style: const TextStyle(
                        color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.bold)),
                  ),
                ],
              ]));
            }).toList(),
            onTap: (_) => setState(() {}),
          ),
        ),

        // Cuerpo
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _body() {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    if (_error != null)
      return _FacErrorView(message: _error!, onRetry: _load);

    final lista = _filtradas;
    if (lista.isEmpty)
      return _FacEmptyView(tab: _tabs[_tabCtrl.index]);

    return RefreshIndicator(
      onRefresh: _load, color: const Color(0xFF1A237E),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: lista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _FacturaCard(
          f:         lista[i],
          onDetalle: () => _verDetalle(lista[i]),
        ),
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _FacHeader extends StatelessWidget {
  final int total; final double deuda; final VoidCallback onRefresh;
  const _FacHeader({required this.total, required this.deuda,
    required this.onRefresh});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mis Facturas', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
            Text('$total factura${total == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
          ])),
          IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF6B7280)),
              onPressed: onRefresh),
        ]),
      ),
      // Banner deuda
      if (deuda > 0)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2))),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFC62828), size: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tienes facturas pendientes de pago',
                  style: TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 13, color: Color(0xFFC62828))),
              Text('Deuda total: \$${deuda.toStringAsFixed(2)} USD',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFE57373))),
            ])),
          ]),
        ),
    ]),
  );
}

// ─── CARD FACTURA ─────────────────────────────────────────────────────────────
class _FacturaCard extends StatelessWidget {
  final _Factura f; final VoidCallback onDetalle;
  const _FacturaCard({required this.f, required this.onDetalle});

  (Color, String, IconData) get _estadoInfo => switch (f.estado) {
    'BORRADOR' => (const Color(0xFF6B7280), 'Borrador',  Icons.edit_outlined),
    'EMITIDA'  => (const Color(0xFFF59E0B), 'Emitida',   Icons.receipt_outlined),
    'PAGADA'   => (const Color(0xFF2E7D32), 'Pagada',    Icons.check_circle_outline),
    'ANULADA'  => (const Color(0xFF9CA3AF), 'Anulada',   Icons.cancel_outlined),
    'VENCIDA'  => (const Color(0xFFC62828), 'Vencida',   Icons.schedule_outlined),
    _          => (const Color(0xFF6B7280), f.estado,    Icons.receipt_outlined),
  };

  String _labelFormaPago(String? fp) => switch (fp) {
    'EFECTIVO'      => 'Efectivo',
    'TRANSFERENCIA' => 'Transferencia',
    'DEPOSITO'      => 'Depósito',
    _               => fp?.replaceAll('_', ' ') ?? '-',
  };

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _estadoInfo;
    final borde = f.esEmitida
        ? const Color(0xFFFBBF24)
        : f.esVencida
        ? const Color(0xFFFFCDD2)
        : f.esPagada
        ? const Color(0xFFA5D6A7)
        : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borde),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Banner estado
        if (f.esEmitida || f.esVencida)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: f.esVencida
                    ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16))),
            child: Row(children: [
              Icon(f.esVencida
                  ? Icons.error_outline : Icons.pending_outlined,
                  size: 14,
                  color: f.esVencida
                      ? const Color(0xFFC62828) : const Color(0xFFE65100)),
              const SizedBox(width: 6),
              Text(f.esVencida
                  ? 'Factura vencida — contacta al equipo'
                  : 'Pendiente de pago',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: f.esVencida
                          ? const Color(0xFFC62828)
                          : const Color(0xFFE65100))),
            ]),
          ),

        // Cabecera
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.numeroFactura ?? 'BORRADOR', style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  fontFamily: 'monospace',
                  color: f.numeroFactura != null
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFF9CA3AF))),
              if (f.pedidoNumero != null)
                Text('Pedido: ${f.pedidoNumero}', style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
            ])),
            // Badge estado
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700, color: color)),
              ]),
            ),
          ]),
        ),

        // Montos highlight
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: f.esPagada
                      ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                      : f.esVencida
                      ? [const Color(0xFFFFEBEE), const Color(0xFFFCE4EC)]
                      : [const Color(0xFFF9FAFB), const Color(0xFFF3F4F6)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: f.esPagada
                      ? const Color(0xFFA5D6A7)
                      : f.esVencida
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFE5E7EB))),
          child: Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Subtotal', style: TextStyle(
                  fontSize: 10, color: Color(0xFF9CA3AF))),
              Text('\$${(f.subtotal0 + f.subtotal15).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
            ])),
            Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('IVA 15%', style: TextStyle(
                        fontSize: 10, color: Color(0xFF9CA3AF))),
                    Text('\$${f.iva.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ]),
            )),
            Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL', style: TextStyle(
                        fontSize: 10, color: Color(0xFF9CA3AF))),
                    Text('\$${f.total.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: f.esPagada
                                ? const Color(0xFF2E7D32)
                                : f.esVencida
                                ? const Color(0xFFC62828)
                                : const Color(0xFF1A237E))),
                  ]),
            )),
          ]),
        ),

        // Meta info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(spacing: 16, runSpacing: 6, children: [
            if (f.fechaEmision != null)
              _MetaChip(Icons.calendar_today_outlined,
                  'Emisión: ${f.fechaEmision}'),
            if (f.fechaVencimiento != null && !f.esPagada)
              _MetaChip(Icons.event_outlined,
                  'Vence: ${f.fechaVencimiento}',
                  color: f.esVencida
                      ? const Color(0xFFC62828) : null),
            if (f.formaPago != null)
              _MetaChip(Icons.payment_outlined,
                  _labelFormaPago(f.formaPago)),
          ]),
        ),

        // Botón ver detalle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDetalle,
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                    side: const BorderSide(color: Color(0xFFC5CAE9)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 11)),
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('Ver detalle completo',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600)),
              )),
        ),
      ]),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon; final String label; final Color? color;
  const _MetaChip(this.icon, this.label, {this.color});
  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12,
        color: color ?? const Color(0xFF9CA3AF)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 11,
        color: color ?? const Color(0xFF6B7280))),
  ]);
}

// ─── SHEET DETALLE COMPLETO ───────────────────────────────────────────────────
class _FacturaDetalleSheet extends StatelessWidget {
  final _Factura factura;
  const _FacturaDetalleSheet({required this.factura});

  String _labelFormaPago(String? fp) => switch (fp) {
    'EFECTIVO'      => 'Efectivo',
    'TRANSFERENCIA' => 'Transferencia bancaria',
    'DEPOSITO'      => 'Depósito bancario',
    _               => fp?.replaceAll('_', ' ') ?? '-',
  };

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
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // Header
            Row(children: [
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.numeroFactura ?? 'BORRADOR', style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
                if (f.pedidoNumero != null)
                  Text('Pedido: ${f.pedidoNumero}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
              ])),
              IconButton(icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 20),

            // Datos del emisor
            if (f.emisorRazonSocial != null) ...[
              _SecTitle('Datos del emisor'),
              const SizedBox(height: 8),
              _InfoBox(children: [
                if (f.emisorRazonSocial != null)
                  _InfoFila(Icons.business_outlined,
                      'Empresa', f.emisorRazonSocial!),
                if (f.emisorRuc != null)
                  _InfoFila(Icons.badge_outlined,
                      'RUC', f.emisorRuc!),
              ]),
              const SizedBox(height: 16),
            ],

            // Datos del cliente
            if (f.clienteNombre != null) ...[
              _SecTitle('Datos de facturación'),
              const SizedBox(height: 8),
              _InfoBox(children: [
                if (f.clienteNombre != null)
                  _InfoFila(Icons.person_outline_rounded,
                      'Nombre', f.clienteNombre!),
                if (f.clienteIdentificacion != null)
                  _InfoFila(Icons.badge_outlined,
                      'Cédula / RUC', f.clienteIdentificacion!),
                if (f.clienteEmail != null)
                  _InfoFila(Icons.email_outlined,
                      'Email', f.clienteEmail!),
                if (f.clienteDireccion != null)
                  _InfoFila(Icons.location_on_outlined,
                      'Dirección', f.clienteDireccion!),
              ]),
              const SizedBox(height: 16),
            ],

            // Detalles del servicio
            _SecTitle('Detalle del servicio'),
            const SizedBox(height: 8),
            if (f.detalles.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: const Text('Sin detalles disponibles',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              )
            else
              Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Column(children: [
                  // Header tabla
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12))),
                    child: const Row(children: [
                      Expanded(flex: 4, child: Text('Descripción',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280)))),
                      Expanded(flex: 1, child: Text('Cant.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280)))),
                      Expanded(flex: 2, child: Text('Subtotal',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280)))),
                    ]),
                  ),
                  // Filas
                  ...f.detalles.asMap().entries.map((e) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        border: e.key > 0
                            ? const Border(top: BorderSide(
                            color: Color(0xFFE5E7EB)))
                            : null),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(flex: 4, child: Text(
                                e.value.descripcion,
                                style: const TextStyle(fontSize: 12,
                                    color: Color(0xFF374151)))),
                            Expanded(flex: 1, child: Text(
                                e.value.cantidad.toStringAsFixed(0),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12,
                                    color: Color(0xFF374151)))),
                            Expanded(flex: 2, child: Text(
                                '\$${e.value.subtotal.toStringAsFixed(2)}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151)))),
                          ]),
                          Text(
                            '\$${e.value.precioUnitario.toStringAsFixed(2)} c/u'
                                ' · ${e.value.gravaIva ? 'IVA 15%' : 'Sin IVA'}',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF9CA3AF)),
                          ),
                        ]),
                  )),
                ]),
              ),
            const SizedBox(height: 16),

            // Totales
            _SecTitle('Totales'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(children: [
                if (f.subtotal0 > 0)
                  _TotalFila('Subtotal 0% (sin IVA)', f.subtotal0),
                if (f.subtotal15 > 0)
                  _TotalFila('Subtotal 15% (con IVA)', f.subtotal15),
                if (f.descuento > 0)
                  _TotalFila('Descuento', f.descuento, isNegative: true),
                _TotalFila('IVA 15%', f.iva),
                const Divider(height: 16),
                Row(children: [
                  const Text('TOTAL', style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18,
                      color: Color(0xFF1A1A2E))),
                  const Spacer(),
                  Text('\$${f.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 24,
                          color: Color(0xFF1A237E))),
                ]),
                if (f.formaPago != null) ...[
                  const Divider(height: 16),
                  Row(children: [
                    const Icon(Icons.payment_outlined,
                        size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Text('Forma de pago: ${_labelFormaPago(f.formaPago)}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 16),

            // Fechas
            _SecTitle('Información'),
            const SizedBox(height: 8),
            _InfoBox(children: [
              if (f.fechaEmision != null)
                _InfoFila(Icons.calendar_today_outlined,
                    'Fecha de emisión', f.fechaEmision!),
              if (f.fechaVencimiento != null)
                _InfoFila(Icons.event_outlined,
                    'Fecha de vencimiento', f.fechaVencimiento!),
              _InfoFila(Icons.circle_outlined, 'Estado',
                  f.estado.replaceAll('_', ' ')),
            ]),

            // Observaciones
            if (f.observaciones != null &&
                f.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFFDE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFF176))),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f.observaciones!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF374151)))),
                    ]),
              ),
            ],
          ]),
        )),
      ]),
    );
  }
}

// ─── WIDGETS DE APOYO ────────────────────────────────────────────────────────

class _SecTitle extends StatelessWidget {
  final String text;
  const _SecTitle(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 14,
        decoration: BoxDecoration(color: const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(fontWeight: FontWeight.w700,
        fontSize: 13, color: Color(0xFF374151))),
  ]);
}

class _InfoBox extends StatelessWidget {
  final List<Widget> children;
  const _InfoBox({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(children: children),
  );
}

class _InfoFila extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoFila(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(
          fontSize: 12, color: Color(0xFF9CA3AF))),
      Expanded(child: Text(value, textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12,
              fontWeight: FontWeight.w600, color: Color(0xFF374151)))),
    ]),
  );
}

class _TotalFila extends StatelessWidget {
  final String label; final double valor; final bool isNegative;
  const _TotalFila(this.label, this.valor, {this.isNegative = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(
          fontSize: 12, color: Color(0xFF6B7280)))),
      Text('${isNegative ? '-' : ''}\$${valor.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isNegative ? const Color(0xFFC62828)
                  : const Color(0xFF374151))),
    ]),
  );
}

// ─── VISTAS AUXILIARES ────────────────────────────────────────────────────────
class _FacEmptyView extends StatelessWidget {
  final String tab;
  const _FacEmptyView({required this.tab});
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
      Text(tab == 'Todas' ? 'No tienes facturas'
          : 'Sin facturas ${tab.toLowerCase()}',
          style: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      const Text('Tus facturas aparecerán aquí una vez emitidas',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          textAlign: TextAlign.center),
    ]),
  ));
}

class _FacErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
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
          style: const TextStyle(
              fontSize: 14, color: Color(0xFF6B7280))),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reintentar')),
    ]),
  ));
}