// lib/src/features/cliente/presentation/pages/cliente_cotizaciones_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../operations/presentation/widgets/pedido_form_sheet.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELO
// ═══════════════════════════════════════════════════════════════════════════════

class _Cotizacion {
  final String  id;
  final String  numeroCotizacion;
  final String  estado;
  final double  total;
  final double  subtotal;
  final double  montoIva;
  final double? pesoFacturable;
  final double? pesoReal;
  final String  validaHasta;
  final String? pedidoNumero;
  final String? pedidoId;
  final String? tarifaNombre;
  final String? detalleCalculo;
  final String? observaciones;
  final String  creadoEn;

  const _Cotizacion({
    required this.id,
    required this.numeroCotizacion,
    required this.estado,
    required this.total,
    required this.subtotal,
    required this.montoIva,
    this.pesoFacturable,
    this.pesoReal,
    required this.validaHasta,
    this.pedidoNumero,
    this.pedidoId,
    this.tarifaNombre,
    this.detalleCalculo,
    this.observaciones,
    required this.creadoEn,
  });

  factory _Cotizacion.fromJson(Map<String, dynamic> j) => _Cotizacion(
    id:               j['id'] ?? '',
    numeroCotizacion: j['numeroCotizacion'] ?? '',
    estado:           j['estado'] ?? '',
    total:            (j['total'] as num?)?.toDouble() ?? 0,
    subtotal:         (j['subtotal'] as num?)?.toDouble() ?? 0,
    montoIva:         (j['montoIva'] as num?)?.toDouble() ?? 0,
    pesoFacturable:   (j['pesoFacturable'] as num?)?.toDouble(),
    pesoReal:         (j['pesoReal'] as num?)?.toDouble(),
    validaHasta:      j['validaHasta'] ?? '',
    pedidoNumero:     j['pedidoNumero'],
    pedidoId:         j['pedidoId'],
    tarifaNombre:     j['tarifaNombre'],
    detalleCalculo:   j['detalleCalculo'],
    observaciones:    j['observaciones'],
    creadoEn:         j['creadoEn'] ?? '',
  );

