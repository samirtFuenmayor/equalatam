// lib/src/features/pedidos/presentation/pages/pedidos_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../../../core/constants/api_constants.dart';
import '../../../network/presentation/pages/despachos_page.dart';
import '../../presentation/widgets/pedido_form_sheet.dart';
import '../domain/model/pedido_model.dart';
import '../bloc/pedido_bloc.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../../cliente/presentation/pages/cliente_pedidos_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});
  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage>
    with SingleTickerProviderStateMixin {

  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [
        // ── Tab bar principal ──────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: const Color(0xFF1A237E),
            unselectedLabelColor: const Color(0xFF9CA3AF),
            indicatorColor: const Color(0xFF1A237E),
            indicatorWeight: 3,
            tabs: const [
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inventory_2_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Pedidos', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ),
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.local_shipping_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Despachos', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
        ),
        // ── Contenido ─────────────────────────────────────────────────────
        Expanded(child: TabBarView(
          controller: _tabCtrl,
          children: [
            BlocProvider(
              create: (_) => di.sl<PedidoBloc>()..add(PedidoLoadAll()),
              child: const _PedidosView(),
            ),
            const DespachosPage(),
          ],
        )),
      ]),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
class _PedidosView extends StatefulWidget {
  const _PedidosView();
  @override
  State<_PedidosView> createState() => _PedidosViewState();
}

class _PedidosViewState extends State<_PedidosView>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String         _q           = '';
  EstadoPedido?  _filtroEstado;
  bool           _buscando    = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  // ── Filtro client-side (cuando NO se está usando el buscador del backend) ─
  List<PedidoModel> _filter(List<PedidoModel> src) {
    if (_buscando) return src; // el backend ya filtró
    return src.where((p) {
      final q   = _q.toLowerCase();
      final okQ = _q.isEmpty ||
          p.numeroPedido.toLowerCase().contains(q) ||
          p.clienteNombreCompleto.toLowerCase().contains(q) ||
          p.clienteCasillero.toLowerCase().contains(q) ||
          (p.trackingExterno?.toLowerCase().contains(q) ?? false) ||
          (p.proveedor?.toLowerCase().contains(q) ?? false) ||
          p.descripcion.toLowerCase().contains(q);
      final okE = _filtroEstado == null || p.estado == _filtroEstado;
      return okQ && okE;
    }).toList();
  }
  void _openVerificarPago(BuildContext ctx, PedidoModel p) =>
      _showSheet(ctx,
          child: BlocProvider.value(
              value: ctx.read<PedidoBloc>(),
              child: _VerificarPagoSheet(
                pedido: p,
                onVerificado: () {
                  ctx.read<PedidoBloc>().add(PedidoLoadAll());
                  _snack(ctx, 'Pago procesado correctamente', ok: true);
                },
              )));

  void _openConfirmarYFacturar(BuildContext ctx, PedidoModel p) {
    _showSheet(ctx,
        child: _RecepcionItemsSheet(
          pedido: p,
          onConfirmado: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('eq_token') ?? '';
              final res   = await http.post(
                Uri.parse('${ApiConstants.baseUrl}/api/pedidos/${p.id}/confirmar-pago-y-facturar'),
                headers: {'Authorization': 'Bearer $token'},
              );
              if (!ctx.mounted) return;
              if (res.statusCode == 200) {
                ctx.read<PedidoBloc>().add(PedidoLoadAll());
                _snack(ctx, 'Factura emitida y enviada al cliente', ok: true);
              } else {
                ctx.read<PedidoBloc>().add(PedidoLoadAll());
                _snack(ctx,
                    'Items faltantes detectados. Se notificó al cliente.',
                    ok: false);
              }
            } catch (_) {
              if (ctx.mounted) _snack(ctx, 'Error al procesar', ok: false);
            }
          },
        ));
  }

  void _doSearch(BuildContext ctx, String v) {
    setState(() { _q = v; _buscando = v.trim().length >= 3; });
    if (_buscando) {
      ctx.read<PedidoBloc>().add(PedidoBuscar(v));
    } else if (v.isEmpty) {
      ctx.read<PedidoBloc>().add(PedidoLoadAll());
    }
  }

  void _openBuscarCliente(BuildContext ctx) => _showSheet(ctx,
      child: BlocProvider.value(
          value: ctx.read<PedidoBloc>(),
          child: const _BuscarClienteSheet()));

  // ── Sheets ────────────────────────────────────────────────────────────────
  void _openComprobante(BuildContext ctx, PedidoModel p) =>
      _showSheet(ctx,
          child: BlocProvider.value(
              value: ctx.read<PedidoBloc>(),
              child: _ComprobanteSheet(
                pedido: p,
                onSubido: () => _snack(ctx,
                    'Comprobante enviado, pendiente verificación',
                    ok: true),
              )));

  void _openCreate(BuildContext ctx) => _showSheet(ctx,
      child: PedidoFormSheet(
        clienteId: '', // el admin selecciona cliente en el form
        onCreado:  () => ctx.read<PedidoBloc>().add(PedidoLoadAll()),
      ));
  void _openEdit(BuildContext ctx, PedidoModel p) => _showSheet(ctx,
      child: BlocProvider.value(
          value: ctx.read<PedidoBloc>(),
          child: _PedidoFormSheet(pedido: p)));

  void _openDetail(BuildContext ctx, PedidoModel p) => _showSheet(ctx,
      child: BlocProvider.value(
          value: ctx.read<PedidoBloc>(),
          child: _PedidoDetailSheet(
            pedido:               p,
            onEdit:               () { Navigator.pop(ctx); _openEdit(ctx, p); },
            onEstado:             () { Navigator.pop(ctx); _openEstado(ctx, p); },
            onRecepcion:          () { Navigator.pop(ctx); _openRecepcion(ctx, p); },
            onComprobante:        () { Navigator.pop(ctx); _openComprobante(ctx, p); },
            onVerificarPago:      () { Navigator.pop(ctx); _openVerificarPago(ctx, p); },
            onConfirmarYFacturar: () { Navigator.pop(ctx); _openConfirmarYFacturar(ctx, p); }, // ← AGREGAR
          )));

  void _openRecepcion(BuildContext ctx, PedidoModel p) => _showSheet(ctx,
      child: _RecepcionItemsSheet(
        pedido: p,
        onConfirmado: () {
          ctx.read<PedidoBloc>().add(PedidoLoadAll());
          _snack(ctx, 'Recepción confirmada correctamente', ok: true);
        },
      ));

  void _openEstado(BuildContext ctx, PedidoModel p) => _showSheet(ctx,
      child: BlocProvider.value(
          value: ctx.read<PedidoBloc>(),
          child: _CambioEstadoSheet(pedido: p)));

  void _showSheet(BuildContext ctx, {required Widget child}) =>
      showModalBottomSheet(
          context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => child);

  void _snack(BuildContext ctx, String msg, {required bool ok}) {
    ScaffoldMessenger.of(ctx)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: ok ? 3 : 5),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return BlocConsumer<PedidoBloc, PedidoState>(
      listener: (ctx, state) {
        if (state is PedidoLoaded && state.message != null)
          _snack(ctx, state.message!, ok: true);
        if (state is PedidoError) _snack(ctx, state.message, ok: false);
      },
      builder: (ctx, state) {
        final all = switch (state) {
          PedidoLoaded s => s.pedidos,
          PedidoError s  => s.pedidos,
          _              => <PedidoModel>[],
        };
        final conteos = switch (state) {
          PedidoLoaded s => s.conteos,
          PedidoError s  => s.conteos,
          _              => <String, int>{},
        };
        final filtered = _filter(all);
        final loading  = state is PedidoLoading;
        final errOnly  = state is PedidoError && all.isEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            // Header
            _PedHeader(
              total: all.length,
              onAdd:     () => _openCreate(ctx),
              onRefresh: () => ctx.read<PedidoBloc>().add(PedidoLoadAll()),
              onPresencial: () => _openBuscarCliente(ctx),
            ),
            // Dashboard mini
            if (conteos.isNotEmpty) _DashboardRow(conteos: conteos),
            // Filtros
            _PedFilterBar(
              searchCtrl:   _searchCtrl,
              filtroEstado: _filtroEstado,
              onSearch:     (v) => _doSearch(ctx, v),
              onEstado:     (e) => setState(() {
                _filtroEstado = e;
                _buscando = false;
              }),
            ),
            // Cuerpo
            Expanded(child: _body(
                ctx, state, filtered, loading, errOnly, isDesktop)),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext ctx, PedidoState state,
      List<PedidoModel> filtered, bool loading,
      bool errOnly, bool isDesktop) {
    if (loading) return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    if (errOnly) return _PedErrorView(
        message: (state as PedidoError).message,
        onRetry: () => ctx.read<PedidoBloc>().add(PedidoLoadAll()));
    if (filtered.isEmpty) return _PedEmptyView(
        hasFilter: _q.isNotEmpty || _filtroEstado != null);
    return isDesktop
        ? _PedidosTable(
        pedidos: filtered,
        onDetail: (p) => _openDetail(ctx, p),
        onEdit:   (p) => _openEdit(ctx, p),
        onEstado: (p) => _openEstado(ctx, p))
        : _PedidosCards(
        pedidos: filtered,
        onDetail: (p) => _openDetail(ctx, p),
        onEdit:   (p) => _openEdit(ctx, p),
        onEstado: (p) => _openEstado(ctx, p));
  }
}


// ─── HEADER ───────────────────────────────────────────────────────────────────
class _PedHeader extends StatelessWidget {
  final int total;
  final VoidCallback onAdd, onRefresh;
  final VoidCallback?  onPresencial;

  const _PedHeader({
    required this.total,
    required this.onAdd,
    required this.onRefresh,
    this.onPresencial,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Gestión de Pedidos', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E))),
          Text('$total pedido${total == 1 ? '' : 's'} registrado${total == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ])),
        IconButton(icon: const Icon(Icons.refresh_rounded,
            color: Color(0xFF6B7280)),
            onPressed: onRefresh, tooltip: 'Actualizar'),
        const SizedBox(width: 6),
        if (onPresencial != null) ...[
          SizedBox(height: 42, child: OutlinedButton.icon(
              onPressed: onPresencial,
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 14 : 10)),
              icon: const Icon(Icons.storefront_outlined, size: 16),
              label: Text(isWide ? 'En sucursal' : '',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 8),
        ],
        SizedBox(height: 42, child: ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12)),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(isWide ? 'Nuevo pedido' : 'Nuevo',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)))),
      ]),
    );
  }
}

