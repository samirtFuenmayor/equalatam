// lib/src/features/cliente/presentation/pages/cliente_pedidos_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELOS LOCALES
// ═══════════════════════════════════════════════════════════════════════════════

class _PedidoResumen {
  final String id;
  final String numeroPedido;
  final String tipo;
  final String descripcion;
  final String estadoLogistico;
  final String estadoFinanciero;
  final String? cotizacionId;
  final double? totalCotizado;
  final String? facturaId;
  final String? numeroFactura;
  final double? totalFactura;
  final String fechaRegistro;

  const _PedidoResumen({
    required this.id,
    required this.numeroPedido,
    required this.tipo,
    required this.descripcion,
    required this.estadoLogistico,
    required this.estadoFinanciero,
    this.cotizacionId,
    this.totalCotizado,
    this.facturaId,
    this.numeroFactura,
    this.totalFactura,
    required this.fechaRegistro,
  });

  factory _PedidoResumen.fromJson(Map<String, dynamic> j) => _PedidoResumen(
    id:               j['id'] ?? '',
    numeroPedido:     j['numeroPedido'] ?? '',
    tipo:             j['tipo'] ?? '',
    descripcion:      j['descripcion'] ?? '',
    estadoLogistico:  j['estadoLogistico'] ?? '',
    estadoFinanciero: j['estadoFinanciero'] ?? 'SIN_COTIZAR',
    cotizacionId:     j['cotizacionId'],
    totalCotizado:    (j['totalCotizado'] as num?)?.toDouble(),
    facturaId:        j['facturaId'],
    numeroFactura:    j['numeroFactura'],
    totalFactura:     (j['totalFactura'] as num?)?.toDouble(),
    fechaRegistro:    j['fechaRegistro'] ?? '',
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ClientePedidosPage extends StatefulWidget {
  const ClientePedidosPage({super.key});
  @override
  State<ClientePedidosPage> createState() => _ClientePedidosPageState();
}

class _ClientePedidosPageState extends State<ClientePedidosPage> {
  List<_PedidoResumen> _pedidos   = [];
  bool                 _loading   = true;
  String?              _error;
  String               _clienteId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs    = await SharedPreferences.getInstance();
      final token    = prefs.getString('eq_token') ?? '';
      _clienteId     = prefs.getString('eq_clienteId') ?? '';

      if (_clienteId.isEmpty) {
        // Intentar obtener clienteId desde /api/auth/me o desde el token
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

      if (_clienteId.isEmpty) {
        setState(() { _error = 'No se pudo identificar tu cuenta.'; _loading = false; });
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/pedidos/cliente/$_clienteId/resumen'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _pedidos = list.map((e) => _PedidoResumen.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Error al cargar pedidos (${res.statusCode})'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Sin conexión al servidor'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [
        _Header(total: _pedidos.length, onRefresh: _load, onNuevo: _openNuevoPedido),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);
    if (_pedidos.isEmpty) return const _EmptyView();
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A237E),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _pedidos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _PedidoCard(
          pedido: _pedidos[i],
          onVerTracking: () => _verTracking(_pedidos[i]),
        ),
      ),
    );
  }

  void _verTracking(_PedidoResumen p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackingSheet(numeroPedido: p.numeroPedido),
    );
  }

  void _openNuevoPedido() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NuevoPedidoSheet(onCreado: _load),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int total;
  final VoidCallback onRefresh, onNuevo;
  const _Header({required this.total, required this.onRefresh, required this.onNuevo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mis Pedidos', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          Text('$total pedido${total == 1 ? '' : 's'} registrado${total == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ])),
        IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
            onPressed: onRefresh),
        const SizedBox(width: 6),
        SizedBox(height: 42, child: ElevatedButton.icon(
          onPressed: onNuevo,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nuevo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        )),
      ]),
    );
  }
}

// ─── CARD DE PEDIDO ───────────────────────────────────────────────────────────
class _PedidoCard extends StatelessWidget {
  final _PedidoResumen pedido;
  final VoidCallback   onVerTracking;
  const _PedidoCard({required this.pedido, required this.onVerTracking});

