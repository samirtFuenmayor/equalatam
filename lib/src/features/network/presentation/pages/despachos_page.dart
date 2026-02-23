// lib/src/features/despachos/presentation/pages/hubs.page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../../../core/constants/api_constants.dart';
import '../domain/models/despacho_model.dart';
import '../bloc/despacho_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
class DespachosPage extends StatelessWidget {
  const DespachosPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => di.sl<DespachoBloc>()..add(DespachoLoadAll()),
    child: const _DespachosView(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class _DespachosView extends StatefulWidget {
  const _DespachosView();
  @override
  State<_DespachosView> createState() => _DespachosViewState();
}

class _DespachosViewState extends State<_DespachosView> {
  final _searchCtrl = TextEditingController();
  String          _q           = '';
  EstadoDespacho? _filtroEstado;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<DespachoModel> _filter(List<DespachoModel> src) => src.where((d) {
    final q   = _q.toLowerCase();
    final okQ = _q.isEmpty ||
        d.numeroDespacho.toLowerCase().contains(q) ||
        d.sucursalOrigenNombre.toLowerCase().contains(q) ||
        d.sucursalDestinoNombre.toLowerCase().contains(q) ||
        (d.aerolinea?.toLowerCase().contains(q) ?? false) ||
        (d.numeroVuelo?.toLowerCase().contains(q) ?? false);
    final okE = _filtroEstado == null || d.estado == _filtroEstado;
    return okQ && okE;
  }).toList();

  void _openCreate(BuildContext ctx) => showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
          value: ctx.read<DespachoBloc>(),
          child: const _DespachoFormSheet()));

  void _openDetail(BuildContext ctx, DespachoModel d) =>
      showModalBottomSheet(
          context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(
              value: ctx.read<DespachoBloc>(),
              child: _DespachoDetailSheet(
                despacho: d,
                onEditTransporte: () {
                  Navigator.pop(ctx);
                  _openTransporte(ctx, d);
                },
                onCambiarEstado: () {
                  Navigator.pop(ctx);
                  _openCambioEstado(ctx, d);
                },
              )));

  void _openTransporte(BuildContext ctx, DespachoModel d) =>
      showModalBottomSheet(
          context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(
              value: ctx.read<DespachoBloc>(),
              child: _DespachoFormSheet(despacho: d)));

  void _openCambioEstado(BuildContext ctx, DespachoModel d) =>
      showModalBottomSheet(
          context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(
              value: ctx.read<DespachoBloc>(),
              child: _CambioEstadoSheet(despacho: d)));

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
        backgroundColor:
        ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: ok ? 3 : 5),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return BlocConsumer<DespachoBloc, DespachoState>(
      listener: (ctx, state) {
        if (state is DespachoLoaded && state.message != null)
          _snack(ctx, state.message!, ok: true);
        if (state is DespachoError) _snack(ctx, state.message, ok: false);
      },
      builder: (ctx, state) {
        final all = switch (state) {
          DespachoLoaded s => s.despachos,
          DespachoError s  => s.despachos,
          _                => <DespachoModel>[],
        };
        final filtered = _filter(all);
        final loading  = state is DespachoLoading;
        final errOnly  = state is DespachoError && all.isEmpty;

        final abiertos   = all.where((d) => d.estado == EstadoDespacho.ABIERTO).length;
        final enTransito = all.where((d) => d.estado == EstadoDespacho.EN_TRANSITO).length;
        final recibidos  = all.where((d) => d.estado == EstadoDespacho.RECIBIDO).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            _DesHeader(
              total: all.length,
              onAdd:     () => _openCreate(ctx),
              onRefresh: () => ctx.read<DespachoBloc>().add(DespachoLoadAll()),
            ),
            if (all.isNotEmpty)
              _DesStatsRow(
                  abiertos: abiertos,
                  enTransito: enTransito,
                  recibidos: recibidos),
            _DesFilterBar(
              searchCtrl:   _searchCtrl,
              filtroEstado: _filtroEstado,
              onSearch: (v) => setState(() => _q = v),
              onEstado: (e) => setState(() => _filtroEstado = e),
            ),
            Expanded(child: _body(
                ctx, state, filtered, loading, errOnly, isDesktop)),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext ctx, DespachoState state,
      List<DespachoModel> filtered, bool loading, bool errOnly,
      bool isDesktop) {
    if (loading) return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    if (errOnly) return _DesErrorView(
        message: (state as DespachoError).message,
        onRetry: () => ctx.read<DespachoBloc>().add(DespachoLoadAll()));
    if (filtered.isEmpty) return _DesEmptyView(
        hasFilter: _q.isNotEmpty || _filtroEstado != null);

    return isDesktop
        ? _DespachosTable(
        despachos: filtered,
        onDetail:  (d) => _openDetail(ctx, d),
        onTransp:  (d) => _openTransporte(ctx, d),
        onEstado:  (d) => _openCambioEstado(ctx, d))
        : _DespachosCards(
        despachos: filtered,
        onDetail:  (d) => _openDetail(ctx, d),
        onTransp:  (d) => _openTransporte(ctx, d),
        onEstado:  (d) => _openCambioEstado(ctx, d));
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _DesHeader extends StatelessWidget {
  final int total;
  final VoidCallback onAdd, onRefresh;
  const _DesHeader(
      {required this.total, required this.onAdd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(children: [
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gestión de Despachos',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Text(
                  '$total despacho${total == 1 ? '' : 's'} registrado${total == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280))),
            ])),
        IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
            onPressed: onRefresh,
            tooltip: 'Actualizar'),
        const SizedBox(width: 6),
        SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 16 : 12)),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(isWide ? 'Nuevo despacho' : 'Nuevo',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            )),
      ]),
    );
  }
}