// ─── DASHBOARD MINI ───────────────────────────────────────────────────────────
class _DashboardRow extends StatelessWidget {
  final Map<String, int> conteos;
  const _DashboardRow({required this.conteos});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Registrados', 'REGISTRADO', const Color(0xFF1A237E)),
      ('En sede', 'RECIBIDO_EN_SEDE', const Color(0xFF7B1FA2)),
      ('En tránsito', 'EN_TRANSITO', const Color(0xFFE65100)),
      ('En aduana', 'EN_ADUANA', const Color(0xFFF57F17)),
      ('Disponibles', 'DISPONIBLE_EN_SUCURSAL', const Color(0xFF00695C)),
      ('Entregados', 'ENTREGADO', const Color(0xFF2E7D32)),
    ];

    return SizedBox(
      height: 82, // ⭐ aumentamos un poco
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (label, key, color) = items[i];
          final count = conteos[key] ?? 0;

          return Container(
            width: 130,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // ⭐ CLAVE
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
// ─── FILTROS ──────────────────────────────────────────────────────────────────
class _PedFilterBar extends StatelessWidget {
  final TextEditingController  searchCtrl;
  final EstadoPedido?          filtroEstado;
  final void Function(String)  onSearch;
  final void Function(EstadoPedido?) onEstado;
  const _PedFilterBar({required this.searchCtrl, required this.filtroEstado,
    required this.onSearch, required this.onEstado});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final search = _PedSearchField(
        ctrl: searchCtrl,
        hint: 'Buscar por número, cliente, casillero, tracking...',
        onChanged: onSearch);
    final drop = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EstadoPedido?>(
          value: filtroEstado,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280)),
          items: [
            const DropdownMenuItem(value: null,
                child: Text('Todos los estados',
                    style: TextStyle(fontSize: 13))),
            ...EstadoPedido.values.map((e) => DropdownMenuItem(
                value: e,
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(
                      color: _estadoColor(e), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(e.label, style: const TextStyle(fontSize: 13)),
                ]))),
          ],
          onChanged: onEstado,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: isWide
          ? Row(children: [Expanded(child: search),
        const SizedBox(width: 10), drop])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [search, const SizedBox(height: 10), drop]),
    );
  }

  Color _estadoColor(EstadoPedido e) => switch (e) {
    EstadoPedido.REGISTRADO             => const Color(0xFF1A237E),
    EstadoPedido.RECIBIDO_EN_SEDE       => const Color(0xFF7B1FA2),
    EstadoPedido.EN_CONSOLIDACION       => const Color(0xFF6D4C41),
    EstadoPedido.EN_TRANSITO            => const Color(0xFFE65100),
    EstadoPedido.EN_ADUANA              => const Color(0xFFF57F17),
    EstadoPedido.RETENIDO_ADUANA        => const Color(0xFFB71C1C),
    EstadoPedido.LIBERADO_ADUANA        => const Color(0xFF00838F),
    EstadoPedido.RECIBIDO_EN_MATRIZ     => const Color(0xFF00695C),
    EstadoPedido.EN_DISTRIBUCION        => const Color(0xFF1565C0),
    EstadoPedido.DISPONIBLE_EN_SUCURSAL => const Color(0xFF2E7D32),
    EstadoPedido.ENTREGADO              => const Color(0xFF388E3C),
    EstadoPedido.DEVUELTO               => const Color(0xFF546E7A),
    EstadoPedido.EXTRAVIADO             => const Color(0xFFC62828),
    EstadoPedido.RECEPCION_PARCIAL      => const Color(0xFFF59E0B), // ← NUEVO
    EstadoPedido.ESPERANDO_ITEMS        => const Color(0xFF0288D1),
  };
}

// ─── TABLA DESKTOP ────────────────────────────────────────────────────────────
class _PedidosTable extends StatelessWidget {
  final List<PedidoModel>          pedidos;
  final void Function(PedidoModel) onDetail, onEdit, onEstado;
  const _PedidosTable({required this.pedidos, required this.onDetail,
    required this.onEdit, required this.onEstado});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.6),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1.4),
              4: FlexColumnWidth(1.2),
              5: FixedColumnWidth(130),
            },
            children: [
              TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: ['Nº Pedido', 'Cliente', 'Contenido',
                    'Estado', 'Peso / Valor', 'Acciones']
                      .map((h) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Text(h, style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280)))))
                      .toList()),
              ...pedidos.map((p) => TableRow(
                  decoration: const BoxDecoration(border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB)))),
                  children: [
                    // Nº Pedido
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.numeroPedido, style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF1A1A2E))),
                              _TipoBadge(tipo: p.tipo),
                              if (p.trackingExterno != null) ...[
                                const SizedBox(height: 2),
                                GestureDetector(
                                    onTap: () => Clipboard.setData(
                                        ClipboardData(text: p.trackingExterno!)),
                                    child: Row(children: [
                                      const Icon(Icons.content_copy_rounded,
                                          size: 10, color: Color(0xFF9CA3AF)),
                                      const SizedBox(width: 3),
                                      Flexible(child: Text(p.trackingExterno!,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10,
                                              color: Color(0xFF9CA3AF)))),
                                    ])),
                              ],
                            ])),
                    // Cliente
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.clienteNombreCompleto,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A2E))),
                              Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAF6),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text(p.clienteCasillero,
                                      style: const TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A237E)))),
                              if (p.sucursalDestinoNombre != null)
                                Text(p.sucursalDestinoNombre!,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9CA3AF))),
                            ])),
                    // Contenido
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.descripcion,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF374151))),
                              if (p.proveedor != null) ...[
                                const SizedBox(height: 3),
                                _ProveedorBadge(proveedor: p.proveedor!),
                              ],
                            ])),
                    // Estado
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: _EstadoBadge(estado: p.estado)),
                    // Peso / Valor
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.peso != null)
                                Text('${p.peso!.toStringAsFixed(2)} lb',
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151))),
                              if (p.valorDeclarado != null)
                                Text('\$${p.valorDeclarado!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0xFF6B7280))),
                            ])),
                    // Acciones
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(children: [
                          _PedBtn(icon: Icons.visibility_outlined,
                              color: const Color(0xFF1A237E),
                              tip: 'Ver detalle',
                              onTap: () => onDetail(p)),
                          const SizedBox(width: 4),
                          _PedBtn(icon: Icons.edit_outlined,
                              color: const Color(0xFF7B1FA2),
                              tip: 'Editar',
                              onTap: () => onEdit(p)),
                          const SizedBox(width: 4),
                          if (!p.estado.esFinal)
                            _PedBtn(icon: Icons.swap_horiz_rounded,
                                color: const Color(0xFFE65100),
                                tip: 'Cambiar estado',
                                onTap: () => onEstado(p)),
                        ])),
                  ])),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CARDS MÓVIL ──────────────────────────────────────────────────────────────
class _PedidosCards extends StatelessWidget {
  final List<PedidoModel>          pedidos;
  final void Function(PedidoModel) onDetail, onEdit, onEstado;
  const _PedidosCards({required this.pedidos, required this.onDetail,
    required this.onEdit, required this.onEstado});

  @override
  Widget build(BuildContext context) => ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: pedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PedCard(
        p: pedidos[i],
        onDetail: () => onDetail(pedidos[i]),
        onEdit:   () => onEdit(pedidos[i]),
        onEstado: () => onEstado(pedidos[i]),
      ));
}

class _PedCard extends StatelessWidget {
  final PedidoModel p;
  final VoidCallback onDetail, onEdit, onEstado;
  const _PedCard({required this.p, required this.onDetail,
    required this.onEdit, required this.onEstado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabecera
        Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(p.numeroPedido, style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  fontFamily: 'monospace', color: Color(0xFF1A1A2E))),
              const SizedBox(width: 8),
              _TipoBadge(tipo: p.tipo),
            ]),
            Text(p.clienteNombreCompleto,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
          ])),
          PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: Color(0xFF9CA3AF), size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                _popItem('detail', Icons.visibility_outlined,
                    'Ver detalle', const Color(0xFF1A237E)),
                _popItem('edit', Icons.edit_outlined,
                    'Editar', const Color(0xFF7B1FA2)),
                if (!p.estado.esFinal)
                  _popItem('estado', Icons.swap_horiz_rounded,
                      'Cambiar estado', const Color(0xFFE65100)),
              ],
              onSelected: (v) {
                if (v == 'detail') onDetail();
                if (v == 'edit')   onEdit();
                if (v == 'estado') onEstado();
              }),
        ]),
        const SizedBox(height: 10),
        // Info cliente + casillero
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(p.clienteCasillero, style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A237E)))),
          const SizedBox(width: 8),
          if (p.proveedor != null) _ProveedorBadge(proveedor: p.proveedor!),
        ]),
        const SizedBox(height: 8),
        // Descripción
        Text(p.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
        if (p.trackingExterno != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
              onTap: () => Clipboard.setData(
                  ClipboardData(text: p.trackingExterno!)),
              child: Row(children: [
                const Icon(Icons.content_copy_rounded,
                    size: 12, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Flexible(child: Text(p.trackingExterno!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF)))),
              ])),
        ],
        const SizedBox(height: 10),
        // Badges + datos
        Wrap(spacing: 6, runSpacing: 6, children: [
          _EstadoBadge(estado: p.estado),
          if (p.peso != null)
            _InfoChip(icon: Icons.scale_outlined,
                label: '${p.peso!.toStringAsFixed(2)} lb'),
          if (p.valorDeclarado != null)
            _InfoChip(icon: Icons.attach_money_rounded,
                label: '\$${p.valorDeclarado!.toStringAsFixed(2)}'),
        ]),
        const SizedBox(height: 12),
        // Ruta
        if (p.sucursalOrigenNombre != null || p.sucursalDestinoNombre != null)
          Row(children: [
            if (p.sucursalOrigenNombre != null)
              Flexible(child: Row(children: [
                const Icon(Icons.flight_takeoff_rounded,
                    size: 12, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Flexible(child: Text(p.sucursalOrigenNombre!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF6B7280)))),
              ])),
            if (p.sucursalDestinoNombre != null) ...[
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 12, color: Color(0xFF9CA3AF))),
              Flexible(child: Row(children: [
                const Icon(Icons.flight_land_rounded,
                    size: 12, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Flexible(child: Text(p.sucursalDestinoNombre!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF6B7280)))),
              ])),
            ],
          ]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: onDetail,
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A237E),
                side: const BorderSide(color: Color(0xFFC5CAE9)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10)),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('Ver detalle', style: TextStyle(fontSize: 13)))),
      ]),
    );
  }

  PopupMenuItem<String> _popItem(
      String v, IconData icon, String label, Color c) =>
      PopupMenuItem(value: v,
          child: Row(children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 10), Text(label)]));
}

// ─── SHEET DETALLE ────────────────────────────────────────────────────────────
class _PedidoDetailSheet extends StatelessWidget {
  final PedidoModel  pedido;
  final VoidCallback onEdit, onEstado, onRecepcion,
      onComprobante, onVerificarPago, onConfirmarYFacturar; // ← agregar

