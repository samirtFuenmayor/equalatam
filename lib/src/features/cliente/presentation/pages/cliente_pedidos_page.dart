// lib/src/features/cliente/presentation/pages/cliente_pedidos_page.dart
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
// Agrega este import al tope del archivo
import '../../../operations/presentation/widgets/pedido_form_sheet.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS LOCALES
// ═══════════════════════════════════════════════════════════════════════════════

enum _CategoriaPedido {
  FOUR_X_TWO, FOUR_X_FOUR, CARGA_GENERAL, DOCUMENTO;

  String get label => switch (this) {
    _CategoriaPedido.FOUR_X_TWO    => '4x2 (hasta 4.4 lb)',
    _CategoriaPedido.FOUR_X_FOUR   => '4x4 (hasta 8.8 lb)',
    _CategoriaPedido.CARGA_GENERAL => 'Carga General',
    _CategoriaPedido.DOCUMENTO     => 'Documento',
  };

  String get description => switch (this) {
    _CategoriaPedido.FOUR_X_TWO    => 'Libre de impuestos',
    _CategoriaPedido.FOUR_X_FOUR   => 'Hasta \$400 — paga \$20 fijo',
    _CategoriaPedido.CARGA_GENERAL => 'Arancel + IVA 15%',
    _CategoriaPedido.DOCUMENTO     => 'Solo documentos — libre',
  };
}

enum _TipoProducto {
  ELECTRONICO, ROPA, COSMETICO, ALIMENTO, HERRAMIENTA, JUGUETE, LIBRO, DOCUMENTO, OTRO;

  String get label => switch (this) {
    _TipoProducto.ELECTRONICO => 'Electrónico',
    _TipoProducto.ROPA        => 'Ropa / Calzado',
    _TipoProducto.COSMETICO   => 'Cosmético',
    _TipoProducto.ALIMENTO    => 'Alimento / Suplemento',
    _TipoProducto.HERRAMIENTA => 'Herramienta',
    _TipoProducto.JUGUETE     => 'Juguete',
    _TipoProducto.LIBRO       => 'Libro',
    _TipoProducto.DOCUMENTO   => 'Documento',
    _TipoProducto.OTRO        => 'Otro',
  };

  IconData get icon => switch (this) {
    _TipoProducto.ELECTRONICO => Icons.devices_rounded,
    _TipoProducto.ROPA        => Icons.checkroom_rounded,
    _TipoProducto.COSMETICO   => Icons.face_rounded,
    _TipoProducto.ALIMENTO    => Icons.restaurant_rounded,
    _TipoProducto.HERRAMIENTA => Icons.build_rounded,
    _TipoProducto.JUGUETE     => Icons.toys_rounded,
    _TipoProducto.LIBRO       => Icons.menu_book_rounded,
    _TipoProducto.DOCUMENTO   => Icons.description_rounded,
    _TipoProducto.OTRO        => Icons.category_rounded,
  };
}
extension _TipoProductoSubs on _TipoProducto {
  List<String> get subcategorias => switch (this) {
    _TipoProducto.ELECTRONICO => ['LAPTOP','CELULAR','TABLET','SMARTWATCH',
      'AURICULARES','CAMARA','CONSOLA_VIDEOJUEGOS','COMPONENTE_PC','OTRO_ELECTRONICO'],
    _TipoProducto.ROPA => ['ROPA_HOMBRE','ROPA_MUJER','ROPA_NINO',
      'CALZADO','ACCESORIO_MODA','BOLSO_CARTERA','OTRO_TEXTIL'],
    _TipoProducto.COSMETICO => ['PERFUME','CREMA_LOCION','MAQUILLAJE',
      'SUPLEMENTO_BELLEZA','OTRO_COSMETICO'],
    _TipoProducto.ALIMENTO => ['SUPLEMENTO_DEPORTIVO','SNACK_GOLOSINA',
      'VITAMINA_MEDICAMENTO_OTC','OTRO_ALIMENTO'],
    _TipoProducto.HERRAMIENTA => ['HERRAMIENTA_ELECTRICA','HERRAMIENTA_MANUAL',
      'REPUESTO_AUTOMOTRIZ','REPUESTO_INDUSTRIAL','OTRO_REPUESTO'],
    _TipoProducto.JUGUETE => ['JUGUETE_INFANTIL','ARTICULO_BEBE',
      'JUEGO_MESA','FIGURA_COLECCIONABLE','OTRO_JUGUETE'],
    _TipoProducto.LIBRO => ['LIBRO_TECNICO','LIBRO_TEXTO',
      'NOVELA_LITERATURA','REVISTA','OTRO_LIBRO'],
    _TipoProducto.DOCUMENTO => ['DOCUMENTO_LEGAL','DOCUMENTO_ACADEMICO',
      'DOCUMENTO_COMERCIAL','OTRO_DOCUMENTO'],
    _TipoProducto.OTRO => ['ARTICULO_HOGAR','DEPORTE_FITNESS',
      'MASCOTA_VETERINARIA','SIN_CLASIFICAR'],
  };
}
// ═══════════════════════════════════════════════════════════════════════════════
// MODELOS LOCALES
// ═══════════════════════════════════════════════════════════════════════════════

