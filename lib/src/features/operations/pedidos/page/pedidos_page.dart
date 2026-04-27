// lib/src/features/pedidos/presentation/pages/pedidos_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../../../core/constants/api_constants.dart';
import '../domain/model/pedido_model.dart';
import '../bloc/pedido_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
class PedidosPage extends StatelessWidget {
  const PedidosPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => di.sl<PedidoBloc>()..add(PedidoLoadAll()),
    child: const _PedidosView(),
  );
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

  void _doSearch(BuildContext ctx, String v) {
    setState(() { _q = v; _buscando = v.trim().length >= 3; });
    if (_buscando) {
      ctx.read<PedidoBloc>().add(PedidoBuscar(v));
    } else if (v.isEmpty) {
      ctx.read<PedidoBloc>().add(PedidoLoadAll());
    }
  }

  // ── Sheets ────────────────────────────────────────────────────────────────
  void _openCreate(BuildContext ctx) => _showSheet(ctx,
      child: BlocProvider.value(
          value: ctx.read<PedidoBloc>(),
          child: const _PedidoFormSheet()));

  void _openEdit(BuildContext ctx, PedidoModel p) => _showSheet(ctx,
      child: BlocProvider.value(
          value: ctx.read<PedidoBloc>(),
          child: _PedidoFormSheet(pedido: p)));

  void _openDetail(BuildContext ctx, PedidoModel p) => _showSheet(ctx,
      child: BlocProvider.value(
          value: ctx.read<PedidoBloc>(),
          child: _PedidoDetailSheet(
            pedido: p,
            onEdit:      () { Navigator.pop(ctx); _openEdit(ctx, p); },
            onEstado:    () { Navigator.pop(ctx); _openEstado(ctx, p); },
            onRecepcion: () { Navigator.pop(ctx); _openRecepcion(ctx, p); },
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
  const _PedHeader({required this.total, required this.onAdd,
    required this.onRefresh});

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
  final VoidCallback onEdit, onEstado, onRecepcion;
  const _PedidoDetailSheet(
      {required this.pedido, required this.onEdit,
        required this.onEstado, required this.onRecepcion});

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

// ─── SHEET FORMULARIO ─────────────────────────────────────────────────────────
class _PedidoFormSheet extends StatefulWidget {
  final PedidoModel? pedido;
  const _PedidoFormSheet({this.pedido});
  @override
  State<_PedidoFormSheet> createState() => _PedidoFormSheetState();
}

class _PedidoFormSheetState extends State<_PedidoFormSheet> {
  final _key = GlobalKey<FormState>();

  // Refs externos
  List<_ClienteRef>  _clientes   = [];
  List<_SucRef>      _sucursales = [];
  bool               _loadingRefs = true;

  String?    _clienteId;
  String?    _origenId;
  String?    _destinoId;
  TipoPedido _tipo = TipoPedido.IMPORTACION;

  late final TextEditingController _tracking   = TextEditingController();
  late final TextEditingController _proveedor  = TextEditingController();
  late final TextEditingController _urlT       = TextEditingController();
  late final TextEditingController _desc       = TextEditingController();
  late final TextEditingController _peso       = TextEditingController();
  late final TextEditingController _largo      = TextEditingController();
  late final TextEditingController _ancho      = TextEditingController();
  late final TextEditingController _alto       = TextEditingController();
  late final TextEditingController _valor      = TextEditingController();
  late final TextEditingController _cantidad   = TextEditingController();
  late final TextEditingController _obs        = TextEditingController();
  late final TextEditingController _notasInt   = TextEditingController();
  late final TextEditingController _fotoUrl    = TextEditingController();

  bool get _isEdit => widget.pedido != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p     = widget.pedido!;
      _clienteId  = p.clienteId;
      _origenId   = p.sucursalOrigenId;
      _destinoId  = p.sucursalDestinoId;
      _tipo       = p.tipo;
      _tracking.text  = p.trackingExterno  ?? '';
      _proveedor.text = p.proveedor        ?? '';
      _urlT.text      = p.urlTracking      ?? '';
      _desc.text      = p.descripcion;
      _peso.text      = p.peso?.toString() ?? '';
      _largo.text     = p.largo?.toString() ?? '';
      _ancho.text     = p.ancho?.toString() ?? '';
      _alto.text      = p.alto?.toString()  ?? '';
      _valor.text     = p.valorDeclarado?.toString() ?? '';
      _cantidad.text  = p.cantidadItems?.toString()  ?? '';
      _obs.text       = p.observaciones    ?? '';
      _notasInt.text  = p.notasInternas    ?? '';
      _fotoUrl.text   = p.fotoUrl          ?? '';
    }
    _fetchRefs();
  }

  Future<void> _fetchRefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final h = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
      final base = ApiConstants.baseUrl;

      final results = await Future.wait([
        http.get(Uri.parse('$base/api/sucursales'), headers: h),
        http.get(Uri.parse('$base/api/clientes'), headers: h),
      ]);

      if (!mounted) return;
      final sucRes = results[0];
      final cliRes = results[1];

      if (sucRes.statusCode == 200) {
        final list = jsonDecode(utf8.decode(sucRes.bodyBytes)) as List;
        _sucursales = list.map((e) => _SucRef(
            id:     e['id'].toString(),
            nombre: e['nombre'].toString(),
            pais:   e['pais'].toString())).toList();
      }
      if (cliRes.statusCode == 200) {
        final list = jsonDecode(utf8.decode(cliRes.bodyBytes)) as List;
        _clientes = list.map((e) => _ClienteRef(
            id:        e['id'].toString(),
            nombres:   e['nombres']?.toString() ?? '',
            apellidos: e['apellidos']?.toString() ?? '',
            casillero: e['casillero']?.toString() ?? '')).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingRefs = false);
  }

  @override
  void dispose() {
    for (final c in [_tracking, _proveedor, _urlT, _desc, _peso,
      _largo, _ancho, _alto, _valor, _cantidad, _obs, _notasInt,
      _fotoUrl]) { c.dispose(); }
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    if (_clienteId == null) {
      _err('Selecciona un cliente'); return;
    }
    if (_origenId == null || _destinoId == null) {
      _err('Selecciona sucursal origen y destino'); return;
    }
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
      'fotoUrl':           _fotoUrl.text.trim(),
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
            padding: EdgeInsets.only(right: t == TipoPedido.IMPORTACION ? 8 : 0),
            child: GestureDetector(
                onTap: () => setState(() => _tipo = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFFE8EAF6) : Colors.white,
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
      const SizedBox(height: 16),

      // ── Cliente ───────────────────────────────────────────────────────
      _PedLabel('Cliente *'),
      const SizedBox(height: 8),
      _loadingRefs
          ? const Center(child: Padding(padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: Color(0xFF1A237E))))
          : _ClienteDropdown(
          value: _clienteId,
          clientes: _clientes,
          onChanged: (v) => setState(() => _clienteId = v)),
      const SizedBox(height: 14),

      // ── Tracking externo ──────────────────────────────────────────────
      _PedLabel('Tracking externo'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(controller: _tracking,
            decoration: _pDeco('Ej: TBA123456789'))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PedLabel('Proveedor'),
              const SizedBox(height: 0),
              TextFormField(controller: _proveedor,
                  decoration: _pDeco('Amazon, FedEx...')),
            ])),
      ]),
      const SizedBox(height: 14),

      // ── Descripción ───────────────────────────────────────────────────
      _PedLabel('Descripción del contenido *'),
      const SizedBox(height: 8),
      TextFormField(
          controller: _desc, maxLines: 2,
          decoration: _pDeco('Ej: Laptop Dell XPS 15'),
          validator: (v) =>
          v == null || v.trim().isEmpty ? 'Campo requerido' : null),
      const SizedBox(height: 14),

      // ── Peso, largo, ancho, alto ──────────────────────────────────────
      _PedLabel('Dimensiones y peso'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(controller: _peso,
            keyboardType: TextInputType.number,
            decoration: _pDeco('Peso (lb)'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(controller: _largo,
            keyboardType: TextInputType.number,
            decoration: _pDeco('Largo (cm)'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(controller: _ancho,
            keyboardType: TextInputType.number,
            decoration: _pDeco('Ancho (cm)'))),
        const SizedBox(width: 8),
        Expanded(child: TextFormField(controller: _alto,
            keyboardType: TextInputType.number,
            decoration: _pDeco('Alto (cm)'))),
      ]),
      const SizedBox(height: 14),

      // ── Valor declarado y cantidad ────────────────────────────────────
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
      const SizedBox(height: 14),

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
      const SizedBox(height: 14),

      // ── Observaciones ─────────────────────────────────────────────────
      _PedLabel('Observaciones'),
      const SizedBox(height: 8),
      TextFormField(controller: _obs, maxLines: 2,
          decoration: _pDeco('Notas generales sobre el pedido...')),
      const SizedBox(height: 14),

      // ── Notas internas ────────────────────────────────────────────────
      _PedLabel('Notas internas (solo empleados)'),
      const SizedBox(height: 8),
      TextFormField(controller: _notasInt, maxLines: 2,
          decoration: _pDeco('Notas solo para el equipo...')),
      const SizedBox(height: 24),

      _PedSubmitBtn(
          label: _isEdit ? 'Guardar cambios' : 'Crear pedido',
          onTap: _submit),
    ])),
  );
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