  const _PedidoDetailSheet({
    required this.pedido,
    required this.onEdit,
    required this.onEstado,
    required this.onRecepcion,
    required this.onComprobante,
    required this.onVerificarPago,
    required this.onConfirmarYFacturar,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} '
          '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final p = pedido;
    return _PedSheet(
      title: p.numeroPedido,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Badges
        Wrap(spacing: 8, runSpacing: 8, children: [
          _EstadoBadge(estado: p.estado),
          _TipoBadge(tipo: p.tipo),
          if (p.proveedor != null) _ProveedorBadge(proveedor: p.proveedor!),
        ]),
        const SizedBox(height: 20),

        // Cliente
        _PedSectionTitle('Cliente'),
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_outline_rounded,
                      color: Color(0xFF1A237E), size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.clienteNombreCompleto,
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 15, color: Color(0xFF1A1A2E))),
                Row(children: [
                  const Text('Casillero: ', style: TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
                  Text(p.clienteCasillero, style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12,
                      color: Color(0xFF1A237E))),
                ]),
                if (p.clienteIdentificacion != null)
                  Text(p.clienteIdentificacion!, style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
              ])),
            ])),
        const SizedBox(height: 16),

        // Contenido
        _PedSectionTitle('Contenido del paquete'),
        _PedDetailRow(Icons.inventory_2_outlined, 'Descripción', p.descripcion),
        if (p.cantidadItems != null)
          _PedDetailRow(Icons.format_list_numbered_rounded,
              'Cantidad', '${p.cantidadItems} item${p.cantidadItems == 1 ? '' : 's'}'),
        if (p.peso != null)
          _PedDetailRow(Icons.scale_outlined, 'Peso',
              '${p.peso!.toStringAsFixed(2)} libras'),
        if (p.largo != null && p.ancho != null && p.alto != null)
          _PedDetailRow(Icons.straighten_rounded, 'Dimensiones',
              '${p.largo!.toStringAsFixed(1)} × ${p.ancho!.toStringAsFixed(1)} × ${p.alto!.toStringAsFixed(1)} cm'),
        if (p.valorDeclarado != null)
          _PedDetailRow(Icons.attach_money_rounded, 'Valor declarado',
              '\$${p.valorDeclarado!.toStringAsFixed(2)} USD'),
        const SizedBox(height: 16),

        // Tracking
        if (p.trackingExterno != null) ...[
          _PedSectionTitle('Tracking externo'),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Row(children: [
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (p.proveedor != null)
                    Text(p.proveedor!, style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12,
                        color: Color(0xFF1A237E))),
                  Text(p.trackingExterno!, style: const TextStyle(
                      fontSize: 13, fontFamily: 'monospace',
                      color: Color(0xFF374151))),
                ])),
                IconButton(
                    icon: const Icon(Icons.content_copy_rounded,
                        color: Color(0xFF9CA3AF), size: 18),
                    tooltip: 'Copiar tracking',
                    onPressed: () => Clipboard.setData(
                        ClipboardData(text: p.trackingExterno!))),
              ])),
          const SizedBox(height: 16),
        ],

        // Ruta
        _PedSectionTitle('Ruta'),
        if (p.sucursalOrigenNombre != null)
          _PedDetailRow(Icons.flight_takeoff_rounded, 'Origen',
              '${p.sucursalOrigenNombre} (${p.sucursalOrigenPais ?? ''})'),
        if (p.sucursalDestinoNombre != null)
          _PedDetailRow(Icons.flight_land_rounded, 'Destino',
              '${p.sucursalDestinoNombre} - ${p.sucursalDestinoCiudad ?? ''}'),
        const SizedBox(height: 16),

        // Línea de tiempo
        _PedSectionTitle('Historial de fechas'),
        _TimelineItem('Registrado',     p.fechaRegistro,        done: true),
        _TimelineItem('Recibido en sede', p.fechaRecepcionSede,  done: p.fechaRecepcionSede != null),
        _TimelineItem('Salió al exterior', p.fechaSalidaExterior, done: p.fechaSalidaExterior != null),
        _TimelineItem('Llegó a Ecuador', p.fechaLlegadaEcuador, done: p.fechaLlegadaEcuador != null),
        _TimelineItem('Disponible',     p.fechaDisponible,      done: p.fechaDisponible != null),
        _TimelineItem('Entregado',      p.fechaEntrega,         done: p.fechaEntrega != null,
            isLast: true),
        const SizedBox(height: 16),

        // Observaciones
        if (p.observaciones != null && p.observaciones!.isNotEmpty) ...[
          _PedSectionTitle('Observaciones'),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFFDE7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFF176))),
              child: Text(p.observaciones!, style: const TextStyle(
                  fontSize: 13, color: Color(0xFF374151)))),
          const SizedBox(height: 8),
        ],
        if (p.notasInternas != null && p.notasInternas!.isNotEmpty) ...[
          _PedSectionTitle('Notas internas'),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCE93D8))),
              child: Text(p.notasInternas!, style: const TextStyle(
                  fontSize: 13, color: Color(0xFF374151)))),
          const SizedBox(height: 8),
        ],

        if (p.registradoPor != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Text('Registrado por: ${p.registradoPor}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ])),

        const SizedBox(height: 4),
        // Botones
        Column(children: [
          if (p.tieneItems && p.estado == EstadoPedido.REGISTRADO) ...[
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: onRecepcion,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: Text(
                'Verificar recepción (${p.items.length} items)',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            )),
            const SizedBox(height: 10),
          ],
          // Botón subir comprobante
          if (p.estadoPago == EstadoPago.PENDIENTE_COMPROBANTE ||
              p.estadoPago == EstadoPago.PAGO_RECHAZADO) ...[
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: onComprobante,
              style: ElevatedButton.styleFrom(
                  backgroundColor: p.estadoPago == EstadoPago.PAGO_RECHAZADO
                      ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: Icon(p.estadoPago == EstadoPago.PAGO_RECHAZADO
                  ? Icons.refresh_rounded : Icons.upload_rounded, size: 18),
              label: Text(
                p.estadoPago == EstadoPago.PAGO_RECHAZADO
                    ? 'Volver a subir comprobante'
                    : 'Subir comprobante de pago',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            )),
            const SizedBox(height: 10),
          ],

          // Badge de estado de pago
          if (p.estadoPago != null) ...[
            _EstadoPagoBanner(estadoPago: p.estadoPago!,
                motivoRechazo: p.motivoRechazo),
            const SizedBox(height: 10),
          ],
          // ← BOTÓN VERIFICAR Y FACTURAR — FUERA del Row, como SizedBox full width
          if (p.estadoPago == EstadoPago.PAGO_VERIFICADO) ...[
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: onConfirmarYFacturar,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Verificar llegada y facturar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 10),
          ],
          // ← BOTÓN VERIFICAR PAGO — también fuera del Row
          if (p.estadoPago == EstadoPago.COMPROBANTE_ENVIADO) ...[
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: onVerificarPago,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Revisar y verificar pago',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            )),
            const SizedBox(height: 10),
          ],

          // Row de editar + cambiar estado (siempre al final)
          Row(children: [
            Expanded(child: OutlinedButton.icon(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B1FA2),
                    side: const BorderSide(color: Color(0xFFCE93D8)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'))),
            if (!p.estado.esFinal) ...[
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                  onPressed: onEstado,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Cambiar estado'))),
            ],
          ]),
        ]),

      ]),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String     label;
  final DateTime?  date;
  final bool       done;
  final bool       isLast;
  const _TimelineItem(this.label, this.date,
      {required this.done, this.isLast = false});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 18, height: 18,
            decoration: BoxDecoration(
                color: done ? const Color(0xFF2E7D32) : const Color(0xFFE5E7EB),
                shape: BoxShape.circle),
            child: Icon(done ? Icons.check_rounded : Icons.circle_outlined,
                size: 10, color: Colors.white)),
        if (!isLast)
          Container(width: 2, height: 28,
              color: done ? const Color(0xFF2E7D32) : const Color(0xFFE5E7EB)),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600,
                color: done ? const Color(0xFF1A1A2E) : const Color(0xFF9CA3AF))),
            if (date != null)
              Text(_fmt(date!), style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7280))),
          ]))),
    ]);
  }
}

// ─── SHEET BUSCAR CLIENTE (AGENTE/ADMIN) ──────────────────────────────────────
class _BuscarClienteSheet extends StatefulWidget {
  const _BuscarClienteSheet();

  @override
  State<_BuscarClienteSheet> createState() => _BuscarClienteSheetState();
}

class _BuscarClienteSheetState extends State<_BuscarClienteSheet> {
  final _cedulaCtrl = TextEditingController();

  bool                    _buscando   = false;
  bool                    _buscado    = false;
  Map<String, dynamic>?   _cliente;
  String?                 _error;

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final cedula = _cedulaCtrl.text.trim();
    if (cedula.isEmpty) {
      setState(() => _error = 'Ingresa un número de cédula');
      return;
    }
    if (cedula.length < 6) {
      setState(() => _error = 'La cédula debe tener al menos 6 dígitos');
      return;
    }

    setState(() {
      _buscando = true;
      _buscado  = false;
      _cliente  = null;
      _error    = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res   = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/pedidos/sucursal/cliente'
                '?cedula=$cedula'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _cliente = jsonDecode(utf8.decode(res.bodyBytes))
          as Map<String, dynamic>;
          _buscado = true;
          _error   = null;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _error   = 'No se encontró ningún cliente con esa cédula';
          _buscado = true;
        });
      } else {
        setState(() {
          _error   = 'Error al buscar. Intenta nuevamente';
          _buscado = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error   = 'Sin conexión. Verifica tu red';
          _buscado = true;
        });
      }
    }

    if (mounted) setState(() => _buscando = false);
  }

  void _continuarConCliente(BuildContext ctx) {
    if (_cliente == null) return;
    Navigator.pop(context);
    // Abre el formulario presencial pasando el cliente ya encontrado
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<PedidoBloc>(),
        child: _PedidoPresencialFormSheet(clienteData: _cliente!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PedSheet(
      title: 'Pedido en sucursal',
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Aviso modo presencial ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC5CAE9))),
              child: const Row(children: [
                Icon(Icons.storefront_outlined,
                    color: Color(0xFF1A237E), size: 20),
                SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Atención presencial',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13,
                              color: Color(0xFF1A237E))),
                      Text(
                        'Busca al cliente por su número de cédula '
                            'y registra el pedido a su nombre.',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF3949AB)),
                      ),
                    ])),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Buscar por cédula ─────────────────────────────────────────────
            _PedSectionTitle('Buscar cliente'),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: TextFormField(
                controller: _cedulaCtrl,
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) => _buscar(),
                decoration: _pDeco(
                  'Número de cédula del cliente',
                  suf: _cedulaCtrl.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF9CA3AF)),
                    onPressed: () => setState(() {
                      _cedulaCtrl.clear();
                      _cliente = null;
                      _buscado = false;
                      _error   = null;
                    }),
                  )
                      : null,
                ),
              )),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _buscando ? null : _buscar,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20)),
                  child: _buscando
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search_rounded, size: 22),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Resultado ─────────────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: !_buscado
                  ? const SizedBox.shrink(key: ValueKey('vacio'))
                  : _error != null
              // Error / no encontrado
                  ? _ResultadoError(
                  key: const ValueKey('error'),
                  mensaje: _error!)
              // Cliente encontrado
                  : _cliente != null
                  ? _ResultadoCliente(
                key: const ValueKey('encontrado'),
                cliente: _cliente!,
                onContinuar: () =>
                    _continuarConCliente(context),
              )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // ── Tips ──────────────────────────────────────────────────────────
            if (!_buscado)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.tips_and_updates_outlined,
                            size: 14, color: Color(0xFF9CA3AF)),
                        SizedBox(width: 6),
                        Text('Tips',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12,
                                color: Color(0xFF6B7280))),
                      ]),
                      const SizedBox(height: 8),
                      ...[
                        'Ingresa la cédula o pasaporte del cliente',
                        'El cliente debe estar registrado en el sistema',
                        'El pedido quedará asociado a su perfil',
                        'Tu sucursal quedará registrada automáticamente',
                      ].map((t) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12)),
                              Expanded(child: Text(t,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280)))),
                            ]),
                      )),
                    ]),
              ),
          ]),
    );
  }
}

// ─── Card resultado cliente encontrado ───────────────────────────────────────
class _ResultadoCliente extends StatelessWidget {
  final Map<String, dynamic> cliente;
  final VoidCallback         onContinuar;