  bool get esPendiente  => estado == 'PENDIENTE';
  bool get esAprobada   => estado == 'APROBADA';
  bool get esFacturada  => estado == 'FACTURADA';
  bool get esVencida    => estado == 'VENCIDA';
  bool get esCancelada  => estado == 'CANCELADA';
  bool get puedeAprobar => esPendiente;
  bool get puedeCancelar => esPendiente || esAprobada;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ClienteCotizacionesPage extends StatefulWidget {
  const ClienteCotizacionesPage({super.key});
  @override
  State<ClienteCotizacionesPage> createState() =>
      _ClienteCotizacionesPageState();
}

class _ClienteCotizacionesPageState extends State<ClienteCotizacionesPage>
    with SingleTickerProviderStateMixin {
  List<_Cotizacion> _cotizaciones = [];
  bool    _loading   = true;
  String? _error;
  String  _clienteId = '';

  // Filtro por estado
  late final TabController _tabCtrl;
  final _tabs = ['Todas', 'Pendiente', 'Aprobada', 'Facturada', 'Cancelada'];

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

  List<_Cotizacion> get _filtradas {
    final idx = _tabCtrl.index;
    if (idx == 0) return _cotizaciones;
    final estado = switch (idx) {
      1 => 'PENDIENTE',
      2 => 'APROBADA',
      3 => 'FACTURADA',
      4 => 'CANCELADA',
      _ => '',
    };
    return _cotizaciones.where((c) => c.estado == estado).toList();
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

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/financiero/cotizaciones/cliente/$_clienteId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _cotizaciones = list
              .map((e) => _Cotizacion.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar cotizaciones (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Sin conexión al servidor'; _loading = false; });
    }
  }

  // ─── Aprobar cotización ───────────────────────────────────────────────────
  void _aprobar(_Cotizacion c) {
    if (c.pedidoId == null) {
      _snack('No se encontró el pedido asociado', ok: false);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AprobarCotizacionSheet(
        cotizacion: c,
        clienteId:  _clienteId,
        onAprobada: () {
          _load();
          _snack('✅ Cotización aprobada. Sube tu comprobante de pago.', ok: true);
        },
      ),
    );
  }

  // ─── Cancelar cotización ──────────────────────────────────────────────────
  Future<void> _cancelar(_Cotizacion c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cancelar cotización?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.numeroCotizacion, style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
              const SizedBox(height: 4),
              Text('Total: \$${c.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 10),
              const Text(
                'Se cancelará la cotización y el pedido asociado. '
                    'Esta acción no se puede deshacer.',
                style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
            ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar cotización'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res   = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/financiero/cotizaciones/${c.id}/cancelar-cliente'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (res.statusCode == 204) {
        _snack('Cotización cancelada', ok: true);
        _load();
      } else {
        String msg = 'Error al cancelar';
        try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
        _snack(msg, ok: false);
      }
    } catch (_) {
      if (mounted) _snack('Sin conexión', ok: false);
    }
  }

  void _verDetalle(_Cotizacion c) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DetalleCotizacionSheet(cotizacion: c),
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
        // Header
        _CotHeader(
          total:     _cotizaciones.length,
          pendientes: _cotizaciones.where((c) => c.esPendiente).length,
          onRefresh: _load,
        ),
        // Tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller:       _tabCtrl,
            isScrollable:     true,
            labelColor:       const Color(0xFF1A237E),
            unselectedLabelColor: const Color(0xFF9CA3AF),
            indicatorColor:   const Color(0xFF1A237E),
            indicatorWeight:  2.5,
            tabAlignment:     TabAlignment.start,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
            tabs: _tabs.map((t) {
              final count = switch (t) {
                'Pendiente'  => _cotizaciones.where((c) => c.esPendiente).length,
                'Aprobada'   => _cotizaciones.where((c) => c.esAprobada).length,
                'Facturada'  => _cotizaciones.where((c) => c.esFacturada).length,
                'Cancelada'  => _cotizaciones.where((c) => c.esCancelada).length,
                _            => _cotizaciones.length,
              };
              return Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(t),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1A237E),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('$count', style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
              );
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
    if (_error != null) return _CotErrorView(message: _error!, onRetry: _load);

    final lista = _filtradas;
    if (lista.isEmpty) return _CotEmptyView(tab: _tabs[_tabCtrl.index]);

    return RefreshIndicator(
      onRefresh: _load, color: const Color(0xFF1A237E),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: lista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _CotizacionCard(
          c:           lista[i],
          onAprobar:   lista[i].puedeAprobar   ? () => _aprobar(lista[i])   : null,
          onCancelar:  lista[i].puedeCancelar  ? () => _cancelar(lista[i])  : null,
          onDetalle:   () => _verDetalle(lista[i]),
        ),
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _CotHeader extends StatelessWidget {
  final int total, pendientes;
  final VoidCallback onRefresh;
  const _CotHeader({
    required this.total, required this.pendientes, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mis Cotizaciones', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
            Row(children: [
              Text('$total cotización${total == 1 ? '' : 'es'}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              if (pendientes > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCC02))),
                  child: Text('$pendientes pendiente${pendientes == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100))),
                ),
              ],
            ]),
          ])),
      IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
          onPressed: onRefresh),
    ]),
  );
}

// ─── CARD COTIZACIÓN ──────────────────────────────────────────────────────────
class _CotizacionCard extends StatelessWidget {
  final _Cotizacion  c;
  final VoidCallback? onAprobar, onCancelar;
  final VoidCallback  onDetalle;

  const _CotizacionCard({
    required this.c, this.onAprobar,
    this.onCancelar, required this.onDetalle});

  (Color, String, IconData) get _estadoInfo => switch (c.estado) {
    'PENDIENTE' => (const Color(0xFFF59E0B), 'Pendiente', Icons.hourglass_empty_rounded),
    'APROBADA'  => (const Color(0xFF2E7D32), 'Aprobada',  Icons.check_circle_outline),
    'FACTURADA' => (const Color(0xFF1A237E), 'Facturada', Icons.receipt_rounded),
    'VENCIDA'   => (const Color(0xFF9CA3AF), 'Vencida',   Icons.schedule_rounded),
    'CANCELADA' => (const Color(0xFFC62828), 'Cancelada', Icons.cancel_outlined),
    _           => (const Color(0xFF6B7280), c.estado,    Icons.help_outline),
  };

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _estadoInfo;
    final borde = c.esPendiente
        ? const Color(0xFFFBBF24)
        : c.esAprobada
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