class _PedidoItem {
  final String  id;
  final String  tipoProducto;
  final String  descripcion;
  final String? trackingExterno;
  final String? proveedor;
  final double? peso;
  final double? valorDeclarado;
  final bool    llego;
  final bool    despachado;
  final String? observaciones;

  const _PedidoItem({
    required this.id, required this.tipoProducto, required this.descripcion,
    this.trackingExterno, this.proveedor, this.peso, this.valorDeclarado,
    required this.llego, required this.despachado, this.observaciones,
  });

  factory _PedidoItem.fromJson(Map<String, dynamic> j) => _PedidoItem(
    id:             j['id']?.toString() ?? '',
    tipoProducto:   j['tipoProducto']?.toString() ?? '',
    descripcion:    j['descripcion']?.toString() ?? '',
    trackingExterno:j['trackingExterno']?.toString(),
    proveedor:      j['proveedor']?.toString(),
    peso:           (j['peso'] as num?)?.toDouble(),
    valorDeclarado: (j['valorDeclarado'] as num?)?.toDouble(),
    llego:          j['llego'] as bool? ?? false,
    despachado:     j['despachado'] as bool? ?? false,
    observaciones:  j['observaciones']?.toString(),
  );
}

class _PedidoResumen {
  final String            id;
  final String            numeroPedido;
  final String            tipo;
  final String            descripcion;
  final String            estadoLogistico;
  final String            estadoFinanciero;
  final String?           cotizacionId;
  final double?           totalCotizado;
  final String?           facturaId;
  final String?           numeroFactura;
  final double?           totalFactura;
  final String            fechaRegistro;
  final List<_PedidoItem> items;
  final String?           categoriaPedido;
  final bool              esPorTitular;
  final String?           tipoTarifa;
  final double?           pesoTotal;

  const _PedidoResumen({
    required this.id, required this.numeroPedido, required this.tipo,
    required this.descripcion, required this.estadoLogistico,
    required this.estadoFinanciero, this.cotizacionId, this.totalCotizado,
    this.facturaId, this.numeroFactura, this.totalFactura,
    required this.fechaRegistro, this.items = const [],
    this.categoriaPedido, this.esPorTitular = false,
    this.tipoTarifa, this.pesoTotal,
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
    items: (j['items'] as List<dynamic>?)
        ?.map((i) => _PedidoItem.fromJson(i as Map<String, dynamic>)).toList() ?? [],
    categoriaPedido:  j['categoriaPedido']?.toString(),
    esPorTitular:     j['esPorTitular'] as bool? ?? false,
    tipoTarifa:       j['tipoTarifa']?.toString(),
    pesoTotal:        (j['pesoTotal'] as num?)?.toDouble(),
  );

  bool get tieneRecepcionParcial => estadoLogistico == 'RECEPCION_PARCIAL';
}

class _ItemForm {
  _TipoProducto tipo;
  String subcategoria; // ← AGREGAR
  String descripcion;
  String tracking;
  String proveedor;
  String peso;
  String valorDeclarado;

  _ItemForm({
    this.tipo = _TipoProducto.ELECTRONICO,
    this.subcategoria = '',  // ← AGREGAR
    this.descripcion = '',
    this.tracking = '',
    this.proveedor = 'Amazon',
    this.peso = '',
    this.valorDeclarado = '',
  });