  const _ResultadoCliente({
    super.key,
    required this.cliente,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final nombres   = '${cliente['nombres'] ?? ''} '
        '${cliente['apellidos'] ?? ''}'.trim();
    final casillero = cliente['casillero']?.toString() ?? '';
    final cedula    = cliente['numeroIdentificacion']?.toString() ??
        cliente['cedula']?.toString() ?? '';
    final email     = cliente['email']?.toString() ?? '';
    final telefono  = cliente['telefono']?.toString() ?? '';
    final plan      = cliente['plan']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0), width: 2)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header cliente
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombres,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15,
                            color: Color(0xFF1A1A2E))),
                    Row(children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1A237E),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(casillero,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                      if (plan.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFA5D6A7))),
                          child: Text(plan,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32))),
                        ),
                      ],
                    ]),
                  ])),
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32), size: 24),
            ]),

            const Divider(height: 20, color: Color(0xFFBBF7D0)),

            // Datos del cliente
            if (cedula.isNotEmpty)
              _InfoFilaCompacta(
                  Icons.badge_outlined, 'Cédula', cedula),
            if (email.isNotEmpty)
              _InfoFilaCompacta(
                  Icons.email_outlined, 'Email', email),
            if (telefono.isNotEmpty)
              _InfoFilaCompacta(
                  Icons.phone_outlined, 'Teléfono', telefono),

            const SizedBox(height: 16),

            // Botón continuar
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onContinuar,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Registrar pedido para este cliente',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
    );
  }
}

// ─── Card error / no encontrado ───────────────────────────────────────────────
class _ResultadoError extends StatelessWidget {
  final String mensaje;
  const _ResultadoError({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2))),
      child: Row(children: [
        const Icon(Icons.person_off_outlined,
            color: Color(0xFFC62828), size: 24),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cliente no encontrado',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13,
                      color: Color(0xFFC62828))),
              const SizedBox(height: 2),
              Text(mensaje,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFE57373))),
            ])),
      ]),
    );
  }
}

// ─── FORMULARIO PRESENCIAL (agente ya encontró al cliente) ────────────────────
class _PedidoPresencialFormSheet extends StatelessWidget {
  final Map<String, dynamic> clienteData;
  const _PedidoPresencialFormSheet({required this.clienteData});

  @override
  Widget build(BuildContext context) => PedidoFormSheet(
    clienteId:       clienteData['id']?.toString() ?? '',
    clienteFijo:     clienteData,
    endpointOverride:'${ApiConstants.baseUrl}/api/pedidos/sucursal',
    onCreado: () {
      // Recargar pedidos después de crear
    },
  );
}




// ─── SHEET FORMULARIO ─────────────────────────────────────────────────────────
class _PedidoFormSheet extends StatefulWidget {
  final PedidoModel? pedido;
  const _PedidoFormSheet({this.pedido});
  @override
  State<_PedidoFormSheet> createState() => _PedidoFormSheetState();
}

class _PedidoFormSheetState extends State<_PedidoFormSheet> {
  final _key = GlobalKey<FormState>();

  // Referencias externas
  List<_ClienteRef> _clientes    = [];
  List<_SucRef>     _sucursales  = [];
  bool              _loadingRefs = true;

  // Datos básicos
  String?    _clienteId;
  String?    _origenId;
  String?    _destinoId;
  TipoPedido _tipo = TipoPedido.IMPORTACION;

  // Tracking y contenido
  late final TextEditingController _tracking  = TextEditingController();
  late final TextEditingController _proveedor = TextEditingController();
  late final TextEditingController _urlT      = TextEditingController();
  late final TextEditingController _desc      = TextEditingController();
  late final TextEditingController _peso      = TextEditingController();
  late final TextEditingController _largo     = TextEditingController();
  late final TextEditingController _ancho     = TextEditingController();
  late final TextEditingController _alto      = TextEditingController();
  late final TextEditingController _valor     = TextEditingController();
  late final TextEditingController _cantidad  = TextEditingController();
  late final TextEditingController _obs       = TextEditingController();
  late final TextEditingController _notasInt  = TextEditingController();

  // ─── Items con subcategoría ───────────────────────────────────────────────
  final List<_ItemFormData> _items = [];

  // ─── Pago ─────────────────────────────────────────────────────────────────
  FormaPago _formaPago = FormaPago.TRANSFERENCIA;
  late final TextEditingController _banco     = TextEditingController();
  late final TextEditingController _referencia = TextEditingController();

  // ─── Facturación ──────────────────────────────────────────────────────────
  bool _usarDatosCliente = true;
  late final TextEditingController _factRazon    = TextEditingController();
  late final TextEditingController _factRuc      = TextEditingController();
  late final TextEditingController _factDireccion = TextEditingController();
  late final TextEditingController _factEmail    = TextEditingController();
  late final TextEditingController _factTelefono = TextEditingController();

  bool get _isEdit => widget.pedido != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.pedido!;
      _clienteId  = p.clienteId;
      _origenId   = p.sucursalOrigenId;
      _destinoId  = p.sucursalDestinoId;
      _tipo       = p.tipo;
      _tracking.text   = p.trackingExterno ?? '';
      _proveedor.text  = p.proveedor ?? '';
      _urlT.text       = p.urlTracking ?? '';
      _desc.text       = p.descripcion;
      _peso.text       = p.peso?.toString() ?? '';
      _largo.text      = p.largo?.toString() ?? '';
      _ancho.text      = p.ancho?.toString() ?? '';
      _alto.text       = p.alto?.toString() ?? '';
      _valor.text      = p.valorDeclarado?.toString() ?? '';
      _cantidad.text   = p.cantidadItems?.toString() ?? '';
      _obs.text        = p.observaciones ?? '';
      _notasInt.text   = p.notasInternas ?? '';

      // Pago
      if (p.formaPago != null) _formaPago = p.formaPago!;
      _banco.text      = p.bancoOrigen ?? '';
      _referencia.text = p.numeroReferencia ?? '';