// ─── STATS ────────────────────────────────────────────────────────────────────
class _DesStatsRow extends StatelessWidget {
  final int abiertos, enTransito, recibidos;
  const _DesStatsRow(
      {required this.abiertos,
        required this.enTransito,
        required this.recibidos});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
    child: Row(children: [
      _StatCard(value: abiertos, label: 'Abiertos',
          color: const Color(0xFF1A237E),
          icon: Icons.inventory_2_outlined),
      const SizedBox(width: 10),
      _StatCard(value: enTransito, label: 'En tránsito',
          color: const Color(0xFFE65100),
          icon: Icons.flight_takeoff_rounded),
      const SizedBox(width: 10),
      _StatCard(value: recibidos, label: 'Recibidos',
          color: const Color(0xFF2E7D32),
          icon: Icons.flight_land_rounded),
    ]),
  );
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.value,
        required this.label,
        required this.color,
        required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF6B7280))),
        ]),
      ]),
    ),
  );
}

// ─── FILTROS ──────────────────────────────────────────────────────────────────
class _DesFilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final EstadoDespacho?       filtroEstado;
  final void Function(String)        onSearch;
  final void Function(EstadoDespacho?) onEstado;
  const _DesFilterBar(
      {required this.searchCtrl,
        required this.filtroEstado,
        required this.onSearch,
        required this.onEstado});

  Color _ec(EstadoDespacho e) => switch (e) {
    EstadoDespacho.ABIERTO     => const Color(0xFF1A237E),
    EstadoDespacho.CERRADO     => const Color(0xFF7B1FA2),
    EstadoDespacho.EN_TRANSITO => const Color(0xFFE65100),
    EstadoDespacho.RECIBIDO    => const Color(0xFF2E7D32),
    EstadoDespacho.PROCESADO   => const Color(0xFF546E7A),
    EstadoDespacho.CANCELADO   => const Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final search = _DesSearchField(
        ctrl: searchCtrl,
        hint: 'Buscar por número, ruta, aerolínea...',
        onChanged: onSearch);
    final drop = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EstadoDespacho?>(
          value: filtroEstado,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280)),
          items: [
            const DropdownMenuItem(
                value: null,
                child: Text('Todos los estados',
                    style: TextStyle(fontSize: 13))),
            ...EstadoDespacho.values.map((e) => DropdownMenuItem(
              value: e,
              child: Row(children: [
                Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: _ec(e), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(e.label,
                    style: const TextStyle(fontSize: 13)),
              ]),
            )),
          ],
          onChanged: onEstado,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: isWide
          ? Row(children: [
        Expanded(child: search),
        const SizedBox(width: 10),
        drop
      ])
          : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [search, const SizedBox(height: 10), drop]),
    );
  }
}