  @override
  Widget build(BuildContext context) {
    final p = pedido;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabecera
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
          child: Row(children: [
            Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF1A237E), size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.numeroPedido, style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  fontFamily: 'monospace', color: Color(0xFF1A1A2E))),
              Text(p.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            _TipoBadge(p.tipo),
          ]),
        ),
        // Estado logístico + financiero
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Estado logístico', style: TextStyle(
                    fontSize: 10, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 4),
                _LogisticoBadge(p.estadoLogistico),
              ])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Estado de pago', style: TextStyle(
                    fontSize: 10, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 4),
                _FinancieroBadge(p.estadoFinanciero),
              ])),
            ]),
            // Si tiene cotización o factura, mostrar el monto
            if (p.totalCotizado != null || p.totalFactura != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Row(children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 16, color: Color(0xFF1A237E)),
                  const SizedBox(width: 8),
                  if (p.numeroFactura != null) ...[
                    Text('Factura: ${p.numeroFactura}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                    const Spacer(),
                    Text('\$${p.totalFactura!.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 14, color: Color(0xFF1A237E))),
                  ] else if (p.totalCotizado != null) ...[
                    const Text('Cotización pendiente',
                        style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
                    const Spacer(),
                    Text('\$${p.totalCotizado!.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 14, color: Color(0xFFF59E0B))),
                  ],
                ]),
              ),
            ],
            const SizedBox(height: 12),
            // Botón tracking
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: onVerTracking,
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFFC5CAE9)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10)),
              icon: const Icon(Icons.track_changes_outlined, size: 16),
              label: const Text('Ver tracking', style: TextStyle(fontSize: 13)),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ─── SHEET TRACKING ───────────────────────────────────────────────────────────
class _TrackingSheet extends StatefulWidget {
  final String numeroPedido;
  const _TrackingSheet({required this.numeroPedido});
  @override State<_TrackingSheet> createState() => _TrackingSheetState();
}

class _TrackingSheetState extends State<_TrackingSheet> {
  List<dynamic> _eventos = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/tracking/public/${widget.numeroPedido}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _eventos = data['eventos'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ClienteSheet(
      title: 'Tracking',
      subtitle: widget.numeroPedido,
      child: _loading
          ? const Center(child: Padding(padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFF1A237E))))
          : _eventos.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(32),
          child: Text('Sin eventos de tracking',
              style: TextStyle(color: Color(0xFF9CA3AF)))))
          : Column(
        children: _eventos.asMap().entries.map((e) {
          final ev    = e.value;
          final isLast = e.key == _eventos.length - 1;
          return _TrackingItem(
            estado:      ev['estado'] ?? '',
            descripcion: ev['descripcion'] ?? '',
            fecha:       ev['fecha'] ?? '',
            isLast:      isLast,
          );
        }).toList(),
      ),
    );
  }
}

class _TrackingItem extends StatelessWidget {
  final String estado, descripcion, fecha;
  final bool   isLast;
  const _TrackingItem({required this.estado, required this.descripcion,
    required this.fecha, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 20, height: 20,
            decoration: const BoxDecoration(
                color: Color(0xFF1A237E), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 12, color: Colors.white)),
        if (!isLast) Container(width: 2, height: 40, color: const Color(0xFFE5E7EB)),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(estado, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1A2E))),
          Text(descripcion, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Text(fecha, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ]),
      )),
    ]);
  }
}

// ─── SHEET NUEVO PEDIDO ───────────────────────────────────────────────────────
class _NuevoPedidoSheet extends StatefulWidget {
  final VoidCallback onCreado;
  const _NuevoPedidoSheet({required this.onCreado});
  @override State<_NuevoPedidoSheet> createState() => _NuevoPedidoSheetState();
}

class _NuevoPedidoSheetState extends State<_NuevoPedidoSheet> {
  final _key        = GlobalKey<FormState>();
  final _descCtrl   = TextEditingController();
  final _pesoCtrl   = TextEditingController();
  final _largoCtrl  = TextEditingController();
  final _anchoCtrl  = TextEditingController();
  final _altoCtrl   = TextEditingController();
  final _valorCtrl  = TextEditingController();
  final _trackCtrl  = TextEditingController();
  final _provCtrl   = TextEditingController();