  Map<String, dynamic> toJson() => {
    'tipoProducto':  tipo.name,
    'descripcion':   descripcion,
    if (subcategoria.isNotEmpty) 'subcategoria': subcategoria, // ← AGREGAR
    if (tracking.isNotEmpty)       'trackingExterno': tracking,
    if (proveedor.isNotEmpty)      'proveedor':       proveedor,
    if (peso.isNotEmpty)           'peso':            double.tryParse(peso),
    if (valorDeclarado.isNotEmpty) 'valorDeclarado':  double.tryParse(valorDeclarado),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════

class ClientePedidosPage extends StatefulWidget {
  const ClientePedidosPage({super.key});
  @override State<ClientePedidosPage> createState() => _ClientePedidosPageState();
}

class _ClientePedidosPageState extends State<ClientePedidosPage> {
  List<_PedidoResumen> _pedidos   = [];
  bool                 _loading   = true;
  String?              _error;
  String               _clienteId = '';

  @override void initState() { super.initState(); _load(); }

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
      onRefresh: _load, color: const Color(0xFF1A237E),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _pedidos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _PedidoCard(
          pedido: _pedidos[i],
          onVerTracking:      () => _verTracking(_pedidos[i]),
          onDecisionDespacho: (d) => _decisionDespacho(_pedidos[i], d),
        ),
      ),
    );
  }

  void _verTracking(_PedidoResumen p) => showModalBottomSheet(
    context: context, isScrollControlled: true,
    useSafeArea: true, backgroundColor: Colors.transparent,
    builder: (_) => _TrackingSheet(numeroPedido: p.numeroPedido),
  );

  void _openNuevoPedido() => showModalBottomSheet(
    context: context, isScrollControlled: true,
    useSafeArea: true, backgroundColor: Colors.transparent,
    builder: (_) => PedidoFormSheet(
      clienteId: _clienteId,
      onCreado:  _load,
    ),
  );

  Future<void> _decisionDespacho(_PedidoResumen p, bool despacharParcial) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/pedidos/${p.id}/decision-despacho'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'despacharParcial': despacharParcial}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(despacharParcial
              ? '✅ Aprobado. Se despachará lo que llegó.'
              : '⏳ Pedido en espera de items faltantes.'),
          backgroundColor: despacharParcial ? const Color(0xFF2E7D32) : const Color(0xFF1A237E),
          behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {}
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int total; final VoidCallback onRefresh, onNuevo;
  const _Header({required this.total, required this.onRefresh, required this.onNuevo});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mis Pedidos', style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        Text('$total pedido${total == 1 ? '' : 's'} registrado${total == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      ])),
      IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)), onPressed: onRefresh),
      const SizedBox(width: 6),
      SizedBox(height: 42, child: ElevatedButton.icon(
        onPressed: onNuevo,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Nuevo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      )),
    ]),
  );
}