// ─── TABLA DESKTOP ────────────────────────────────────────────────────────────
class _DespachosTable extends StatelessWidget {
  final List<DespachoModel>          despachos;
  final void Function(DespachoModel) onDetail, onTransp, onEstado;
  const _DespachosTable(
      {required this.despachos,
        required this.onDetail,
        required this.onTransp,
        required this.onEstado});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.8),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(2.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1),
              5: FixedColumnWidth(130),
            },
            children: [
              TableRow(
                  decoration:
                  const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    'Nº Despacho',
                    'Estado',
                    'Ruta',
                    'Transporte',
                    'Pedidos',
                    'Acciones'
                  ]
                      .map((h) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: Text(h,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280))),
                  ))
                      .toList()),
              ...despachos.map((d) => TableRow(
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: Color(0xFFE5E7EB)))),
                  children: [
                    // Número
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.numeroDespacho,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                      color: Color(0xFF1A1A2E))),
                              if (d.creadoPor != null)
                                Text(d.creadoPor!,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9CA3AF))),
                            ])),
                    // Estado
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: _EstadoBadge(estado: d.estado)),
                    // Ruta
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RutaRow(
                                  icon: Icons.flight_takeoff_rounded,
                                  nombre: d.sucursalOrigenNombre,
                                  pais: d.sucursalOrigenPais),
                              const SizedBox(height: 4),
                              _RutaRow(
                                  icon: Icons.flight_land_rounded,
                                  nombre: d.sucursalDestinoNombre,
                                  pais: d.sucursalDestinoPais),
                            ])),
                    // Transporte
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (d.tipoTransporte != null)
                                _TransporteBadge(tipo: d.tipoTransporte!),
                              if (d.numeroVuelo != null) ...[
                                const SizedBox(height: 4),
                                Text(d.numeroVuelo!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280))),
                              ],
                            ])),
                    // Pedidos
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8EAF6),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('${d.totalPedidos}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF1A237E))),
                        )),
                    // Acciones
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(children: [
                          _DesBtn(
                              icon: Icons.visibility_outlined,
                              color: const Color(0xFF1A237E),
                              tip: 'Ver detalle',
                              onTap: () => onDetail(d)),
                          const SizedBox(width: 4),
                          _DesBtn(
                              icon: Icons.local_shipping_outlined,
                              color: const Color(0xFF7B1FA2),
                              tip: 'Editar transporte',
                              onTap: () => onTransp(d)),
                          const SizedBox(width: 4),
                          if (d.estado.transicionesValidas.isNotEmpty)
                            _DesBtn(
                                icon: Icons.swap_horiz_rounded,
                                color: const Color(0xFFE65100),
                                tip: 'Cambiar estado',
                                onTap: () => onEstado(d)),
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
class _DespachosCards extends StatelessWidget {
  final List<DespachoModel>          despachos;
  final void Function(DespachoModel) onDetail, onTransp, onEstado;
  const _DespachosCards(
      {required this.despachos,
        required this.onDetail,
        required this.onTransp,
        required this.onEstado});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    itemCount: despachos.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _DesCard(
      d: despachos[i],
      onDetail: () => onDetail(despachos[i]),
      onTransp: () => onTransp(despachos[i]),
      onEstado: () => onEstado(despachos[i]),
    ),
  );
}

class _DesCard extends StatelessWidget {
  final DespachoModel d;
  final VoidCallback  onDetail, onTransp, onEstado;
  const _DesCard(
      {required this.d,
        required this.onDetail,
        required this.onTransp,
        required this.onEstado});

  String _fmtShort(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabecera
        Row(children: [
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.numeroDespacho,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            fontFamily: 'monospace',
                            color: Color(0xFF1A1A2E))),
                    if (d.creadoPor != null)
                      Text('Por: ${d.creadoPor}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF))),
                  ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: Color(0xFF9CA3AF), size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              _popItem('detail', Icons.visibility_outlined,
                  'Ver detalle', const Color(0xFF1A237E)),
              _popItem('transporte', Icons.local_shipping_outlined,
                  'Editar transporte', const Color(0xFF7B1FA2)),
              if (d.estado.transicionesValidas.isNotEmpty)
                _popItem('estado', Icons.swap_horiz_rounded,
                    'Cambiar estado', const Color(0xFFE65100)),
            ],
            onSelected: (v) {
              if (v == 'detail')     onDetail();
              if (v == 'transporte') onTransp();
              if (v == 'estado')     onEstado();
            },
          ),
        ]),
        const SizedBox(height: 12),
        // Ruta visual
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              _RutaRow(
                  icon: Icons.flight_takeoff_rounded,
                  nombre: d.sucursalOrigenNombre,
                  pais: d.sucursalOrigenPais),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    const SizedBox(width: 6),
                    Container(width: 2, height: 12,
                        color: const Color(0xFFE5E7EB)),
                  ])),
              _RutaRow(
                  icon: Icons.flight_land_rounded,
                  nombre: d.sucursalDestinoNombre,
                  pais: d.sucursalDestinoPais),
            ])),
        const SizedBox(height: 10),
        // Badges
        Wrap(spacing: 6, runSpacing: 6, children: [
          _EstadoBadge(estado: d.estado),
          if (d.tipoTransporte != null)
            _TransporteBadge(tipo: d.tipoTransporte!),
          _CountBadge(count: d.totalPedidos, label: 'paquete'),
        ]),
        if (d.fechaSalidaProgramada != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule_rounded,
                size: 12, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text('Salida: ${_fmtShort(d.fechaSalidaProgramada!)}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280))),
          ]),
        ],
        const SizedBox(height: 12),
        // Botón ver detalle
        SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                onPressed: onDetail,
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                    side: const BorderSide(color: Color(0xFFC5CAE9)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Ver detalle',
                    style: TextStyle(fontSize: 13)))),
      ]),
    );
  }

  PopupMenuItem<String> _popItem(
      String v, IconData icon, String label, Color c) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 10),
            Text(label)
          ]));
}