  bool   _cotizar  = true;
  String _tipo     = 'IMPORTACION';
  String _categoria = 'GENERAL';
  String? _origenId;
  String? _destinoId;
  List<Map<String, String>> _sucursales = [];
  bool _loadingSuc = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSucursales();
  }

  Future<void> _loadSucursales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/sucursales'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _sucursales = list.map((s) => {
            'id':     s['id'].toString(),
            'nombre': s['nombre'].toString(),
            'pais':   s['pais'].toString(),
          }).toList();
          _loadingSuc = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSuc = false);
    }
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    if (_origenId == null || _destinoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona sucursal origen y destino'),
          backgroundColor: Color(0xFFC62828)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final prefs    = await SharedPreferences.getInstance();
      final token    = prefs.getString('eq_token') ?? '';
      final clienteId = prefs.getString('eq_clienteId') ?? '';

      final body = <String, dynamic>{
        'tipo':              _tipo,
        'clienteId':         clienteId,
        'descripcion':       _descCtrl.text.trim(),
        'sucursalOrigenId':  _origenId,
        'sucursalDestinoId': _destinoId,
        'solicitaCotizacion':_cotizar,
        if (_cotizar) 'categoria': _categoria,
        if (_pesoCtrl.text.isNotEmpty)  'peso':  double.tryParse(_pesoCtrl.text),
        if (_largoCtrl.text.isNotEmpty) 'largo': double.tryParse(_largoCtrl.text),
        if (_anchoCtrl.text.isNotEmpty) 'ancho': double.tryParse(_anchoCtrl.text),
        if (_altoCtrl.text.isNotEmpty)  'alto':  double.tryParse(_altoCtrl.text),
        if (_valorCtrl.text.isNotEmpty) 'valorDeclarado': double.tryParse(_valorCtrl.text),
        if (_trackCtrl.text.isNotEmpty) 'trackingExterno': _trackCtrl.text.trim(),
        if (_provCtrl.text.isNotEmpty)  'proveedor': _provCtrl.text.trim(),
      };

      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/pedidos'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      if (res.statusCode == 201) {
        Navigator.pop(context);
        widget.onCreado();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_cotizar
              ? '✅ Pedido creado. Cotización generada automáticamente.'
              : '✅ Pedido creado correctamente.'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        String msg = 'Error al crear el pedido';
        try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg), backgroundColor: const Color(0xFFC62828)));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sin conexión al servidor'),
          backgroundColor: Color(0xFFC62828)));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  void dispose() {
    for (final c in [_descCtrl, _pesoCtrl, _largoCtrl, _anchoCtrl,
      _altoCtrl, _valorCtrl, _trackCtrl, _provCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ClienteSheet(
      title: 'Nuevo Pedido',
      child: Form(key: _key, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // Tipo
        _CLabel('Tipo de envío'),
        const SizedBox(height: 8),
        Row(children: ['IMPORTACION', 'EXPORTACION'].map((t) {
          final sel = _tipo == t;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: t == 'IMPORTACION' ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _tipo = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: sel ? const Color(0xFFE8EAF6) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB),
                        width: sel ? 2 : 1)),
                child: Column(children: [
                  Icon(t == 'IMPORTACION'
                      ? Icons.flight_land_rounded : Icons.flight_takeoff_rounded,
                      color: sel ? const Color(0xFF1A237E) : const Color(0xFF9CA3AF),
                      size: 20),
                  const SizedBox(height: 4),
                  Text(t == 'IMPORTACION' ? 'Importación' : 'Exportación',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? const Color(0xFF1A237E) : const Color(0xFF9CA3AF))),
                ]),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 16),

        // Descripción
        _CLabel('¿Qué vas a enviar? *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl, maxLines: 2,
          decoration: _cDeco('Ej: Ropa y calzado deportivo'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),

        // Cotización toggle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _cotizar ? const Color(0xFFE8EAF6) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _cotizar ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB))),
          child: Row(children: [
            Icon(_cotizar ? Icons.calculate_outlined : Icons.send_outlined,
                color: _cotizar ? const Color(0xFF1A237E) : const Color(0xFF6B7280), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_cotizar ? 'Quiero una cotización primero' : 'Enviar directamente',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(_cotizar
                  ? 'Te enviamos el precio antes de procesar'
                  : 'El administrador gestionará tu pedido',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ])),
            Switch(
              value: _cotizar,
              onChanged: (v) => setState(() => _cotizar = v),
              activeColor: const Color(0xFF1A237E),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Categoría (solo si cotizar)
        if (_cotizar) ...[
          _CLabel('Categoría del paquete'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _categoria,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: const [
                  DropdownMenuItem(value: 'GENERAL',    child: Text('General')),
                  DropdownMenuItem(value: 'PEQUENO',    child: Text('Paquete Pequeño')),
                  DropdownMenuItem(value: 'MEDIANO',    child: Text('Paquete Mediano')),
                  DropdownMenuItem(value: 'GRANDE',     child: Text('Paquete Grande')),
                  DropdownMenuItem(value: 'DOCUMENTOS', child: Text('Documentos')),
                  DropdownMenuItem(value: 'FRAGIL',     child: Text('Frágil')),
                ],
                onChanged: (v) => setState(() => _categoria = v!),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Peso y dimensiones
        _CLabel('Peso (libras)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pesoCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _cDeco('Ej: 2.5'),
          validator: _cotizar
              ? (v) => v == null || v.isEmpty ? 'Requerido para cotizar' : null
              : null,
        ),
        const SizedBox(height: 14),

        _CLabel('Dimensiones (cm) — opcional'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextFormField(controller: _largoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _cDeco('Largo'))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _anchoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _cDeco('Ancho'))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _altoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _cDeco('Alto'))),
        ]),
        const SizedBox(height: 14),

        _CLabel('Valor declarado (USD) — opcional'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _valorCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _cDeco('Ej: 150.00'),
        ),
        const SizedBox(height: 14),

        _CLabel('Tracking externo — opcional'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextFormField(controller: _trackCtrl,
              decoration: _cDeco('Ej: TBA123456789'))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _provCtrl,
              decoration: _cDeco('Amazon, FedEx...'))),
        ]),
        const SizedBox(height: 14),

        // Sucursales
        _CLabel('Sucursal origen *'),
        const SizedBox(height: 8),
        _loadingSuc
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
            : _SucDropdown(
            hint: 'Sede exterior donde llega',
            value: _origenId,
            sucursales: _sucursales,
            excluir: _destinoId,
            onChanged: (v) => setState(() => _origenId = v)),
        const SizedBox(height: 14),
        _CLabel('Sucursal destino *'),
        const SizedBox(height: 8),
        _SucDropdown(
            hint: 'Sucursal en Ecuador',
            value: _destinoId,
            sucursales: _sucursales,
            excluir: _origenId,
            onChanged: (v) => setState(() => _destinoId = v)),
        const SizedBox(height: 24),

        SizedBox(height: 50, child: ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: _submitting
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(_cotizar ? 'Crear y cotizar' : 'Crear pedido',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        )),
      ])),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════════

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge(this.tipo);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: tipo == 'IMPORTACION' ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC),
          borderRadius: BorderRadius.circular(8)),
      child: Text(tipo == 'IMPORTACION' ? 'Importación' : 'Exportación',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: tipo == 'IMPORTACION'
                  ? const Color(0xFF1565C0) : const Color(0xFFC62828))));
}