        // Banner pendiente
        if (c.esPendiente)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              const Icon(Icons.hourglass_empty_rounded,
                  size: 14, color: Color(0xFFE65100)),
              const SizedBox(width: 6),
              const Text('Pendiente de tu aprobación',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFFE65100))),
            ]),
          ),

        // Banner aprobada
        if (c.esAprobada)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: const Row(children: [
              Icon(Icons.check_circle_outline,
                  size: 14, color: Color(0xFF2E7D32)),
              SizedBox(width: 6),
              Text('Aprobada — sube tu comprobante de pago',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32))),
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
              Text(c.numeroCotizacion, style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  fontFamily: 'monospace', color: Color(0xFF1A1A2E))),
              if (c.pedidoNumero != null)
                Text('Pedido: ${c.pedidoNumero}', style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
              if (c.tarifaNombre != null)
                Text(c.tarifaNombre!, style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280))),
            ])),
            // Badge estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700, color: color)),
              ]),
            ),
          ]),
        ),

        // Desglose de montos
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(children: [
            _MontoFila('Subtotal', c.subtotal),
            const SizedBox(height: 4),
            _MontoFila('IVA 15%', c.montoIva),
            const Divider(height: 14),
            _MontoFila('TOTAL', c.total, bold: true,
                color: const Color(0xFF1A237E)),
            if (c.pesoFacturable != null) ...[
              const Divider(height: 12),
              Row(children: [
                const Icon(Icons.scale_outlined,
                    size: 13, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text(
                    'Peso: ${c.pesoReal?.toStringAsFixed(2) ?? '-'} lb real '
                        '/ ${c.pesoFacturable!.toStringAsFixed(2)} lb facturable',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
              ]),
            ],
          ]),
        ),

        // Fecha validez
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 12, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Text('Válida hasta: ${c.validaHasta}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280))),
            const Spacer(),
            GestureDetector(
              onTap: onDetalle,
              child: const Row(children: [
                Text('Ver detalle',
                    style: TextStyle(fontSize: 11,
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.w600)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: Color(0xFF1A237E)),
              ]),
            ),
          ]),
        ),

        // Acciones
        if (onAprobar != null || onCancelar != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              if (onCancelar != null)
                Expanded(child: OutlinedButton.icon(
                  onPressed: onCancelar,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(color: Color(0xFFC62828)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11)),
                  icon: const Icon(Icons.close_rounded, size: 15),
                  label: const Text('Cancelar',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600)),
                )),
              if (onAprobar != null && onCancelar != null)
                const SizedBox(width: 10),
              if (onAprobar != null)
                Expanded(child: ElevatedButton.icon(
                  onPressed: onAprobar,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11)),
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: const Text('Aprobar',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600)),
                )),
            ]),
          ),
      ]),
    );
  }
}

class _MontoFila extends StatelessWidget {
  final String label;
  final double valor;
  final bool   bold;
  final Color  color;
  const _MontoFila(this.label, this.valor,
      {this.bold = false, this.color = const Color(0xFF374151)});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: TextStyle(
        fontSize: bold ? 14 : 12,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: bold ? const Color(0xFF1A1A2E) : const Color(0xFF6B7280)))),
    Text('\$${valor.toStringAsFixed(2)}', style: TextStyle(
        fontSize: bold ? 18 : 13,
        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        color: color)),
  ]);
}

// ─── SHEET APROBAR ────────────────────────────────────────────────────────────
class _AprobarCotizacionSheet extends StatefulWidget {
  final _Cotizacion  cotizacion;
  final String       clienteId;
  final VoidCallback onAprobada;

  const _AprobarCotizacionSheet({
    required this.cotizacion,
    required this.clienteId,
    required this.onAprobada,
  });

  @override
  State<_AprobarCotizacionSheet> createState() =>
      _AprobarCotizacionSheetState();
}

class _AprobarCotizacionSheetState extends State<_AprobarCotizacionSheet> {
  String _formaPago        = 'TRANSFERENCIA';
  bool   _usarDatosCliente = true;
  bool   _submitting       = false;

  final _bancoCtrl     = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _factRazonCtrl  = TextEditingController();
  final _factRucCtrl    = TextEditingController();
  final _factEmailCtrl  = TextEditingController();
  final _factTelCtrl    = TextEditingController();
  final _factDirCtrl    = TextEditingController();