      // Facturación
      if (p.datosFacturacion != null) {
        _usarDatosCliente    = p.datosFacturacion!.usarDatosCliente;
        _factRazon.text      = p.datosFacturacion!.razonSocial ?? '';
        _factRuc.text        = p.datosFacturacion!.rucCedula ?? '';
        _factDireccion.text  = p.datosFacturacion!.direccion ?? '';
        _factEmail.text      = p.datosFacturacion!.email ?? '';
        _factTelefono.text   = p.datosFacturacion!.telefono ?? '';
      }
    }
    _fetchRefs();
  }

  Future<void> _fetchRefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final h = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      final base = ApiConstants.baseUrl;
      final results = await Future.wait([
        http.get(Uri.parse('$base/api/sucursales'), headers: h),
        http.get(Uri.parse('$base/api/clientes'), headers: h),
      ]);
      if (!mounted) return;
      if (results[0].statusCode == 200) {
        final list = jsonDecode(utf8.decode(results[0].bodyBytes)) as List;
        _sucursales = list.map((e) => _SucRef(
          id:     e['id'].toString(),
          nombre: e['nombre'].toString(),
          pais:   e['pais'].toString(),
        )).toList();
      }
      if (results[1].statusCode == 200) {
        final list = jsonDecode(utf8.decode(results[1].bodyBytes)) as List;
        _clientes = list.map((e) => _ClienteRef(
          id:        e['id'].toString(),
          nombres:   e['nombres']?.toString() ?? '',
          apellidos: e['apellidos']?.toString() ?? '',
          casillero: e['casillero']?.toString() ?? '',
        )).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingRefs = false);
  }

  @override
  void dispose() {
    for (final c in [
      _tracking, _proveedor, _urlT, _desc, _peso, _largo, _ancho,
      _alto, _valor, _cantidad, _obs, _notasInt, _banco, _referencia,
      _factRazon, _factRuc, _factDireccion, _factEmail, _factTelefono,
    ]) { c.dispose(); }
    for (final item in _items) { item.dispose(); }
    super.dispose();
  }

  void _addItem() {
    setState(() => _items.add(_ItemFormData()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    if (_clienteId == null) { _err('Selecciona un cliente'); return; }
    if (_origenId == null || _destinoId == null) {
      _err('Selecciona sucursal origen y destino'); return;
    }
    if (_formaPago == FormaPago.TRANSFERENCIA &&
        _banco.text.trim().isEmpty) {
      _err('Ingresa el banco de origen para la transferencia'); return;
    }

    // Construir items
    final itemsData = _items.map((item) {
      final m = <String, dynamic>{
        'tipoProducto': item.tipoProducto?.name ?? 'OTRO',
        'descripcion':  item.descripcion.text.trim(),
      };
      if (item.subcategoria != null)
        m['subcategoria'] = item.subcategoria;
      if (item.tracking.text.trim().isNotEmpty)
        m['trackingExterno'] = item.tracking.text.trim();
      if (item.proveedor.text.trim().isNotEmpty)
        m['proveedor'] = item.proveedor.text.trim();
      if (item.peso.text.trim().isNotEmpty)
        m['peso'] = double.tryParse(item.peso.text.trim());
      if (item.valor.text.trim().isNotEmpty)
        m['valorDeclarado'] = double.tryParse(item.valor.text.trim());
      return m;
    }).toList();

    // Datos de facturación
    final factData = <String, dynamic>{
      'usarDatosCliente':    _usarDatosCliente,
      if (!_usarDatosCliente) ...{
        'razonSocial':         _factRazon.text.trim(),
        'rucCedula':           _factRuc.text.trim(),
        'direccionFacturacion':_factDireccion.text.trim(),
        'emailFacturacion':    _factEmail.text.trim(),
        'telefonoFacturacion': _factTelefono.text.trim(),
      },
    };

    final data = <String, dynamic>{
      'tipo':              _tipo.name,
      'clienteId':         _clienteId,
      'trackingExterno':   _tracking.text.trim(),
      'proveedor':         _proveedor.text.trim(),
      'urlTracking':       _urlT.text.trim(),
      'descripcion':       _desc.text.trim(),
      'sucursalOrigenId':  _origenId,
      'sucursalDestinoId': _destinoId,
      'observaciones':     _obs.text.trim(),
      'notasInternas':     _notasInt.text.trim(),
      'formaPago':         _formaPago.name,
      'datosFacturacion':  factData,
      if (_items.isNotEmpty) 'items': itemsData,
      if (_formaPago == FormaPago.TRANSFERENCIA) ...{
        'bancoOrigen':      _banco.text.trim(),
        'numeroReferencia': _referencia.text.trim(),
      },
    };

    if (_peso.text.trim().isNotEmpty)
      data['peso'] = double.tryParse(_peso.text.trim());
    if (_largo.text.trim().isNotEmpty)
      data['largo'] = double.tryParse(_largo.text.trim());
    if (_ancho.text.trim().isNotEmpty)
      data['ancho'] = double.tryParse(_ancho.text.trim());
    if (_alto.text.trim().isNotEmpty)
      data['alto'] = double.tryParse(_alto.text.trim());
    if (_valor.text.trim().isNotEmpty)
      data['valorDeclarado'] = double.tryParse(_valor.text.trim());
    if (_cantidad.text.trim().isNotEmpty)
      data['cantidadItems'] = int.tryParse(_cantidad.text.trim());

    if (_isEdit) {
      context.read<PedidoBloc>()
          .add(PedidoUpdateRequested(widget.pedido!.id, data));
    } else {
      context.read<PedidoBloc>().add(PedidoCreateRequested(data));
    }
    Navigator.pop(context);
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg),
          backgroundColor: const Color(0xFFC62828)));


  @override
  Widget build(BuildContext context) => _PedSheet(
    title: _isEdit ? 'Editar pedido' : 'Nuevo pedido',
    child: Form(key: _key, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      // ── Tipo ─────────────────────────────────────────────────────────
      _PedLabel('Tipo de pedido'),
      const SizedBox(height: 8),
      Row(children: TipoPedido.values.map((t) {
        final sel = _tipo == t;
        return Expanded(child: Padding(
            padding: EdgeInsets.only(
                right: t == TipoPedido.IMPORTACION ? 8 : 0),
            child: GestureDetector(
                onTap: () => setState(() => _tipo = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFE8EAF6) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? const Color(0xFF1A237E)
                              : const Color(0xFFE5E7EB),
                          width: sel ? 2 : 1)),
                  child: Column(children: [
                    Icon(t == TipoPedido.IMPORTACION
                        ? Icons.flight_land_rounded
                        : Icons.flight_takeoff_rounded,
                        color: sel ? const Color(0xFF1A237E)
                            : const Color(0xFF9CA3AF), size: 20),
                    const SizedBox(height: 4),
                    Text(t.label, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? const Color(0xFF1A237E)
                            : const Color(0xFF9CA3AF))),
                  ]),
                ))));
      }).toList()),
      const SizedBox(height: 20),

      // ── Cliente ───────────────────────────────────────────────────────
      _PedLabel('Cliente *'),
      const SizedBox(height: 8),
      _loadingRefs
          ? const Center(child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(
              color: Color(0xFF1A237E))))
          : _ClienteDropdown(
          value: _clienteId,
          clientes: _clientes,
          onChanged: (v) => setState(() => _clienteId = v)),
      const SizedBox(height: 20),

      // ── Tracking externo ──────────────────────────────────────────────
      _PedLabel('Tracking externo'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(
            controller: _tracking,
            decoration: _pDeco('Ej: TBA123456789'))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _PedLabel('Proveedor'),
          const SizedBox(height: 4),
          TextFormField(controller: _proveedor,
              decoration: _pDeco('Amazon, FedEx...')),
        ])),
      ]),
      const SizedBox(height: 20),

      // ── Descripción ───────────────────────────────────────────────────
      _PedLabel('Descripción del contenido *'),
      const SizedBox(height: 8),
      TextFormField(
          controller: _desc, maxLines: 2,
          decoration: _pDeco('Ej: Laptop Dell XPS 15'),
          validator: (v) =>
          v == null || v.trim().isEmpty ? 'Campo requerido' : null),
      const SizedBox(height: 20),

      // ── Items con subcategorías ───────────────────────────────────────
      Row(children: [
        const Expanded(child: _PedLabel('Items del pedido')),
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add_rounded,
              size: 16, color: Color(0xFF1A237E)),
          label: const Text('Agregar item',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF1A237E))),
        ),
      ]),
      const SizedBox(height: 8),

      ..._items.asMap().entries.map((entry) {
        final i    = entry.key;
        final item = entry.value;
        return _ItemFormCard(
          key: ValueKey(item.id),
          item: item,
          index: i,
          onRemove: () => _removeItem(i),
          onChanged: () => setState(() {}),
        );
      }),

      if (_items.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB),
                  style: BorderStyle.solid)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 16, color: Color(0xFF9CA3AF)),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Sin items individuales. Puedes agregar items '
                  'para rastrear cada producto por separado.',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF)),
            )),
          ]),
        ),
      const SizedBox(height: 20),

      // ── Peso y dimensiones ────────────────────────────────────────────
      _PedLabel('Peso y dimensiones'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(controller: _peso,
            keyboardType: TextInputType.number,
            decoration: _pDeco('Peso (lb)'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(controller: _largo,
            keyboardType: TextInputType.number,
            decoration: _pDeco('Largo cm'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(controller: _ancho,
            keyboardType: TextInputType.number,
            decoration: _pDeco('Ancho cm'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(controller: _alto,
            keyboardType: TextInputType.number,
            decoration: _pDeco('Alto cm'))),
      ]),
      const SizedBox(height: 14),

      Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _PedLabel('Valor declarado (\$)'),
          const SizedBox(height: 8),
          TextFormField(controller: _valor,
              keyboardType: TextInputType.number,
              decoration: _pDeco('0.00')),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _PedLabel('Cantidad de ítems'),
          const SizedBox(height: 8),
          TextFormField(controller: _cantidad,
              keyboardType: TextInputType.number,
              decoration: _pDeco('1')),
        ])),
      ]),
      const SizedBox(height: 20),

      // ── Sucursales ────────────────────────────────────────────────────
      _PedLabel('Sucursal origen *'),
      const SizedBox(height: 8),
      _SucDropdown(
          hint: 'Sede exterior donde llega',
          value: _origenId,
          sucursales: _sucursales,
          excluir: _destinoId,
          onChanged: (v) => setState(() => _origenId = v)),
      const SizedBox(height: 14),
      _PedLabel('Sucursal destino *'),
      const SizedBox(height: 8),
      _SucDropdown(
          hint: 'Sucursal en Ecuador',
          value: _destinoId,
          sucursales: _sucursales,
          excluir: _origenId,
          onChanged: (v) => setState(() => _destinoId = v)),
      const SizedBox(height: 20),

      // ── Forma de pago ─────────────────────────────────────────────────
      _PedSectionTitle('Forma de pago'),
      const SizedBox(height: 12),
      Row(children: FormaPago.values.map((f) {
        final sel = _formaPago == f;
        return Expanded(child: Padding(
            padding: EdgeInsets.only(
                right: f == FormaPago.EFECTIVO ? 8 : 0),
            child: GestureDetector(
                onTap: () => setState(() => _formaPago = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? const Color(0xFF2E7D32)
                              : const Color(0xFFE5E7EB),
                          width: sel ? 2 : 1)),
                  child: Column(children: [
                    Icon(
                      f == FormaPago.EFECTIVO
                          ? Icons.payments_outlined
                          : Icons.account_balance_outlined,
                      color: sel ? const Color(0xFF2E7D32)
                          : const Color(0xFF9CA3AF),
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(f.label, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: sel ? const Color(0xFF2E7D32)
                            : const Color(0xFF9CA3AF))),
                  ]),
                ))));
      }).toList()),
      const SizedBox(height: 14),

      // Datos adicionales según forma de pago
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _formaPago == FormaPago.TRANSFERENCIA
            ? Column(
            key: const ValueKey('transferencia'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFBBF7D0))),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Luego de registrar podrás subir '
                        'el comprobante de transferencia.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF2E7D32)),
                  )),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PedLabel('Banco origen *'),
                      const SizedBox(height: 8),
                      TextFormField(
                          controller: _banco,
                          decoration: _pDeco(
                              'Ej: Banco Pichincha'),
                          validator: (v) =>
                          _formaPago == FormaPago.TRANSFERENCIA &&
                              (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null),
                    ])),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PedLabel('Nº referencia'),
                      const SizedBox(height: 8),
                      TextFormField(
                          controller: _referencia,
                          decoration: _pDeco('Opcional')),
                    ])),
              ]),
            ])
            : Container(
          key: const ValueKey('efectivo'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFFFE082))),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 16, color: Color(0xFFE65100)),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Pago en efectivo. El agente deberá '
                  'subir una foto del recibo después.',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFFE65100)),
            )),
          ]),
        ),
      ),
      const SizedBox(height: 20),

      // ── Datos de facturación ──────────────────────────────────────────
      _PedSectionTitle('Datos de facturación'),
      const SizedBox(height: 12),

      // Toggle usar datos del cliente
      GestureDetector(
        onTap: () => setState(
                () => _usarDatosCliente = !_usarDatosCliente),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: _usarDatosCliente
                  ? const Color(0xFFE8EAF6) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _usarDatosCliente
                      ? const Color(0xFF1A237E)
                      : const Color(0xFFE5E7EB),
                  width: _usarDatosCliente ? 2 : 1)),
          child: Row(children: [
            Icon(
              _usarDatosCliente
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: _usarDatosCliente
                  ? const Color(0xFF1A237E)
                  : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Usar mis datos personales',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13, color: Color(0xFF374151))),
                  Text('Nombre, cédula y correo del perfil',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                ])),
          ]),
        ),
      ),
      const SizedBox(height: 12),

      // Campos de tercero (se muestran si no usa datos propios)
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !_usarDatosCliente
            ? Column(
            key: const ValueKey('tercero'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                  controller: _factRazon,
                  decoration: _pDeco(
                      'Razón social o nombre completo'),
                  validator: (v) => !_usarDatosCliente &&
                      (v == null || v.trim().isEmpty)
                      ? 'Requerido'
                      : null),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextFormField(
                    controller: _factRuc,
                    decoration: _pDeco('RUC / Cédula'),
                    validator: (v) => !_usarDatosCliente &&
                        (v == null || v.trim().isEmpty)
                        ? 'Requerido'
                        : null)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(
                    controller: _factTelefono,
                    decoration: _pDeco('Teléfono'))),
              ]),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _factEmail,
                  decoration: _pDeco(
                      'Correo electrónico')),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _factDireccion,
                  decoration: _pDeco('Dirección')),
              const SizedBox(height: 10),
            ])
            : const SizedBox.shrink(key: ValueKey('propio')),
      ),

      // ── Observaciones ─────────────────────────────────────────────────
      _PedLabel('Observaciones'),
      const SizedBox(height: 8),
      TextFormField(controller: _obs, maxLines: 2,
          decoration: _pDeco('Notas generales...')),
      const SizedBox(height: 14),
      _PedLabel('Notas internas (solo empleados)'),
      const SizedBox(height: 8),
      TextFormField(controller: _notasInt, maxLines: 2,
          decoration: _pDeco('Notas solo para el equipo...')),
      const SizedBox(height: 24),

      _PedSubmitBtn(
          label: _isEdit ? 'Guardar cambios' : 'Registrar pedido',
          onTap: _submit),
    ])),
  );
}

// ─── Card de item con tipo + subcategoría ─────────────────────────────────────
class _ItemFormCard extends StatefulWidget {
  final _ItemFormData item;
  final int           index;
  final VoidCallback  onRemove;
  final VoidCallback  onChanged;