class _LogisticoBadge extends StatelessWidget {
  final String estado;
  const _LogisticoBadge(this.estado);

  Color get _color => switch (estado) {
    'REGISTRADO'             => const Color(0xFF1A237E),
    'RECIBIDO_EN_SEDE'       => const Color(0xFF7B1FA2),
    'EN_TRANSITO'            => const Color(0xFFE65100),
    'EN_ADUANA'              => const Color(0xFFF57F17),
    'DISPONIBLE_EN_SUCURSAL' => const Color(0xFF2E7D32),
    'ENTREGADO'              => const Color(0xFF388E3C),
    _                        => const Color(0xFF6B7280),
  };

  String get _label => estado.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(_label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _color)),
      ]));
}

class _FinancieroBadge extends StatelessWidget {
  final String estado;
  const _FinancieroBadge(this.estado);

  (Color, String) get _info => switch (estado) {
    'SIN_COTIZAR'          => (const Color(0xFF9CA3AF), 'Sin cotizar'),
    'COTIZADO'             => (const Color(0xFFF59E0B), 'Cotizado'),
    'PENDIENTE_PAGO'       => (const Color(0xFFE65100), 'Pendiente pago'),
    'LISTO_PARA_FACTURAR'  => (const Color(0xFF7B1FA2), 'Listo para facturar'),
    'EMITIDA'              => (const Color(0xFF1A237E), 'Facturado'),
    'PAGADA'               => (const Color(0xFF2E7D32), 'Pagado'),
    'VENCIDA'              => (const Color(0xFFC62828), 'Vencida'),
    _                      => (const Color(0xFF6B7280), estado.replaceAll('_', ' ')),
  };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _info;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ]));
  }
}

class _SucDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final String? excluir;
  final List<Map<String, String>> sucursales;
  final void Function(String?) onChanged;
  const _SucDropdown({
    required this.hint,
    required this.value,
    required this.sucursales,
    required this.onChanged,
    this.excluir,
  });

  @override
  Widget build(BuildContext context) {
    final items = sucursales.where((s) => s['id'] != excluir).toList();
    final cur   = (value != null && items.any((s) => s['id'] == value)) ? value : null;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                value: cur,
                hint: Text(hint, style: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 14)),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: items.map((s) => DropdownMenuItem(
                    value: s['id'],
                    child: Text('${s['nombre']} (${s['pais']})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: onChanged)));
  }
}
class _ClienteSheet extends StatelessWidget {
  final String  title;
  final String? subtitle;
  final Widget  child;
  const _ClienteSheet({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Container(
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            IconButton(icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 18),
          child,
        ]),
      )),
    ]),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6), shape: BoxShape.circle),
          child: const Icon(Icons.inventory_2_outlined,
              size: 48, color: Color(0xFF1A237E))),
      const SizedBox(height: 16),
      const Text('Aún no tienes pedidos', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      const Text('Presiona "Nuevo" para registrar tu primer pedido',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          textAlign: TextAlign.center),
    ]),
  ));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
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

class _CLabel extends StatelessWidget {
  final String text;
  const _CLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: Color(0xFF374151)));
}

InputDecoration _cDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFC62828))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFC62828), width: 2)),
);