// ─── CARD DE PEDIDO ───────────────────────────────────────────────────────────
class _PedidoCard extends StatefulWidget {
  final _PedidoResumen       pedido;
  final VoidCallback          onVerTracking;
  final void Function(bool)   onDecisionDespacho;
  const _PedidoCard({required this.pedido, required this.onVerTracking, required this.onDecisionDespacho});
  @override State<_PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<_PedidoCard> {
  bool _showItems = false;

  String _labelCategoria(String c) => switch (c) {
    'FOUR_X_TWO'    => '4x2', 'FOUR_X_FOUR' => '4x4',
    'CARGA_GENERAL' => 'Carga General', 'DOCUMENTO' => 'Documento', _ => c,
  };

  String _labelTarifa(String t) => switch (t) {
    'FAMILIAR' => '👨‍👩‍👧 Familiar', 'AMIGO' => '👥 Amigo', _ => '👤 Individual',
  };

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: p.tieneRecepcionParcial ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
              width: p.tieneRecepcionParcial ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Alerta recepción parcial
        if (p.tieneRecepcionParcial)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFFFFF3E0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('Recepción parcial — algunos items no llegaron',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100)))),
            ]),
          ),

        // Cabecera
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1A237E), size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.numeroPedido, style: const TextStyle(fontWeight: FontWeight.w800,
                  fontSize: 14, fontFamily: 'monospace', color: Color(0xFF1A1A2E))),
              Text(p.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            _TipoBadge(p.tipo),
          ]),
        ),

        // Chips de info
        if (p.categoriaPedido != null || p.pesoTotal != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(spacing: 8, runSpacing: 6, children: [
              if (p.categoriaPedido != null)
                _InfoChip(Icons.category_outlined, _labelCategoria(p.categoriaPedido!)),
              if (p.pesoTotal != null)
                _InfoChip(Icons.scale_outlined, '${p.pesoTotal!.toStringAsFixed(2)} lb'),
              if (p.tipoTarifa != null)
                _InfoChip(Icons.people_outline, _labelTarifa(p.tipoTarifa!)),
            ]),
          ),

        // Estados
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Logístico', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 4),
              _LogisticoBadge(p.estadoLogistico),
            ])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pago', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 4),
              _FinancieroBadge(p.estadoFinanciero),
            ])),
          ]),
        ),

        // Monto
        if (p.totalCotizado != null || p.totalFactura != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Row(children: [
                const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF1A237E)),
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
          ),

        // Items
        if (p.items.isNotEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _showItems = !_showItems),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                const Icon(Icons.list_alt_rounded, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text('${p.items.length} producto${p.items.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(_showItems ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: const Color(0xFF9CA3AF)),
              ]),
            ),
          ),
          if (_showItems)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(children: p.items.map((i) => _ItemTile(item: i)).toList()),
            ),
        ],

        // Decisión despacho parcial
        if (p.tieneRecepcionParcial)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('¿Qué deseas hacer?', style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => widget.onDecisionDespacho(false),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A237E),
                      side: const BorderSide(color: Color(0xFF1A237E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                  icon: const Icon(Icons.hourglass_bottom_rounded, size: 16),
                  label: const Text('Esperar', style: TextStyle(fontSize: 12)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => widget.onDecisionDespacho(true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                  icon: const Icon(Icons.local_shipping_outlined, size: 16),
                  label: const Text('Despachar ahora', style: TextStyle(fontSize: 12)),
                )),
              ]),
            ]),
          ),

        // Tracking
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: widget.onVerTracking,
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A237E),
                side: const BorderSide(color: Color(0xFFC5CAE9)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10)),
            icon: const Icon(Icons.track_changes_outlined, size: 16),
            label: const Text('Ver tracking', style: TextStyle(fontSize: 13)),
          )),
        ),
      ]),
    );
  }
}

// ─── ITEM TILE ────────────────────────────────────────────────────────────────
class _ItemTile extends StatelessWidget {
  final _PedidoItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: item.llego ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.llego ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A))),
    child: Row(children: [
      Container(width: 32, height: 32,
          decoration: BoxDecoration(
              color: (item.llego ? const Color(0xFF2E7D32) : const Color(0xFFF59E0B)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(item.llego ? Icons.check_circle_outline : Icons.hourglass_empty_rounded,
              size: 16, color: item.llego ? const Color(0xFF2E7D32) : const Color(0xFFF59E0B))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.descripcion, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        if (item.trackingExterno != null)
          Text(item.trackingExterno!, style: const TextStyle(
              fontSize: 10, color: Color(0xFF6B7280), fontFamily: 'monospace')),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (item.peso != null)
          Text('${item.peso!.toStringAsFixed(2)} lb',
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        Text(item.llego ? 'Llegó' : 'Pendiente',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: item.llego ? const Color(0xFF2E7D32) : const Color(0xFFF59E0B))),
      ]),
    ]),
  );
}

// ─── SHEET TRACKING ───────────────────────────────────────────────────────────
class _TrackingSheet extends StatefulWidget {
  final String numeroPedido;
  const _TrackingSheet({required this.numeroPedido});
  @override State<_TrackingSheet> createState() => _TrackingSheetState();
}

class _TrackingSheetState extends State<_TrackingSheet> {
  List<dynamic> _eventos = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

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
        setState(() { _eventos = data['eventos'] ?? []; _loading = false; });
      } else { setState(() => _loading = false); }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => _ClienteSheet(
    title: 'Tracking', subtitle: widget.numeroPedido,
    child: _loading
        ? const Center(child: Padding(padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: Color(0xFF1A237E))))
        : _eventos.isEmpty
        ? const Center(child: Padding(padding: EdgeInsets.all(32),
        child: Text('Sin eventos de tracking',
            style: TextStyle(color: Color(0xFF9CA3AF)))))
        : Column(children: _eventos.asMap().entries.map((e) {
      final ev = e.value; final isLast = e.key == _eventos.length - 1;
      return _TrackingItem(estado: ev['estado'] ?? '',
          descripcion: ev['descripcion'] ?? '', fecha: ev['fecha'] ?? '', isLast: isLast);
    }).toList()),
  );
}