// ─── SHEET DETALLE ────────────────────────────────────────────────────────────
class _DespachoDetailSheet extends StatelessWidget {
  final DespachoModel despacho;
  final VoidCallback  onEditTransporte, onCambiarEstado;
  const _DespachoDetailSheet(
      {required this.despacho,
        required this.onEditTransporte,
        required this.onCambiarEstado});

  String _fmtFull(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final d = despacho;
    return _DesSheet(
      title: d.numeroDespacho,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Badges superiores
        Wrap(spacing: 8, runSpacing: 8, children: [
          _EstadoBadge(estado: d.estado),
          if (d.tipoTransporte != null)
            _TransporteBadge(tipo: d.tipoTransporte!),
          _CountBadge(count: d.totalPedidos, label: 'paquete'),
        ]),
        const SizedBox(height: 20),

        // Ruta
        _DesSectionTitle('Ruta'),
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.flight_takeoff_rounded,
                    size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Origen',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF9CA3AF))),
                      Text(d.sucursalOrigenNombre,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      Text(d.sucursalOrigenPais,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                    ]),
              ]),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1)),
              Row(children: [
                const Icon(Icons.flight_land_rounded,
                    size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Destino',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF9CA3AF))),
                      Text(d.sucursalDestinoNombre,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      Text(d.sucursalDestinoPais,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                    ]),
              ]),
            ])),
        const SizedBox(height: 16),

        // Transporte
        _DesSectionTitle('Información de transporte'),
        _DesDetailRow(Icons.airplanemode_active_outlined,
            'Aerolínea', d.aerolinea ?? '—'),
        _DesDetailRow(Icons.confirmation_number_outlined,
            'Nº Vuelo', d.numeroVuelo ?? '—'),
        _DesDetailRow(Icons.article_outlined,
            'Guía aérea', d.guiaAerea ?? '—'),
        if (d.numeroContenedor != null && d.numeroContenedor!.isNotEmpty)
          _DesDetailRow(Icons.inventory_2_outlined,
              'Contenedor', d.numeroContenedor!),
        const SizedBox(height: 16),

        // Fechas
        _DesSectionTitle('Fechas'),
        if (d.fechaSalidaProgramada != null)
          _DesDetailRow(Icons.schedule_rounded, 'Salida programada',
              _fmtFull(d.fechaSalidaProgramada!)),
        if (d.fechaSalidaReal != null)
          _DesDetailRow(Icons.check_circle_outline, 'Salida real',
              _fmtFull(d.fechaSalidaReal!)),
        if (d.fechaLlegadaProgramada != null)
          _DesDetailRow(Icons.schedule_outlined, 'Llegada programada',
              _fmtFull(d.fechaLlegadaProgramada!)),
        if (d.fechaLlegadaReal != null)
          _DesDetailRow(Icons.check_circle_rounded, 'Llegada real',
              _fmtFull(d.fechaLlegadaReal!)),
        const SizedBox(height: 16),

        // Totales
        _DesSectionTitle('Totales'),
        Row(children: [
          _TotalCard('${d.totalPedidos}', 'Pedidos',
              Icons.inventory_outlined),
          const SizedBox(width: 10),
          _TotalCard('${d.pesoTotal.toStringAsFixed(2)} kg', 'Peso',
              Icons.scale_outlined),
          const SizedBox(width: 10),
          _TotalCard('\$${d.valorTotalDeclarado.toStringAsFixed(2)}',
              'Declarado', Icons.attach_money_rounded),
        ]),

        // Observaciones
        if (d.observaciones != null && d.observaciones!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _DesSectionTitle('Observaciones'),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFFDE7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFF176))),
              child: Text(d.observaciones!,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF374151)))),
        ],

        // Pedidos incluidos
        if (d.pedidos.isNotEmpty) ...[
          const SizedBox(height: 16),
          _DesSectionTitle('Pedidos incluidos (${d.pedidos.length})'),
          ...d.pedidos.map((p) => _PedidoItem(pedido: p)),
        ],

        const SizedBox(height: 20),

        // Botones acción
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: onEditTransporte,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7B1FA2),
                      side: const BorderSide(color: Color(0xFFCE93D8)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar transporte'))),
          if (d.estado.transicionesValidas.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: onCambiarEstado,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Cambiar estado'))),
          ],
        ]),
      ]),
    );
  }
}