  const _ItemFormCard({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ItemFormCard> createState() => _ItemFormCardState();
}

class _ItemFormCardState extends State<_ItemFormCard> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header del item
            Row(children: [
              Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${widget.index + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.bold)))),
              const SizedBox(width: 10),
              const Expanded(child: Text('Item',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13,
                      color: Color(0xFF374151)))),
              IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ]),
            const SizedBox(height: 12),

            // Tipo de producto
            _PedLabel('Tipo de producto *'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TipoProducto>(
                  value: item.tipoProducto,
                  hint: const Text('Seleccionar tipo',
                      style: TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 13)),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6B7280)),
                  items: TipoProducto.values.map((t) =>
                      DropdownMenuItem(
                        value: t,
                        child: Text(t.label,
                            style: const TextStyle(fontSize: 13)),
                      )).toList(),
                  onChanged: (t) => setState(() {
                    item.tipoProducto  = t;
                    item.subcategoria  = null; // resetear subcategoría
                    widget.onChanged();
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Subcategoría (solo si hay tipo seleccionado)
            if (item.tipoProducto != null) ...[
              _PedLabel('Subcategoría'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: item.subcategoria,
                    hint: const Text('Seleccionar subcategoría',
                        style: TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 13)),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6B7280)),
                    items: item.tipoProducto!.subcategorias.map((s) =>
                        DropdownMenuItem(
                          value: s,
                          child: Text(
                            item.tipoProducto!.subcategoriaLabel(s),
                            style: const TextStyle(fontSize: 13),
                          ),
                        )).toList(),
                    onChanged: (s) => setState(() {
                      item.subcategoria = s;
                      widget.onChanged();
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Descripción
            _PedLabel('Descripción *'),
            const SizedBox(height: 6),
            TextFormField(
                controller: item.descripcion,
                decoration: _pDeco('Ej: Laptop Dell XPS 15 negro'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null),
            const SizedBox(height: 10),

            // Tracking + proveedor
            Row(children: [
              Expanded(child: TextFormField(
                  controller: item.tracking,
                  decoration: _pDeco('Tracking (opcional)'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                  controller: item.proveedor,
                  decoration: _pDeco('Proveedor'))),
            ]),
            const SizedBox(height: 10),

            // Peso + valor
            Row(children: [
              Expanded(child: TextFormField(
                  controller: item.peso,
                  keyboardType: TextInputType.number,
                  decoration: _pDeco('Peso (lb)'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                  controller: item.valor,
                  keyboardType: TextInputType.number,
                  decoration: _pDeco('Valor \$'))),
            ]),
          ]),
    );
  }
}

// ─── Datos de un item en el formulario ───────────────────────────────────────
class _ItemFormData {
  final String id = UniqueKey().toString();
  TipoProducto? tipoProducto;
  String?       subcategoria;

  final TextEditingController descripcion = TextEditingController();
  final TextEditingController tracking    = TextEditingController();
  final TextEditingController proveedor   = TextEditingController();
  final TextEditingController peso        = TextEditingController();
  final TextEditingController valor       = TextEditingController();

  void dispose() {
    descripcion.dispose();
    tracking.dispose();
    proveedor.dispose();
    peso.dispose();
    valor.dispose();
  }
}

// ─── SHEET SUBIR COMPROBANTE ──────────────────────────────────────────────────
class _ComprobanteSheet extends StatefulWidget {
  final PedidoModel  pedido;
  final VoidCallback onSubido;

  const _ComprobanteSheet({
    required this.pedido,
    required this.onSubido,
  });

  @override
  State<_ComprobanteSheet> createState() => _ComprobanteSheetState();
}

class _ComprobanteSheetState extends State<_ComprobanteSheet> {
  final _bancoCtrl     = TextEditingController();
  final _referenciaCtrl = TextEditingController();

  String? _imagenBase64;
  String? _nombreArchivo;
  bool    _submitting = false;
  bool    _loadingImagen = false;

  @override
  void initState() {
    super.initState();
    // Pre-llenar banco y referencia si ya existen en el pedido
    _bancoCtrl.text      = widget.pedido.bancoOrigen ?? '';
    _referenciaCtrl.text = widget.pedido.numeroReferencia ?? '';
  }

  @override
  void dispose() {
    _bancoCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

  // ── Seleccionar imagen y convertir a base64 ───────────────────────────────
  Future<void> _seleccionarImagen() async {
    setState(() => _loadingImagen = true);
    try {
      // Usamos file_picker para seleccionar imagen
      // Asegúrate de tener file_picker en pubspec.yaml
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // necesitamos los bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _imagenBase64  = base64Encode(file.bytes!);
            _nombreArchivo = file.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: const Color(0xFFC62828),
        ));
      }
    }
    if (mounted) setState(() => _loadingImagen = false);
  }

  Future<void> _submit() async {
    if (_imagenBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una imagen del comprobante'),
        backgroundColor: Color(0xFFC62828),
      ));
      return;
    }

    if (widget.pedido.formaPago == FormaPago.TRANSFERENCIA &&
        _bancoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresa el banco de origen'),
        backgroundColor: Color(0xFFC62828),
      ));
      return;
    }

    setState(() => _submitting = true);

    try {
      context.read<PedidoBloc>().add(PedidoSubirComprobante(
        widget.pedido.id,
        _imagenBase64!,
        bancoOrigen:      _bancoCtrl.text.trim().isNotEmpty
            ? _bancoCtrl.text.trim() : null,
        numeroReferencia: _referenciaCtrl.text.trim().isNotEmpty
            ? _referenciaCtrl.text.trim() : null,
      ));

      if (mounted) {
        Navigator.pop(context);
        widget.onSubido();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFC62828),
        ));
      }
    }

    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final esTransferencia =
        widget.pedido.formaPago == FormaPago.TRANSFERENCIA;

    return _PedSheet(
      title: 'Subir comprobante',
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Info del pedido ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: Color(0xFF1A237E), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.pedido.numeroPedido,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13,
                              color: Color(0xFF1A1A2E))),
                      Text(widget.pedido.clienteNombreCompleto,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    ])),
                // Badge forma de pago
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: esTransferencia
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      esTransferencia
                          ? Icons.account_balance_outlined
                          : Icons.payments_outlined,
                      size: 12,
                      color: esTransferencia
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.pedido.formaPago?.label ?? 'Pago',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: esTransferencia
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100)),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Datos bancarios (solo transferencia) ──────────────────────────
            if (esTransferencia) ...[
              _PedSectionTitle('Datos de la transferencia'),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _bancoCtrl,
                  decoration: _pDeco('Banco origen *  Ej: Banco Pichincha')),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _referenciaCtrl,
                  decoration: _pDeco('Número de referencia (opcional)')),
              const SizedBox(height: 20),
            ],

            // ── Área de imagen ────────────────────────────────────────────────
            _PedSectionTitle(
              esTransferencia
                  ? 'Comprobante de transferencia'
                  : 'Foto del recibo de efectivo',
            ),
            const SizedBox(height: 12),

            // Preview o selector
            GestureDetector(
              onTap: _loadingImagen ? null : _seleccionarImagen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _imagenBase64 != null ? null : 160,
                decoration: BoxDecoration(
                    color: _imagenBase64 != null
                        ? Colors.transparent
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _imagenBase64 != null
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE5E7EB),
                        width: _imagenBase64 != null ? 2 : 1,
                        style: _imagenBase64 != null
                            ? BorderStyle.solid
                            : BorderStyle.solid)),
                child: _loadingImagen
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: Color(0xFF1A237E)),
                  ),
                )
                    : _imagenBase64 != null
                    ? _ImagenPreview(
                  base64: _imagenBase64!,
                  nombre: _nombreArchivo ?? 'comprobante',
                  onCambiar: _seleccionarImagen,
                )
                    : _SelectorImagenVacio(
                    esTransferencia: esTransferencia),
              ),
            ),
            const SizedBox(height: 20),

            // ── Instrucciones ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF90CAF9))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: Color(0xFF1565C0)),
                      SizedBox(width: 6),
                      Text('Requisitos del comprobante',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12,
                              color: Color(0xFF1565C0))),
                    ]),
                    const SizedBox(height: 6),
                    ...( esTransferencia
                        ? [
                      'Debe mostrar el monto transferido',
                      'Debe incluir fecha y hora',
                      'Debe ser legible y sin recortes',
                      'Formatos: JPG, PNG',
                    ]
                        : [
                      'Foto clara del recibo de caja',
                      'Debe mostrar el monto pagado',
                      'Debe ser legible',
                      'Formatos: JPG, PNG',
                    ]
                    ).map((t) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(
                                color: Color(0xFF1565C0), fontSize: 12)),
                            Expanded(child: Text(t,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF1565C0)))),
                          ]),
                    )),
                  ]),
            ),
            const SizedBox(height: 24),

            // ── Botón enviar ──────────────────────────────────────────────────
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _imagenBase64 != null
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF9CA3AF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                icon: _submitting
                    ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload_rounded, size: 18),
                label: Text(
                  _submitting
                      ? 'Enviando...'
                      : _imagenBase64 != null
                      ? 'Enviar comprobante'
                      : 'Selecciona una imagen primero',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ]),
    );
  }
}

// ─── Preview de imagen seleccionada ──────────────────────────────────────────
class _ImagenPreview extends StatelessWidget {
  final String       base64;
  final String       nombre;
  final VoidCallback onCambiar;

  const _ImagenPreview({
    required this.base64,
    required this.nombre,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ClipRRect(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(10)),
        child: Image.memory(
          base64Decode(base64),
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
            color: Color(0xFFF0FDF4),
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(10))),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF2E7D32), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(nombre,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600))),
          TextButton(
            onPressed: onCambiar,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Cambiar',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF1A237E))),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Área vacía para seleccionar imagen ──────────────────────────────────────
class _SelectorImagenVacio extends StatelessWidget {
  final bool esTransferencia;
  const _SelectorImagenVacio({required this.esTransferencia});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                shape: BoxShape.circle),
            child: Icon(
              esTransferencia
                  ? Icons.receipt_long_outlined
                  : Icons.camera_alt_outlined,
              size: 32,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Toca para seleccionar',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14,
                  color: Color(0xFF374151))),
          const SizedBox(height: 4),
          const Text('JPG o PNG desde tu galería o archivos',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF))),
        ]);
  }
}

// ─── SHEET CAMBIO DE ESTADO ───────────────────────────────────────────────────
class _CambioEstadoSheet extends StatefulWidget {
  final PedidoModel pedido;
  const _CambioEstadoSheet({required this.pedido});
  @override
  State<_CambioEstadoSheet> createState() => _CambioEstadoSheetState();
}

class _CambioEstadoSheetState extends State<_CambioEstadoSheet> {
  EstadoPedido? _nuevo;
  final _obsCtrl    = TextEditingController();
  final _sucIdCtrl  = TextEditingController();

  List<_SucRef> _sucursales = [];

  @override
  void initState() {
    super.initState();
    _fetchSuc();
  }