class _TrackingItem extends StatelessWidget {
  final String estado, descripcion, fecha; final bool isLast;
  const _TrackingItem({required this.estado, required this.descripcion,
    required this.fecha, required this.isLast});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(children: [
      Container(width: 20, height: 20,
          decoration: const BoxDecoration(color: Color(0xFF1A237E), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 12, color: Colors.white)),
      if (!isLast) Container(width: 2, height: 40, color: const Color(0xFFE5E7EB)),
    ]),
    const SizedBox(width: 12),
    Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(estado, style: const TextStyle(fontWeight: FontWeight.w700,
              fontSize: 13, color: Color(0xFF1A1A2E))),
          Text(descripcion, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Text(fecha, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ]))),
  ]);
}

// ─── ITEM FORM CARD ───────────────────────────────────────────────────────────
class _ItemFormCard extends StatefulWidget {
  final int index; final _ItemForm item;
  final VoidCallback onChanged; final VoidCallback? onRemove;
  const _ItemFormCard({required this.index, required this.item,
    required this.onChanged, this.onRemove});
  @override State<_ItemFormCard> createState() => _ItemFormCardState();
}

class _ItemFormCardState extends State<_ItemFormCard> {
  late final TextEditingController _descCtrl, _trackCtrl, _provCtrl, _pesoCtrl, _valorCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl  = TextEditingController(text: widget.item.descripcion);
    _trackCtrl = TextEditingController(text: widget.item.tracking);
    _provCtrl  = TextEditingController(text: widget.item.proveedor);
    _pesoCtrl  = TextEditingController(text: widget.item.peso);
    _valorCtrl = TextEditingController(text: widget.item.valorDeclarado);
  }

  @override
  void dispose() {
    for (final c in [_descCtrl, _trackCtrl, _provCtrl, _pesoCtrl, _valorCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Row(children: [
          Container(width: 24, height: 24,
              decoration: BoxDecoration(color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text('${widget.index + 1}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 8),
          const Text('Producto', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
          const Spacer(),
          if (widget.onRemove != null)
            IconButton(icon: const Icon(Icons.remove_circle_outline_rounded,
                color: Color(0xFFC62828), size: 20),
                onPressed: widget.onRemove, padding: EdgeInsets.zero,
                constraints: const BoxConstraints()),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: DropdownButtonHideUnderline(child: DropdownButton<_TipoProducto>(
              value: widget.item.tipo, isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              items: _TipoProducto.values.map((t) => DropdownMenuItem(value: t,
                  child: Row(children: [
                    Icon(t.icon, size: 16, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(t.label, style: const TextStyle(fontSize: 13)),
                  ]))).toList(),
              onChanged: (v) { widget.item.tipo = v!; widget.onChanged(); },
            )),
          ),
          // Después del dropdown de tipo de producto
          const SizedBox(height: 8),
          if (widget.item.tipo.subcategorias.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: widget.item.subcategoria.isNotEmpty ? widget.item.subcategoria : null,
                hint: const Text('Subcategoría (opcional)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                items: widget.item.tipo.subcategorias.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s.replaceAll('_', ' ').toLowerCase().split(' ')
                          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
                          .join(' '),
                      style: const TextStyle(fontSize: 13),
                    ))).toList(),
                onChanged: (v) { widget.item.subcategoria = v ?? ''; widget.onChanged(); },
              )),
            ),
          const SizedBox(height: 8),
          // Descripción
          TextFormField(controller: _descCtrl,
              decoration: _cDeco('Descripción del producto *'),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) { widget.item.descripcion = v; widget.onChanged(); }),
          const SizedBox(height: 8),
          // Tracking y proveedor
          Row(children: [
            Expanded(child: TextFormField(controller: _trackCtrl,
                decoration: _cDeco('Tracking Amazon'),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) { widget.item.tracking = v; widget.onChanged(); })),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _provCtrl,
                decoration: _cDeco('Proveedor'),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) { widget.item.proveedor = v; widget.onChanged(); })),
          ]),
          const SizedBox(height: 8),
          // Peso y valor
          Row(children: [
            Expanded(child: TextFormField(controller: _pesoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _cDeco('Peso (lb)'), style: const TextStyle(fontSize: 13),
                onChanged: (v) { widget.item.peso = v; widget.onChanged(); })),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _valorCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _cDeco('Valor USD'), style: const TextStyle(fontSize: 13),
                onChanged: (v) { widget.item.valorDeclarado = v; widget.onChanged(); })),
          ]),
        ]),
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: const Color(0xFF6B7280)), const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w600, color: Color(0xFF374151))),
    ]),
  );
}