class _PedidoItem extends StatelessWidget {
  final DetallePedidoModel pedido;
  const _PedidoItem({required this.pedido});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Row(children: [
      Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.inventory_2_outlined,
              size: 16, color: Color(0xFF1A237E))),
      const SizedBox(width: 12),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pedido.numeroPedido,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1A1A2E))),
            Text(pedido.clienteNombre,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280))),
            Text(pedido.clienteCasillero,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF9CA3AF))),
          ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (pedido.peso != null)
          Text('${pedido.peso!.toStringAsFixed(2)} kg',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7280))),
        Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8)),
            child: Text(pedido.estadoPedido,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32)))),
      ]),
    ]),
  );
}

// ─── SHEET FORMULARIO (CREAR / EDITAR TRANSPORTE) ─────────────────────────────
class _DespachoFormSheet extends StatefulWidget {
  final DespachoModel? despacho;
  const _DespachoFormSheet({this.despacho});
  @override
  State<_DespachoFormSheet> createState() => _DespachoFormSheetState();
}

class _DespachoFormSheetState extends State<_DespachoFormSheet> {
  final _key = GlobalKey<FormState>();

  // Sucursales cargadas desde /api/sucursales
  List<_SucRef> _sucursales = [];
  bool          _loadingSuc = true;
  String?       _origenId;
  String?       _destinoId;
  String        _tipoTransporte = 'AEREO';

  late final TextEditingController _aerolinea  = TextEditingController();
  late final TextEditingController _numVuelo   = TextEditingController();
  late final TextEditingController _guiaAerea  = TextEditingController();
  late final TextEditingController _contenedor = TextEditingController();
  late final TextEditingController _salida     = TextEditingController();
  late final TextEditingController _llegada    = TextEditingController();
  late final TextEditingController _obs        = TextEditingController();