  Future<void> _fetchSuc() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res   = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/sucursales'),
          headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200 && mounted) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() => _sucursales = list.map((e) => _SucRef(
            id:     e['id'].toString(),
            nombre: e['nombre'].toString(),
            pais:   e['pais'].toString())).toList());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _obsCtrl.dispose(); _sucIdCtrl.dispose(); super.dispose();
  }

  Color _ec(EstadoPedido e) => switch (e) {
    EstadoPedido.REGISTRADO             => const Color(0xFF1A237E),
    EstadoPedido.RECIBIDO_EN_SEDE       => const Color(0xFF7B1FA2),
    EstadoPedido.EN_CONSOLIDACION       => const Color(0xFF6D4C41),
    EstadoPedido.EN_TRANSITO            => const Color(0xFFE65100),
    EstadoPedido.EN_ADUANA              => const Color(0xFFF57F17),
    EstadoPedido.RETENIDO_ADUANA        => const Color(0xFFB71C1C),
    EstadoPedido.LIBERADO_ADUANA        => const Color(0xFF00838F),
    EstadoPedido.RECIBIDO_EN_MATRIZ     => const Color(0xFF00695C),
    EstadoPedido.EN_DISTRIBUCION        => const Color(0xFF1565C0),
    EstadoPedido.DISPONIBLE_EN_SUCURSAL => const Color(0xFF2E7D32),
    EstadoPedido.ENTREGADO              => const Color(0xFF388E3C),
    EstadoPedido.DEVUELTO               => const Color(0xFF546E7A),
    EstadoPedido.EXTRAVIADO             => const Color(0xFFC62828),
    EstadoPedido.RECEPCION_PARCIAL      => const Color(0xFFF59E0B), // ← NUEVO
    EstadoPedido.ESPERANDO_ITEMS        => const Color(0xFF0288D1),
  };

  void _submit() {
    if (_nuevo == null) return;
    String? sucId = _sucIdCtrl.text.trim().isNotEmpty
        ? _sucIdCtrl.text.trim() : null;
    context.read<PedidoBloc>().add(PedidoEstadoCambiar(
        widget.pedido.id, _nuevo!,
        observacion: _obsCtrl.text.trim(),
        sucursalId: sucId));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final siguientes = widget.pedido.estado.siguientes;
    return _PedSheet(
      title: 'Cambiar estado',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Estado actual
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('Estado actual: ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              _EstadoBadge(estado: widget.pedido.estado),
            ])),
        const SizedBox(height: 20),
        _PedLabel('Nuevo estado'),
        const SizedBox(height: 12),

        // Opciones
        ...siguientes.map((e) {
          final sel = _nuevo == e;
          final c = _ec(e);
          return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                  onTap: () => setState(() => _nuevo = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: sel ? c.withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? c : const Color(0xFFE5E7EB),
                            width: sel ? 2 : 1)),
                    child: Row(children: [
                      Container(width: 12, height: 12,
                          decoration: BoxDecoration(
                              color: c, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.label, style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14,
                          color: sel ? c : const Color(0xFF374151)))),
                      if (sel) Icon(Icons.check_circle_rounded,
                          color: c, size: 20),
                    ]),
                  )));
        }),

        if (siguientes.isEmpty)
          Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 48),
                const SizedBox(height: 8),
                Text('Este pedido está en estado ${widget.pedido.estado.label}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7280))),
              ]))),

        if (siguientes.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Sucursal (opcional, para estados que la requieren)
          _PedLabel('Sucursal relacionada (opcional)'),
          const SizedBox(height: 8),
          _SucDropdown(
              hint: 'Sucursal donde ocurre el evento',
              value: _sucIdCtrl.text.isNotEmpty ? _sucIdCtrl.text : null,
              sucursales: _sucursales,
              onChanged: (v) => setState(
                      () => _sucIdCtrl.text = v ?? '')),
          const SizedBox(height: 14),
          _PedLabel('Observación (opcional)'),
          const SizedBox(height: 8),
          TextFormField(controller: _obsCtrl, maxLines: 2,
              decoration: _pDeco('Ej: Entregado a Samir Torres')),
          const SizedBox(height: 24),
          _PedSubmitBtn(
              label: _nuevo != null
                  ? 'Cambiar a ${_nuevo!.label}'
                  : 'Selecciona un estado',
              onTap: _nuevo != null ? _submit : () {},
              color: _nuevo != null
                  ? _ec(_nuevo!) : const Color(0xFF9CA3AF)),
        ],
      ]),
    );
  }
}
// ─── SHEET RECEPCIÓN DE ITEMS ─────────────────────────────────────────────────
class _RecepcionItemsSheet extends StatefulWidget {
  final PedidoModel  pedido;
  final VoidCallback onConfirmado;
  const _RecepcionItemsSheet({required this.pedido, required this.onConfirmado});
  @override State<_RecepcionItemsSheet> createState() => _RecepcionItemsSheetState();
}

class _RecepcionItemsSheetState extends State<_RecepcionItemsSheet> {
  late final List<_ItemRecepcion> _items;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _items = widget.pedido.items.map((i) => _ItemRecepcion(
      id:          i.id,
      descripcion: i.descripcion,
      tracking:    i.trackingExterno,
      tipo:        i.tipoProducto,
      peso:        i.peso,
      llego:       i.llego,
    )).toList();
  }

  Future<void> _marcarItem(int index, bool llego) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/pedidos/${widget.pedido.id}'
            '/items/${_items[index].id}/llegada'),
        headers: {'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'},
        body: jsonEncode({'llego': llego}),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() => _items[index].llego = llego);
      }
    } catch (_) {}
  }

  Future<void> _confirmar() async {
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/pedidos/${widget.pedido.id}'
            '/confirmar-recepcion'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context);
        widget.onConfirmado();
      } else {
        String msg = 'Error al confirmar';
        try { msg = jsonDecode(res.body)['message'] ?? msg; } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg), backgroundColor: const Color(0xFFC62828)));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sin conexión'), backgroundColor: Color(0xFFC62828)));
    }
    if (mounted) setState(() => _submitting = false);
  }

  int get _llegaron  => _items.where((i) => i.llego).length;
  int get _faltantes => _items.where((i) => !i.llego).length;

  @override
  Widget build(BuildContext context) {
    return _PedSheet(
      title: 'Verificar recepción',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // Info del pedido
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.inventory_2_outlined,
                color: Color(0xFF1A237E), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.pedido.numeroPedido,
                      style: const TextStyle(fontWeight: FontWeight.w800,
                          fontSize: 13, color: Color(0xFF1A1A2E))),
                  Text(widget.pedido.clienteNombreCompleto,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Resumen
        Row(children: [
          Expanded(child: _ResumenChip(
            icon: Icons.check_circle_outline,
            label: 'Llegaron',
            count: _llegaron,
            color: const Color(0xFF2E7D32),
          )),
          const SizedBox(width: 10),
          Expanded(child: _ResumenChip(
            icon: Icons.hourglass_empty_rounded,
            label: 'Faltantes',
            count: _faltantes,
            color: const Color(0xFFC62828),
          )),
          const SizedBox(width: 10),
          Expanded(child: _ResumenChip(
            icon: Icons.inventory_outlined,
            label: 'Total',
            count: _items.length,
            color: const Color(0xFF1A237E),
          )),
        ]),
        const SizedBox(height: 20),

        // Lista de items
        const _PedSectionTitle('Marcar items recibidos'),
        const SizedBox(height: 10),

        ..._items.asMap().entries.map((e) {
          final i   = e.key;
          final item = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                color: item.llego
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: item.llego
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFDE68A))),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                // Icono estado
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: (item.llego
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF59E0B)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                    item.llego
                        ? Icons.check_circle_outline
                        : Icons.hourglass_empty_rounded,
                    size: 18,
                    color: item.llego
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.descripcion, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
                  if (item.tracking != null)
                    Text(item.tracking!, style: const TextStyle(
                        fontSize: 10, color: Color(0xFF6B7280),
                        fontFamily: 'monospace')),
                  Row(children: [
                    if (item.tipo.isNotEmpty)
                      _MiniChip(item.tipo.replaceAll('_', ' ')),
                    if (item.peso != null) ...[
                      const SizedBox(width: 6),
                      _MiniChip('${item.peso!.toStringAsFixed(2)} lb'),
                    ],
                  ]),
                ])),
                const SizedBox(width: 8),
                // Toggle
                Column(children: [
                  GestureDetector(
                    onTap: () => _marcarItem(i, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: item.llego
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.check_rounded,
                          size: 16,
                          color: item.llego
                              ? Colors.white : const Color(0xFF9CA3AF)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _marcarItem(i, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: !item.llego
                              ? const Color(0xFFC62828)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close_rounded,
                          size: 16,
                          color: !item.llego
                              ? Colors.white : const Color(0xFF9CA3AF)),
                    ),
                  ),
                ]),
              ]),
            ),
          );
        }).toList(),

        const SizedBox(height: 20),

        // Aviso si hay faltantes
        if (_faltantes > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCC02))),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFE65100), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Faltan $_faltantes item${_faltantes == 1 ? '' : 's'}. '
                    'Se notificará al cliente para que decida si despachar '
                    'lo que llegó o esperar.',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFE65100)),
              )),
            ]),
          ),

        if (_llegaron == _items.length && _items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0))),
            child: const Row(children: [
              Icon(Icons.check_circle_outline,
                  color: Color(0xFF2E7D32), size: 18),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Todos los items llegaron. El pedido pasará a RECIBIDO EN SEDE.',
                style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
              )),
            ]),
          ),

        const SizedBox(height: 20),

        // Botón confirmar
        SizedBox(height: 50, child: ElevatedButton.icon(
          onPressed: _submitting ? null : _confirmar,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: _submitting
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.fact_check_outlined, size: 18),
          label: Text(
            _faltantes > 0
                ? 'Confirmar recepción parcial ($_llegaron/${ _items.length})'
                : 'Confirmar recepción completa',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        )),
      ]),
    );
  }
}

class _ItemRecepcion {
  final String  id;
  final String  descripcion;
  final String? tracking;
  final String  tipo;
  final double? peso;
  bool          llego;

  _ItemRecepcion({
    required this.id,
    required this.descripcion,
    this.tracking,
    required this.tipo,
    this.peso,
    required this.llego,
  });
}