  @override
  void dispose() {
    for (final c in [_bancoCtrl, _referenciaCtrl, _factRazonCtrl,
      _factRucCtrl, _factEmailCtrl, _factTelCtrl, _factDirCtrl])
      c.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_formaPago == 'TRANSFERENCIA' && _bancoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresa el banco de origen'),
        backgroundColor: Color(0xFFC62828),
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final body  = {
        'formaPago':        _formaPago,
        'bancoOrigen':      _bancoCtrl.text.trim(),
        'referenciaPago':   _referenciaCtrl.text.trim(),
        'datosFacturacion': {
          'usarDatosCliente': _usarDatosCliente,
          if (!_usarDatosCliente) ...{
            'razonSocial':          _factRazonCtrl.text.trim(),
            'rucCedula':            _factRucCtrl.text.trim(),
            'emailFacturacion':     _factEmailCtrl.text.trim(),
            'telefonoFacturacion':  _factTelCtrl.text.trim(),
            'direccionFacturacion': _factDirCtrl.text.trim(),
          },
        },
      };
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/financiero/cotizaciones/'
            '${widget.cotizacion.id}/aprobar-cliente'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
        },
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context);
        widget.onAprobada();
      } else {
        String msg = 'Error al aprobar';
        try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg), backgroundColor: const Color(0xFFC62828)));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin conexión al servidor'),
              backgroundColor: Color(0xFFC62828)));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cotizacion;
    return Container(
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
        Flexible(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Expanded(child: Text('Aprobar cotización',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E)))),
                  IconButton(icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 16),

                // Resumen cotización
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF283593)]),
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.calculate_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(c.numeroCotizacion,
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const Spacer(),
                          Text('\$${c.total.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w900, fontSize: 20)),
                        ]),
                        const SizedBox(height: 4),
                        Text('Subtotal: \$${c.subtotal.toStringAsFixed(2)}'
                            ' + IVA: \$${c.montoIva.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.white.withOpacity(0.8),
                                fontSize: 11)),
                      ]),
                ),
                const SizedBox(height: 20),

                // Forma de pago
                const Text('Forma de pago', style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13,
                    color: Color(0xFF374151))),
                const SizedBox(height: 10),
                Row(children: ['EFECTIVO', 'TRANSFERENCIA'].map((f) {
                  final sel = _formaPago == f;
                  return Expanded(child: Padding(
                    padding: EdgeInsets.only(right: f == 'EFECTIVO' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _formaPago = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                            color: sel ? const Color(0xFFE8F5E9) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: sel ? const Color(0xFF2E7D32)
                                    : const Color(0xFFE5E7EB),
                                width: sel ? 2 : 1)),
                        child: Column(children: [
                          Icon(f == 'EFECTIVO'
                              ? Icons.payments_outlined
                              : Icons.account_balance_outlined,
                              color: sel ? const Color(0xFF2E7D32)
                                  : const Color(0xFF9CA3AF), size: 22),
                          const SizedBox(height: 6),
                          Text(f == 'EFECTIVO' ? 'Efectivo' : 'Transferencia',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? const Color(0xFF2E7D32)
                                      : const Color(0xFF9CA3AF))),
                        ]),
                      ),
                    ),
                  ));
                }).toList()),
                const SizedBox(height: 14),

                if (_formaPago == 'TRANSFERENCIA') ...[
                  Row(children: [
                    Expanded(child: TextFormField(
                        controller: _bancoCtrl,
                        decoration: _cDeco('Banco origen *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(
                        controller: _referenciaCtrl,
                        decoration: _cDeco('Referencia (opcional)'))),
                  ]),
                  const SizedBox(height: 14),
                ],

                // Facturación
                const Text('Datos de facturación', style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13,
                    color: Color(0xFF374151))),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () =>
                      setState(() => _usarDatosCliente = !_usarDatosCliente),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: _usarDatosCliente
                            ? const Color(0xFFE8EAF6) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _usarDatosCliente
                                ? const Color(0xFF1A237E)
                                : const Color(0xFFE5E7EB),
                            width: _usarDatosCliente ? 2 : 1)),
                    child: Row(children: [
                      Icon(_usarDatosCliente
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                          color: _usarDatosCliente
                              ? const Color(0xFF1A237E)
                              : const Color(0xFF9CA3AF), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Usar mis datos personales', style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13,
                                color: Color(0xFF374151))),
                            Text('Nombre, cédula y correo registrados',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF9CA3AF))),
                          ])),
                    ]),
                  ),
                ),

                if (!_usarDatosCliente) ...[
                  const SizedBox(height: 10),
                  TextFormField(controller: _factRazonCtrl,
                      decoration: _cDeco('Razón social o nombre')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _factRucCtrl,
                        decoration: _cDeco('RUC / Cédula'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: _factTelCtrl,
                        decoration: _cDeco('Teléfono'))),
                  ]),
                  const SizedBox(height: 8),
                  TextFormField(controller: _factEmailCtrl,
                      decoration: _cDeco('Correo electrónico')),
                  const SizedBox(height: 8),
                  TextFormField(controller: _factDirCtrl,
                      decoration: _cDeco('Dirección')),
                ],
                const SizedBox(height: 24),

                SizedBox(height: 52, child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _confirmar,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(_submitting ? 'Procesando...' : 'Confirmar aprobación ✓',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                )),
              ]),
        )),
      ]),
    );
  }
}