  bool get _isEdit => widget.despacho != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.despacho!;
      _origenId        = d.sucursalOrigenId;
      _destinoId       = d.sucursalDestinoId;
      _aerolinea.text  = d.aerolinea         ?? '';
      _numVuelo.text   = d.numeroVuelo        ?? '';
      _guiaAerea.text  = d.guiaAerea          ?? '';
      _contenedor.text = d.numeroContenedor   ?? '';
      _tipoTransporte  = d.tipoTransporte     ?? 'AEREO';
      _obs.text        = d.observaciones      ?? '';
      if (d.fechaSalidaProgramada  != null) _salida.text  = _iso(d.fechaSalidaProgramada!);
      if (d.fechaLlegadaProgramada != null) _llegada.text = _iso(d.fechaLlegadaProgramada!);
    }
    _fetchSucursales();
  }

  Future<void> _fetchSucursales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res   = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/sucursales'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          });
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        if (mounted) setState(() {
          _sucursales = list.map((e) => _SucRef(
              id:     e['id'].toString(),
              nombre: e['nombre'].toString(),
              pais:   e['pais'].toString())).toList();
          _loadingSuc = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingSuc = false);
  }

  @override
  void dispose() {
    _aerolinea.dispose(); _numVuelo.dispose(); _guiaAerea.dispose();
    _contenedor.dispose(); _salida.dispose(); _llegada.dispose();
    _obs.dispose(); super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    if (_origenId == null || _destinoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona sucursal origen y destino'),
          backgroundColor: Color(0xFFC62828)));
      return;
    }
    if (_origenId == _destinoId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Origen y destino no pueden ser iguales'),
          backgroundColor: Color(0xFFC62828)));
      return;
    }

    final data = <String, dynamic>{
      'sucursalOrigenId':      _origenId,
      'sucursalDestinoId':     _destinoId,
      'aerolinea':             _aerolinea.text.trim(),
      'numeroVuelo':           _numVuelo.text.trim(),
      'guiaAerea':             _guiaAerea.text.trim(),
      'numeroContenedor':      _contenedor.text.trim(),
      'tipoTransporte':        _tipoTransporte,
      'observaciones':         _obs.text.trim(),
    };
    if (_salida.text.trim().isNotEmpty)
      data['fechaSalidaProgramada'] = _salida.text.trim();
    if (_llegada.text.trim().isNotEmpty)
      data['fechaLlegadaProgramada'] = _llegada.text.trim();

    if (_isEdit) {
      context.read<DespachoBloc>()
          .add(DespachoTransporteUpdate(widget.despacho!.id, data));
    } else {
      context.read<DespachoBloc>().add(DespachoCreateRequested(data));
    }
    Navigator.pop(context);
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now.add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;
    final dt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    ctrl.text = _iso(dt);
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
          '-${d.day.toString().padLeft(2, '0')}'
          'T${d.hour.toString().padLeft(2, '0')}'
          ':${d.minute.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    return _DesSheet(
      title: _isEdit ? 'Editar transporte' : 'Nuevo despacho',
      child: Form(
        key: _key,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Sucursales ──────────────────────────────────────────────
          _DesLabel('Sucursal origen *'),
          const SizedBox(height: 8),
          _loadingSuc
              ? const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                  color: Color(0xFF1A237E))))
              : _SucDropdown(
              hint: 'Seleccionar origen',
              value: _origenId,
              sucursales: _sucursales,
              excluir: _destinoId,
              onChanged: (v) => setState(() => _origenId = v)),
          const SizedBox(height: 14),
          _DesLabel('Sucursal destino *'),
          const SizedBox(height: 8),
          _SucDropdown(
              hint: 'Seleccionar destino',
              value: _destinoId,
              sucursales: _sucursales,
              excluir: _origenId,
              onChanged: (v) => setState(() => _destinoId = v)),
          const SizedBox(height: 16),

          // ── Tipo de transporte ──────────────────────────────────────
          _DesLabel('Tipo de transporte'),
          const SizedBox(height: 8),
          Row(children: [
            _TipoBtn(
                label: 'Aéreo',
                icon: Icons.flight_rounded,
                value: 'AEREO',
                selected: _tipoTransporte,
                onTap: (v) => setState(() => _tipoTransporte = v)),
            const SizedBox(width: 8),
            _TipoBtn(
                label: 'Marítimo',
                icon: Icons.directions_boat_outlined,
                value: 'MARITIMO',
                selected: _tipoTransporte,
                onTap: (v) => setState(() => _tipoTransporte = v)),
            const SizedBox(width: 8),
            _TipoBtn(
                label: 'Terrestre',
                icon: Icons.local_shipping_outlined,
                value: 'TERRESTRE',
                selected: _tipoTransporte,
                onTap: (v) => setState(() => _tipoTransporte = v)),
          ]),
          const SizedBox(height: 14),

          // ── Aerolínea y nº vuelo ────────────────────────────────────
          Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesLabel('Aerolínea'),
                  const SizedBox(height: 8),
                  TextFormField(controller: _aerolinea,
                      decoration: _desoDeco('Ej: American Airlines')),
                ])),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesLabel('Nº Vuelo'),
                  const SizedBox(height: 8),
                  TextFormField(controller: _numVuelo,
                      decoration: _desoDeco('Ej: AA-1234')),
                ])),
          ]),
          const SizedBox(height: 14),

          // ── Guía aérea y contenedor ─────────────────────────────────
          Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesLabel('Guía aérea'),
                  const SizedBox(height: 8),
                  TextFormField(controller: _guiaAerea,
                      decoration: _desoDeco('Ej: 001-12345678')),
                ])),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesLabel('Nº Contenedor'),
                  const SizedBox(height: 8),
                  TextFormField(controller: _contenedor,
                      decoration: _desoDeco('Para marítimos')),
                ])),
          ]),
          const SizedBox(height: 14),

          // ── Fechas ──────────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesLabel('Salida programada'),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _salida,
                      readOnly: true,
                      decoration: _desoDeco('Seleccionar fecha',
                          suf: IconButton(
                              icon: const Icon(Icons.calendar_month_outlined,
                                  size: 18, color: Color(0xFF9CA3AF)),
                              onPressed: () => _pickDate(_salida)))),
                ])),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DesLabel('Llegada programada'),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _llegada,
                      readOnly: true,
                      decoration: _desoDeco('Seleccionar fecha',
                          suf: IconButton(
                              icon: const Icon(Icons.calendar_month_outlined,
                                  size: 18, color: Color(0xFF9CA3AF)),
                              onPressed: () => _pickDate(_llegada)))),
                ])),
          ]),
          const SizedBox(height: 14),

          // ── Observaciones ───────────────────────────────────────────
          _DesLabel('Observaciones'),
          const SizedBox(height: 8),
          TextFormField(
              controller: _obs, maxLines: 3,
              decoration: _desoDeco('Notas adicionales...')),
          const SizedBox(height: 24),

          _DesSubmitBtn(
              label: _isEdit ? 'Guardar cambios' : 'Crear despacho',
              onTap: _submit),
        ]),
      ),
    );
  }
}

// ─── SHEET CAMBIO DE ESTADO ───────────────────────────────────────────────────
class _CambioEstadoSheet extends StatefulWidget {
  final DespachoModel despacho;
  const _CambioEstadoSheet({required this.despacho});
  @override
  State<_CambioEstadoSheet> createState() => _CambioEstadoSheetState();
}

class _CambioEstadoSheetState extends State<_CambioEstadoSheet> {
  EstadoDespacho? _nuevo;
  final _obsCtrl = TextEditingController();

  @override
  void dispose() { _obsCtrl.dispose(); super.dispose(); }