class _ResumenChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      count;
  final Color    color;
  const _ResumenChip({required this.icon, required this.label,
    required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text('$count', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(
          fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: const TextStyle(
        fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
  );
}

// ─── SHEET VERIFICAR PAGO (ADMIN) ─────────────────────────────────────────────
class _VerificarPagoSheet extends StatefulWidget {
  final PedidoModel  pedido;
  final VoidCallback onVerificado;

  const _VerificarPagoSheet({
    required this.pedido,
    required this.onVerificado,
  });

  @override
  State<_VerificarPagoSheet> createState() => _VerificarPagoSheetState();
}

class _VerificarPagoSheetState extends State<_VerificarPagoSheet> {
  final _motivoCtrl  = TextEditingController();
  bool  _submitting  = false;
  bool  _loadingImg  = true;
  String? _base64    ;

  // Vista previa del comprobante — se carga desde el backend
  @override
  void initState() {
    super.initState();
    _cargarComprobante();
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  // ── Obtener el base64 del comprobante desde el endpoint específico ─────────
  Future<void> _cargarComprobante() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res   = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/pedidos/${widget.pedido.id}/comprobante'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _base64     = data['comprobanteBase64']?.toString();
          _loadingImg = false;
        });
      } else {
        if (mounted) setState(() => _loadingImg = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingImg = false);
    }
  }

  Future<void> _aprobar() async {
    setState(() => _submitting = true);
    context.read<PedidoBloc>().add(PedidoVerificarPago(
      widget.pedido.id,
      aprobado: true,
    ));
    if (mounted) {
      Navigator.pop(context);
      widget.onVerificado();
    }
  }

  Future<void> _rechazar() async {
    if (_motivoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresa el motivo del rechazo'),
        backgroundColor: Color(0xFFC62828),
      ));
      return;
    }
    setState(() => _submitting = true);
    context.read<PedidoBloc>().add(PedidoVerificarPago(
      widget.pedido.id,
      aprobado:      false,
      motivoRechazo: _motivoCtrl.text.trim(),
    ));
    if (mounted) {
      Navigator.pop(context);
      widget.onVerificado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p              = widget.pedido;
    final esTransferencia = p.formaPago == FormaPago.TRANSFERENCIA;

    return _PedSheet(
      title: 'Verificar pago',
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Info del pedido ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.numeroPedido,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14,
                                    color: Color(0xFF1A1A2E))),
                            Text(p.clienteNombreCompleto,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7280))),
                          ])),
                      // Badge forma de pago
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: esTransferencia
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            esTransferencia
                                ? Icons.account_balance_outlined
                                : Icons.payments_outlined,
                            size: 12,
                            color: esTransferencia
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 4),
                          Text(p.formaPago?.label ?? '',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: esTransferencia
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFE65100))),
                        ]),
                      ),
                    ]),

                    // Datos bancarios si aplica
                    if (p.bancoOrigen != null || p.numeroReferencia != null) ...[
                      const Divider(height: 16),
                      if (p.bancoOrigen != null)
                        _InfoFilaCompacta(
                            Icons.account_balance_outlined,
                            'Banco',
                            p.bancoOrigen!),
                      if (p.numeroReferencia != null)
                        _InfoFilaCompacta(
                            Icons.tag_rounded,
                            'Referencia',
                            p.numeroReferencia!),
                    ],

                    // Fecha subida comprobante
                    if (p.fechaSubidaComprobante != null) ...[
                      const Divider(height: 16),
                      _InfoFilaCompacta(
                          Icons.schedule_rounded,
                          'Subido el',
                          _fmtFecha(p.fechaSubidaComprobante!)),
                    ],
                  ]),
            ),
            const SizedBox(height: 20),

            // ── Comprobante ───────────────────────────────────────────────────
            _PedSectionTitle('Comprobante de pago'),
            const SizedBox(height: 12),

            Container(
              height: 260,
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB))),
              child: _loadingImg
                  ? const Center(child: CircularProgressIndicator(
                  color: Color(0xFF1A237E)))
                  : _base64 != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.memory(
                  base64Decode(_base64!),
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.image_not_supported_outlined,
                      size: 40, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 8),
                  Text('No se pudo cargar el comprobante',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Datos de facturación ──────────────────────────────────────────
            if (p.datosFacturacion != null) ...[
              _PedSectionTitle('Datos de facturación'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Column(children: [
                  if (p.datosFacturacion!.razonSocial != null)
                    _InfoFilaCompacta(Icons.person_outline_rounded,
                        'Razón social',
                        p.datosFacturacion!.razonSocial!),
                  if (p.datosFacturacion!.rucCedula != null)
                    _InfoFilaCompacta(Icons.badge_outlined,
                        'RUC / Cédula',
                        p.datosFacturacion!.rucCedula!),
                  if (p.datosFacturacion!.email != null)
                    _InfoFilaCompacta(Icons.email_outlined,
                        'Email',
                        p.datosFacturacion!.email!),
                  if (p.datosFacturacion!.direccion != null)
                    _InfoFilaCompacta(Icons.location_on_outlined,
                        'Dirección',
                        p.datosFacturacion!.direccion!),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // ── Sección de decisión ───────────────────────────────────────────
            _PedSectionTitle('Decisión'),
            const SizedBox(height: 12),

            // Campo motivo rechazo
            TextFormField(
              controller: _motivoCtrl,
              maxLines: 2,
              decoration: _pDeco(
                  'Motivo de rechazo (requerido solo si rechazas)'),
            ),
            const SizedBox(height: 16),

            // Botones aprobar / rechazar
            Row(children: [
              // Rechazar
              Expanded(child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : _rechazar,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(
                          color: Color(0xFFC62828), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: _submitting
                      ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Color(0xFFC62828), strokeWidth: 2))
                      : const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Rechazar',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              )),
              const SizedBox(width: 12),
              // Aprobar
              Expanded(child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _aprobar,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: _submitting
                      ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('Aprobar',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              )),
            ]),
            const SizedBox(height: 8),

            // Aviso
            const Text(
              'Al aprobar, el pago queda verificado y el pedido '
                  'continúa su flujo logístico normalmente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ]),
    );
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
}

// ─── Fila compacta de info ────────────────────────────────────────────────────
class _InfoFilaCompacta extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoFilaCompacta(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF9CA3AF))),
        Expanded(child: Text(value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF374151)))),
      ]),
    );
  }
}
// ─── WIDGETS PROPIOS DEL MÓDULO ───────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  final EstadoPedido estado;
  const _EstadoBadge({required this.estado});

  Color get _c => switch (estado) {
    EstadoPedido.REGISTRADO             => const Color(0xFF1A237E),
    EstadoPedido.RECIBIDO_EN_SEDE       => const Color(0xFF7B1FA2),
    EstadoPedido.EN_CONSOLIDACION       => const Color(0xFF6D4C41),
    EstadoPedido.EN_TRANSITO            => const Color(0xFFE65100),
    EstadoPedido.EN_ADUANA              => const Color(0xFFF57F17),
    EstadoPedido.RETENIDO_ADUANA        => const Color(0xFFB71C1C),
    EstadoPedido.LIBERADO_ADUANA        => const Color(0xFF00838F),
    EstadoPedido.RECIBIDO_EN_MATRIZ     => const Color(0xFF00695C),
    EstadoPedido.EN_DISTRIBUCION        => const Color(0xFF1565C0),
    EstadoPedido.DISPONIBLE_EN_SUCURSAL => const Color(0xFF2E7D32),
    EstadoPedido.ENTREGADO              => const Color(0xFF388E3C),
    EstadoPedido.DEVUELTO               => const Color(0xFF546E7A),
    EstadoPedido.EXTRAVIADO             => const Color(0xFFC62828),
    EstadoPedido.RECEPCION_PARCIAL      => const Color(0xFFF59E0B), // ← NUEVO
    EstadoPedido.ESPERANDO_ITEMS        => const Color(0xFF0288D1),
  };

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: _c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _c.withOpacity(0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: _c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(estado.label, style: TextStyle(
            color: _c, fontSize: 10, fontWeight: FontWeight.w700)),
      ]));
}

class _TipoBadge extends StatelessWidget {
  final TipoPedido tipo;
  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: tipo == TipoPedido.IMPORTACION
              ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC),
          borderRadius: BorderRadius.circular(6)),
      child: Text(tipo.label, style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: tipo == TipoPedido.IMPORTACION
              ? const Color(0xFF1565C0) : const Color(0xFFC62828))));
}

class _ProveedorBadge extends StatelessWidget {
  final String proveedor;
  const _ProveedorBadge({required this.proveedor});

  Color get _c {
    final p = proveedor.toLowerCase();
    if (p.contains('amazon')) return const Color(0xFFFF9900);
    if (p.contains('fedex'))  return const Color(0xFF4D148C);
    if (p.contains('ups'))    return const Color(0xFF351C15);
    if (p.contains('ebay'))   return const Color(0xFF3665F3);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: _c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _c.withOpacity(0.2))),
      child: Text(proveedor, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: _c)));
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(
        fontSize: 11, color: Color(0xFF6B7280))),
  ]);
}

class _PedBtn extends StatelessWidget {
  final IconData icon; final Color color;
  final String tip; final VoidCallback onTap;
  const _PedBtn({required this.icon, required this.color,
    required this.tip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(
      message: tip,
      child: Material(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Padding(padding: const EdgeInsets.all(7),
                  child: Icon(icon, color: color, size: 16)))));
}

class _ClienteDropdown extends StatelessWidget {
  final String?           value;
  final List<_ClienteRef> clientes;
  final void Function(String?) onChanged;
  const _ClienteDropdown({required this.value, required this.clientes,
    required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
              value: (value != null && clientes.any((c) => c.id == value))
                  ? value : null,
              hint: const Text('Seleccionar cliente',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF6B7280)),
              isExpanded: true,
              items: clientes.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.nombres} ${c.apellidos} [${c.casillero}]',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged)));
}

class _SucDropdown extends StatelessWidget {
  final String        hint;
  final String?       value, excluir;
  final List<_SucRef> sucursales;
  final void Function(String?) onChanged;
  const _SucDropdown({required this.hint, required this.value,
    required this.sucursales, required this.onChanged, this.excluir});

  @override
  Widget build(BuildContext context) {
    final items = sucursales.where((s) => s.id != excluir).toList();
    final cur   = (value != null && items.any((s) => s.id == value))
        ? value : null;
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
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6B7280)),
                isExpanded: true,
                items: items.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.nombre} (${s.pais})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: onChanged)));
  }
}

class _ClienteRef {
  final String id, nombres, apellidos, casillero;
  const _ClienteRef({required this.id, required this.nombres,
    required this.apellidos, required this.casillero});
}

class _SucRef {
  final String id, nombre, pais;
  const _SucRef({required this.id, required this.nombre, required this.pais});
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS BASE
// ═════════════════════════════════════════════════════════════════════════════

class _PedSectionTitle extends StatelessWidget {
  final String text; const _PedSectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 3, height: 14,
            decoration: BoxDecoration(color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700,
            fontSize: 13, color: Color(0xFF374151))),
      ]));
}

class _PedDetailRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _PedDetailRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              fontSize: 10, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(
              fontSize: 14, color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500)),
        ])),
      ]));
}

class _PedSheet extends StatelessWidget {
  final String title; final Widget child;
  const _PedSheet({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        Flexible(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: Text(title, style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E)))),
                  IconButton(icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 18),
                child,
              ]),
        )),
      ]));
}

class _PedLabel extends StatelessWidget {
  final String text; const _PedLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: Color(0xFF374151)));
}

class _PedSubmitBtn extends StatelessWidget {
  final String label; final VoidCallback onTap; final Color color;
  const _PedSubmitBtn({required this.label, required this.onTap,
    this.color = const Color(0xFF1A237E)});
  @override
  Widget build(BuildContext context) => SizedBox(height: 50,
      child: ElevatedButton(onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: color,
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: Text(label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600))));
}

class _PedSearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint; final void Function(String) onChanged;
  const _PedSearchField({required this.ctrl, required this.hint,
    required this.onChanged});

  OutlineInputBorder _b({Color? c, double w = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c ?? const Color(0xFFE5E7EB), width: w));

  @override
  Widget build(BuildContext context) => TextField(
      controller: ctrl, onChanged: onChanged,
      decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF9CA3AF), size: 20),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded,
              color: Color(0xFF9CA3AF), size: 18),
              onPressed: () { ctrl.clear(); onChanged(''); }) : null,
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 16),
          border: _b(), enabledBorder: _b(),
          focusedBorder: _b(c: const Color(0xFF1A237E), w: 2)));
}

class _EstadoPagoBanner extends StatelessWidget {
  final EstadoPago estadoPago;
  final String?    motivoRechazo;

  const _EstadoPagoBanner({
    required this.estadoPago,
    this.motivoRechazo,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon, texto) = switch (estadoPago) {
      EstadoPago.PENDIENTE_COMPROBANTE => (
      const Color(0xFFE65100),
      const Color(0xFFFFF3E0),
      Icons.hourglass_empty_rounded,
      'Pendiente: sube tu comprobante de pago',
      ),
      EstadoPago.COMPROBANTE_ENVIADO => (
      const Color(0xFF1565C0),
      const Color(0xFFE3F2FD),
      Icons.schedule_rounded,
      'Comprobante enviado, esperando verificación del equipo',
      ),
      EstadoPago.PAGO_VERIFICADO => (
      const Color(0xFF2E7D32),
      const Color(0xFFF0FDF4),
      Icons.verified_rounded,
      'Pago verificado y aprobado ✓',
      ),
      EstadoPago.PAGO_RECHAZADO => (
      const Color(0xFFC62828),
      const Color(0xFFFFEBEE),
      Icons.cancel_outlined,
      motivoRechazo != null
          ? 'Comprobante rechazado: $motivoRechazo'
          : 'Comprobante rechazado. Sube uno nuevo.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(texto,
            style: TextStyle(
                fontSize: 12, color: color,
                fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

class _PedEmptyView extends StatelessWidget {
  final bool hasFilter; const _PedEmptyView({required this.hasFilter});
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
        Text(hasFilter ? 'Sin resultados' : 'No hay pedidos',
            style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Text(hasFilter
            ? 'Intenta con otro término o filtro'
            : 'Crea el primer pedido con "Nuevo pedido"',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center),
      ])));
}

class _PedErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _PedErrorView({required this.message, required this.onRetry});
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
      ])));
}

InputDecoration _pDeco(String hint, {Widget? suf}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
    suffixIcon: suf, filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    border:             _pib(),
    enabledBorder:      _pib(),
    focusedBorder:      _pib(c: const Color(0xFF1A237E), w: 2),
    errorBorder:        _pib(c: const Color(0xFFC62828)),
    focusedErrorBorder: _pib(c: const Color(0xFFC62828), w: 2));

OutlineInputBorder _pib({Color? c, double w = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c ?? const Color(0xFFE5E7EB), width: w));

