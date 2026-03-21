// lib/src/features/cliente/presentation/pages/cliente_cotizaciones_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

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
  final String? observaciones;
  final String  creadoEn;

  const _Cotizacion({
    required this.id, required this.numeroCotizacion,
    required this.estado, required this.total,
    required this.subtotal, required this.montoIva,
    this.pesoFacturable, this.pesoReal,
    required this.validaHasta, this.pedidoNumero,
    this.observaciones, required this.creadoEn,
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
    observaciones:    j['observaciones'],
    creadoEn:         j['creadoEn'] ?? '',
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ClienteCotizacionesPage extends StatefulWidget {
  const ClienteCotizacionesPage({super.key});
  @override
  State<ClienteCotizacionesPage> createState() => _ClienteCotizacionesPageState();
}

class _ClienteCotizacionesPageState extends State<ClienteCotizacionesPage> {
  List<_Cotizacion> _cotizaciones = [];
  bool   _loading   = true;
  String? _error;

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

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/financiero/cotizaciones/cliente/$clienteId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _cotizaciones = list.map((e) => _Cotizacion.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Error al cargar cotizaciones'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Sin conexión al servidor'; _loading = false; });
    }
  }

  Future<void> _aprobar(_Cotizacion c) async {
    final formaPago  = await _seleccionarPago(c);
    if (formaPago == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res   = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/financiero/cotizaciones/${c.id}/aprobar-cliente'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(formaPago),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _snack('✅ Cotización aprobada. El admin procesará tu pedido.', ok: true);
        _load();
      } else {
        String msg = 'Error al aprobar';
        try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
        _snack(msg, ok: false);
      }
    } catch (_) {
      _snack('Sin conexión al servidor', ok: false);
    }
  }

  Future<Map<String, dynamic>?> _seleccionarPago(_Cotizacion c) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AprobarSheet(cotizacion: c),
    );
  }

  Future<void> _cancelar(_Cotizacion c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cancelar cotización?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Cotización ${c.numeroCotizacion} por \$${c.total.toStringAsFixed(2)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('No', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Cancelar cotización'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res   = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/financiero/cotizaciones/${c.id}/cancelar'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _snack('Cotización cancelada', ok: true);
        _load();
      } else {
        _snack('Error al cancelar', ok: false);
      }
    } catch (_) {
      _snack('Sin conexión', ok: false);
    }
  }

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
        _CotHeader(total: _cotizaciones.length, onRefresh: _load),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _body() {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    if (_error != null) return _CotErrorView(message: _error!, onRetry: _load);
    if (_cotizaciones.isEmpty) return const _CotEmptyView();
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A237E),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _cotizaciones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _CotizacionCard(
          c:          _cotizaciones[i],
          onAprobar:  () => _aprobar(_cotizaciones[i]),
          onCancelar: () => _cancelar(_cotizaciones[i]),
        ),
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _CotHeader extends StatelessWidget {
  final int total;
  final VoidCallback onRefresh;
  const _CotHeader({required this.total, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mis Cotizaciones', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        Text('$total cotización${total == 1 ? '' : 'es'}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      ])),
      IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
          onPressed: onRefresh),
    ]),
  );
}

// ─── CARD ─────────────────────────────────────────────────────────────────────
class _CotizacionCard extends StatelessWidget {
  final _Cotizacion  c;
  final VoidCallback onAprobar;
  final VoidCallback onCancelar;
  const _CotizacionCard({required this.c, required this.onAprobar, required this.onCancelar});