  Color _ec(EstadoDespacho e) => switch (e) {
    EstadoDespacho.ABIERTO     => const Color(0xFF1A237E),
    EstadoDespacho.CERRADO     => const Color(0xFF7B1FA2),
    EstadoDespacho.EN_TRANSITO => const Color(0xFFE65100),
    EstadoDespacho.RECIBIDO    => const Color(0xFF2E7D32),
    EstadoDespacho.PROCESADO   => const Color(0xFF546E7A),
    EstadoDespacho.CANCELADO   => const Color(0xFFC62828),
  };

  String _desc(EstadoDespacho e) => switch (e) {
    EstadoDespacho.CERRADO     => 'No se pueden agregar más pedidos',
    EstadoDespacho.EN_TRANSITO => 'El despacho ha salido del origen',
    EstadoDespacho.RECIBIDO    => 'Llegó a la sucursal destino',
    EstadoDespacho.PROCESADO   => 'Todos los pedidos fueron distribuidos',
    EstadoDespacho.CANCELADO   => 'Cancela y revierte los pedidos',
    _                          => '',
  };

  void _submit() {
    if (_nuevo == null) return;
    context.read<DespachoBloc>().add(DespachoEstadoCambiar(
        widget.despacho.id, _nuevo!,
        observacion: _obsCtrl.text.trim()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final transiciones = widget.despacho.estado.transicionesValidas;
    return _DesSheet(
      title: 'Cambiar estado',
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Estado actual
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('Estado actual: ',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280))),
              _EstadoBadge(estado: widget.despacho.estado),
            ])),
        const SizedBox(height: 20),
        _DesLabel('Selecciona el nuevo estado'),
        const SizedBox(height: 12),

        // Opciones
        ...transiciones.map((e) {
          final sel = _nuevo == e;
          final c   = _ec(e);
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
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: sel
                                        ? c : const Color(0xFF374151))),
                            Text(_desc(e),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF))),
                          ])),
                      if (sel)
                        Icon(Icons.check_circle_rounded, color: c, size: 20),
                    ]),
                  )));
        }),
        const SizedBox(height: 16),

        // Observación
        _DesLabel('Observación (opcional)'),
        const SizedBox(height: 8),
        TextFormField(
            controller: _obsCtrl, maxLines: 2,
            decoration: _desoDeco('Ej: Cerrado con 3 paquetes')),
        const SizedBox(height: 24),

        _DesSubmitBtn(
            label: _nuevo != null
                ? 'Cambiar a ${_nuevo!.label}'
                : 'Selecciona un estado',
            onTap: _nuevo != null ? _submit : () {},
            color: _nuevo != null ? _ec(_nuevo!) : const Color(0xFF9CA3AF)),
      ]),
    );
  }
}

// ─── WIDGETS PROPIOS DEL MÓDULO ───────────────────────────────────────────────

class _RutaRow extends StatelessWidget {
  final IconData icon;
  final String   nombre, pais;
  const _RutaRow(
      {required this.icon, required this.nombre, required this.pais});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 13, color: const Color(0xFF6B7280)),
    const SizedBox(width: 6),
    Expanded(
        child: Text('$nombre ($pais)',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF374151)))),
  ]);
}

class _EstadoBadge extends StatelessWidget {
  final EstadoDespacho estado;
  const _EstadoBadge({required this.estado});

  Color get _c => switch (estado) {
    EstadoDespacho.ABIERTO     => const Color(0xFF1A237E),
    EstadoDespacho.CERRADO     => const Color(0xFF7B1FA2),
    EstadoDespacho.EN_TRANSITO => const Color(0xFFE65100),
    EstadoDespacho.RECIBIDO    => const Color(0xFF2E7D32),
    EstadoDespacho.PROCESADO   => const Color(0xFF546E7A),
    EstadoDespacho.CANCELADO   => const Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: _c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _c.withOpacity(0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: BoxDecoration(
              color: _c, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(estado.label,
          style: TextStyle(
              color: _c,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    ]),
  );
}

class _TransporteBadge extends StatelessWidget {
  final String tipo;
  const _TransporteBadge({required this.tipo});

  IconData get _icon => switch (tipo) {
    'MARITIMO'  => Icons.directions_boat_outlined,
    'TERRESTRE' => Icons.local_shipping_outlined,
    _           => Icons.flight_rounded,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icon, size: 10, color: const Color(0xFF6B7280)),
      const SizedBox(width: 4),
      Text(tipo,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280))),
    ]),
  );
}

class _CountBadge extends StatelessWidget {
  final int count; final String label;
  const _CountBadge({required this.count, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(20)),
    child: Text(
        '$count $label${count == 1 ? '' : 's'}',
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A237E))),
  );
}