// ─── SHEET DETALLE ────────────────────────────────────────────────────────────
class _DetalleCotizacionSheet extends StatelessWidget {
  final _Cotizacion cotizacion;
  const _DetalleCotizacionSheet({required this.cotizacion});

  @override
  Widget build(BuildContext context) {
    final c = cotizacion;
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.numeroCotizacion, style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
                if (c.pedidoNumero != null)
                  Text('Pedido: ${c.pedidoNumero}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
              ])),
              IconButton(icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 20),

            // Montos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(children: [
                if (c.pesoReal != null)
                  _DetalleFila('Peso real',
                      '${c.pesoReal!.toStringAsFixed(2)} lb'),
                if (c.pesoFacturable != null)
                  _DetalleFila('Peso facturable',
                      '${c.pesoFacturable!.toStringAsFixed(2)} lb'),
                if (c.detalleCalculo != null &&
                    c.detalleCalculo!.isNotEmpty) ...[
                  const Divider(height: 16),
                  Text(c.detalleCalculo!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280))),
                ],
                const Divider(height: 16),
                _DetalleFila('Subtotal',
                    '\$${c.subtotal.toStringAsFixed(2)}'),
                _DetalleFila('IVA 15%',
                    '\$${c.montoIva.toStringAsFixed(2)}'),
                const Divider(height: 12),
                Row(children: [
                  const Text('TOTAL', style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16,
                      color: Color(0xFF1A1A2E))),
                  const Spacer(),
                  Text('\$${c.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800,
                          fontSize: 22, color: Color(0xFF1A237E))),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Info adicional
            _DetalleFila('Estado', c.estado.replaceAll('_', ' ')),
            _DetalleFila('Válida hasta', c.validaHasta),
            if (c.tarifaNombre != null)
              _DetalleFila('Tarifa', c.tarifaNombre!),
            if (c.observaciones != null && c.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFFDE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFF176))),
                child: Text(c.observaciones!,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF374151))),
              ),
            ],
          ]),
        )),
      ]),
    );
  }
}

class _DetalleFila extends StatelessWidget {
  final String label, value;
  const _DetalleFila(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(
          fontSize: 12, color: Color(0xFF9CA3AF))),
      Expanded(child: Text(value, textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 12,
              fontWeight: FontWeight.w600, color: Color(0xFF374151)))),
    ]),
  );
}

// ─── VISTAS AUXILIARES ────────────────────────────────────────────────────────
class _CotEmptyView extends StatelessWidget {
  final String tab;
  const _CotEmptyView({required this.tab});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6), shape: BoxShape.circle),
          child: const Icon(Icons.calculate_outlined,
              size: 48, color: Color(0xFF1A237E))),
      const SizedBox(height: 16),
      Text(tab == 'Todas'
          ? 'No tienes cotizaciones'
          : 'Sin cotizaciones $tab'.toLowerCase(),
          style: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      const Text('Crea un pedido con cotización para verlo aquí',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          textAlign: TextAlign.center),
    ]),
  ));
}

class _CotErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CotErrorView({required this.message, required this.onRetry});
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reintentar')),
    ]),
  ));
}

InputDecoration _cDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFC62828))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFC62828), width: 2)),
);