  (Color, String) get _estadoInfo => switch (c.estado) {
    'PENDIENTE'  => (const Color(0xFFF59E0B), 'Pendiente'),
    'APROBADA'   => (const Color(0xFF2E7D32), 'Aprobada'),
    'FACTURADA'  => (const Color(0xFF1A237E), 'Facturada'),
    'VENCIDA'    => (const Color(0xFF9CA3AF), 'Vencida'),
    'CANCELADA'  => (const Color(0xFFC62828), 'Cancelada'),
    _            => (const Color(0xFF6B7280), c.estado),
  };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _estadoInfo;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: c.estado == 'PENDIENTE'
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
                child: Icon(Icons.calculate_outlined, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.numeroCotizacion, style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  fontFamily: 'monospace', color: Color(0xFF1A1A2E))),
              if (c.pedidoNumero != null)
                Text('Pedido: ${c.pedidoNumero}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ])),
            // Badge estado
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(children: [
            _MontoFila('Subtotal', c.subtotal),
            const SizedBox(height: 6),
            _MontoFila('IVA 15%', c.montoIva),
            const Divider(height: 14),
            _MontoFila('TOTAL', c.total, bold: true, color: const Color(0xFF1A237E)),
            if (c.pesoFacturable != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.scale_outlined, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text('Peso facturable: ${c.pesoFacturable!.toStringAsFixed(2)} lb',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ]),
            ],
          ]),
        ),
        // Válida hasta
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Text('Válida hasta: ${c.validaHasta}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ]),
        ),
        // Acciones (solo si PENDIENTE)
        if (c.estado == 'PENDIENTE')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: onCancelar,
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFC62828)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Cancelar', style: TextStyle(fontSize: 13)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: onAprobar,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Aprobar', style: TextStyle(fontSize: 13)),
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
        fontSize: bold ? 16 : 13,
        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        color: color)),
  ]);
}

// ─── SHEET APROBAR ────────────────────────────────────────────────────────────
class _AprobarSheet extends StatefulWidget {
  final _Cotizacion cotizacion;
  const _AprobarSheet({required this.cotizacion});
  @override State<_AprobarSheet> createState() => _AprobarSheetState();
}

class _AprobarSheetState extends State<_AprobarSheet> {
  String _formaPago = 'TRANSFERENCIA';
  final  _refCtrl   = TextEditingController();
  final  _obsCtrl   = TextEditingController();

  @override
  void dispose() { _refCtrl.dispose(); _obsCtrl.dispose(); super.dispose(); }

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
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Expanded(child: Text('Aprobar cotización', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))),
              IconButton(icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 8),
            // Resumen
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA5D6A7))),
              child: Row(children: [
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.numeroCotizacion, style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  Text('Total a pagar: \$${c.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32))),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Método de pago', style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
            const SizedBox(height: 10),
            ...['TRANSFERENCIA', 'DEPOSITO', 'EFECTIVO'].map((fp) {
              final (icon, label, desc) = switch (fp) {
                'TRANSFERENCIA' => (Icons.swap_horiz_rounded, 'Transferencia bancaria',
                'Envía el comprobante por WhatsApp'),
                'DEPOSITO'      => (Icons.account_balance_outlined, 'Depósito bancario',
                'Depósito en cuenta de Equalatam'),
                _               => (Icons.store_outlined, 'Efectivo en sucursal',
                'Paga en nuestra sucursal'),
              };
              final sel = _formaPago == fp;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _formaPago = fp),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: sel ? const Color(0xFFE8EAF6) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB),
                            width: sel ? 2 : 1)),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: sel ? const Color(0xFF1A237E) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(icon,
                              color: sel ? Colors.white : const Color(0xFF6B7280),
                              size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(label, style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13,
                            color: sel ? const Color(0xFF1A237E) : const Color(0xFF374151))),
                        Text(desc, style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                      ])),
                      if (sel) const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF1A237E), size: 20),
                    ]),
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            const Text('Referencia / comprobante (opcional)', style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextFormField(controller: _refCtrl,
                decoration: _cDeco2('Ej: TRF-2026-001234')),
            const SizedBox(height: 14),
            const Text('Observaciones (opcional)', style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextFormField(controller: _obsCtrl, maxLines: 2,
                decoration: _cDeco2('Ej: Transferencia realizada el 21/03/2026')),
            const SizedBox(height: 24),
            SizedBox(height: 50, child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, {
                'formaPago':       _formaPago,
                'referenciaPago':  _refCtrl.text.trim(),
                'observaciones':   _obsCtrl.text.trim(),
              }),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Confirmar aprobación',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )),
          ]),
        )),
      ]),
    );
  }
}

// ─── VISTAS AUXILIARES ────────────────────────────────────────────────────────
class _CotEmptyView extends StatelessWidget {
  const _CotEmptyView();
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
      const Text('No tienes cotizaciones', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      const Text('Crea un pedido con cotización para verla aquí',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reintentar')),
    ]),
  ));
}

InputDecoration _cDeco2(String hint) => InputDecoration(
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
);