class _TipoBtn extends StatelessWidget {
  final String   label, value, selected;
  final IconData icon;
  final void Function(String) onTap;
  const _TipoBtn(
      {required this.label,
        required this.icon,
        required this.value,
        required this.selected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    final c = sel ? const Color(0xFF1A237E) : const Color(0xFF9CA3AF);
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: sel
                  ? const Color(0xFFE8EAF6) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: sel
                      ? const Color(0xFF1A237E)
                      : const Color(0xFFE5E7EB),
                  width: sel ? 2 : 1)),
          child: Column(children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c)),
          ]),
        ),
      ),
    );
  }
}

class _SucDropdown extends StatelessWidget {
  final String        hint;
  final String?       value, excluir;
  final List<_SucRef> sucursales;
  final void Function(String?) onChanged;
  const _SucDropdown(
      {required this.hint,
        required this.value,
        required this.sucursales,
        required this.onChanged,
        this.excluir});

  @override
  Widget build(BuildContext context) {
    final items =
    sucursales.where((s) => s.id != excluir).toList();
    final currentVal =
    (value != null && items.any((s) => s.id == value))
        ? value
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          hint: Text(hint,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280)),
          isExpanded: true,
          items: items
              .map((s) => DropdownMenuItem(
            value: s.id,
            child: Text('${s.nombre} (${s.pais})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14)),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SucRef {
  final String id, nombre, pais;
  const _SucRef(
      {required this.id, required this.nombre, required this.pais});
}

class _DesBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       tip;
  final VoidCallback onTap;
  const _DesBtn(
      {required this.icon,
        required this.color,
        required this.tip,
        required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    child: Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(icon, color: color, size: 16))),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS BASE
// ═════════════════════════════════════════════════════════════════════════════

class _DesSectionTitle extends StatelessWidget {
  final String text;
  const _DesSectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 3, height: 14,
            decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF374151))),
      ]));
}

class _DesDetailRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _DesDetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                          fontWeight: FontWeight.w500)),
                ]),
          ]));
}

class _TotalCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _TotalCard(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Icon(icon, size: 20, color: const Color(0xFF1A237E)),
        const SizedBox(height: 4),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF1A1A2E))),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF9CA3AF))),
      ]),
    ),
  );
}

class _DesSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _DesSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 12),
      Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2))),
      Flexible(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E)))),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 18),
                child,
              ]),
        ),
      ),
    ]),
  );
}

class _DesLabel extends StatelessWidget {
  final String text;
  const _DesLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF374151)));
}

class _DesSubmitBtn extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;
  final Color        color;
  const _DesSubmitBtn(
      {required this.label,
        required this.onTap,
        this.color = const Color(0xFF1A237E)});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
      child: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600)),
    ),
  );
}

class _DesSearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final String                hint;
  final void Function(String) onChanged;
  const _DesSearchField(
      {required this.ctrl,
        required this.hint,
        required this.onChanged});

  OutlineInputBorder _b({Color? c, double w = 1}) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: c ?? const Color(0xFFE5E7EB), width: w));

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: const Icon(Icons.search_rounded,
          color: Color(0xFF9CA3AF), size: 20),
      suffixIcon: ctrl.text.isNotEmpty
          ? IconButton(
          icon: const Icon(Icons.close_rounded,
              color: Color(0xFF9CA3AF), size: 18),
          onPressed: () {
            ctrl.clear();
            onChanged('');
          })
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
          vertical: 12, horizontal: 16),
      border: _b(),
      enabledBorder: _b(),
      focusedBorder: _b(c: const Color(0xFF1A237E), w: 2),
    ),
  );
}

class _DesEmptyView extends StatelessWidget {
  final bool hasFilter;
  const _DesEmptyView({required this.hasFilter});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFE8EAF6), shape: BoxShape.circle),
            child: const Icon(Icons.local_shipping_outlined,
                size: 48, color: Color(0xFF1A237E))),
        const SizedBox(height: 16),
        Text(hasFilter ? 'Sin resultados' : 'No hay despachos',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Text(
            hasFilter
                ? 'Intenta con otro término o filtro'
                : 'Crea el primer despacho con "Nuevo despacho"',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _DesErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _DesErrorView(
      {required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFC62828))),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 20),
        ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar')),
      ]),
    ),
  );
}

InputDecoration _desoDeco(String hint, {Widget? suf}) => InputDecoration(
  hintText: hint,
  hintStyle:
  const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
  suffixIcon: suf,
  filled: true,
  fillColor: Colors.white,
  contentPadding:
  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  border:             _dib(),
  enabledBorder:      _dib(),
  focusedBorder:      _dib(c: const Color(0xFF1A237E), w: 2),
  errorBorder:        _dib(c: const Color(0xFFC62828)),
  focusedErrorBorder: _dib(c: const Color(0xFFC62828), w: 2),
);

OutlineInputBorder _dib({Color? c, double w = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide:
    BorderSide(color: c ?? const Color(0xFFE5E7EB), width: w));