class _TipoBadge extends StatelessWidget {
  final String tipo; const _TipoBadge(this.tipo);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: tipo == 'IMPORTACION' ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC),
          borderRadius: BorderRadius.circular(8)),
      child: Text(tipo == 'IMPORTACION' ? 'Importación' : 'Exportación',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: tipo == 'IMPORTACION' ? const Color(0xFF1565C0) : const Color(0xFFC62828))));
}

class _LogisticoBadge extends StatelessWidget {
  final String estado; const _LogisticoBadge(this.estado);
  Color get _color => switch (estado) {
    'REGISTRADO'             => const Color(0xFF1A237E),
    'RECIBIDO_EN_SEDE'       => const Color(0xFF7B1FA2),
    'EN_TRANSITO'            => const Color(0xFFE65100),
    'EN_ADUANA'              => const Color(0xFFF57F17),
    'RECEPCION_PARCIAL'      => const Color(0xFFE65100),
    'ESPERANDO_ITEMS'        => const Color(0xFF0277BD),
    'DISPONIBLE_EN_SUCURSAL' => const Color(0xFF2E7D32),
    'ENTREGADO'              => const Color(0xFF388E3C),
    _                        => const Color(0xFF6B7280),
  };
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(estado.replaceAll('_', ' '),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _color)),
      ]));
}

class _FinancieroBadge extends StatelessWidget {
  final String estado; const _FinancieroBadge(this.estado);
  (Color, String) get _info => switch (estado) {
    'SIN_COTIZAR'         => (const Color(0xFF9CA3AF), 'Sin cotizar'),
    'COTIZADO'            => (const Color(0xFFF59E0B), 'Cotizado'),
    'PENDIENTE_PAGO'      => (const Color(0xFFE65100), 'Pendiente pago'),
    'LISTO_PARA_FACTURAR' => (const Color(0xFF7B1FA2), 'Listo para facturar'),
    'EMITIDA'             => (const Color(0xFF1A237E), 'Facturado'),
    'PAGADA'              => (const Color(0xFF2E7D32), 'Pagado'),
    'VENCIDA'             => (const Color(0xFFC62828), 'Vencida'),
    _                     => (const Color(0xFF6B7280), estado.replaceAll('_', ' ')),
  };
  @override
  Widget build(BuildContext context) {
    final (color, label) = _info;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ]));
  }
}

class _SucDropdown extends StatelessWidget {
  final String hint; final String? value, excluir;
  final List<Map<String, String>> sucursales; final void Function(String?) onChanged;
  const _SucDropdown({required this.hint, required this.value, required this.sucursales,
    required this.onChanged, this.excluir});
  @override
  Widget build(BuildContext context) {
    final items = sucursales.where((s) => s['id'] != excluir).toList();
    final cur   = (value != null && items.any((s) => s['id'] == value)) ? value : null;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: cur,
            hint: Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: items.map((s) => DropdownMenuItem(value: s['id'],
                child: Text('${s['nombre']} (${s['pais']})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChanged)));
  }
}

class _ClienteSheet extends StatelessWidget {
  final String title; final String? subtitle; final Widget child;
  const _ClienteSheet({required this.title, this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 12),
      Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
      Flexible(child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
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
          decoration: const BoxDecoration(color: Color(0xFFE8EAF6), shape: BoxShape.circle),
          child: const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF1A237E))),
      const SizedBox(height: 16),
      const Text('Aún no tienes pedidos', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      const Text('Presiona "Nuevo" para registrar tu primer pedido',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
    ]),
  ));
}

class _ErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFC62828))),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reintentar')),
    ]),
  ));
}

class _CLabel extends StatelessWidget {
  final String text; const _CLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
      fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)));
}

InputDecoration _cDeco(String hint) => InputDecoration(
  hintText: hint, hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
  border:             OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
  errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC62828))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC62828), width: 2)),
);