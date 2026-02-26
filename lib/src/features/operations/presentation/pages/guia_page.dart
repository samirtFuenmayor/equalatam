// lib/src/features/guias/presentation/pages/guias_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../../../core/constants/api_constants.dart';
import '../domain/models/guia_model.dart';
import '../bloc/guia_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
class GuiasPage extends StatelessWidget {
  const GuiasPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => di.sl<GuiaBloc>()..add(GuiaLoadAll()),
    child: const _GuiasView(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class _GuiasView extends StatefulWidget {
  const _GuiasView();
  @override
  State<_GuiasView> createState() => _GuiasViewState();
}

class _GuiasViewState extends State<_GuiasView> {
  final _searchCtrl = TextEditingController();
  String       _q           = '';
  EstadoGuia?  _filtroEstado;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<GuiaModel> _filter(List<GuiaModel> src) => src.where((g) {
    final q   = _q.toLowerCase();
    final okQ = _q.isEmpty ||
        g.numeroGuia.toLowerCase().contains(q) ||
        g.numeroPedido.toLowerCase().contains(q) ||
        g.destinatarioNombre.toLowerCase().contains(q) ||
        g.destinatarioCasillero.toLowerCase().contains(q) ||
        g.remitenteNombre.toLowerCase().contains(q) ||
        (g.numeroDespacho?.toLowerCase().contains(q) ?? false) ||
        (g.trackingExterno?.toLowerCase().contains(q) ?? false);
    final okE = _filtroEstado == null || g.estado == _filtroEstado;
    return okQ && okE;
  }).toList();

  void _openCreate(BuildContext ctx) => showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
          value: ctx.read<GuiaBloc>(),
          child: const _GuiaFormSheet()));

  void _openDetail(BuildContext ctx, GuiaModel g) => showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
          value: ctx.read<GuiaBloc>(),
          child: _GuiaDetailSheet(
            guia: g,
            onAsignarDespacho: () { Navigator.pop(ctx); _openAsignarDespacho(ctx, g); },
            onCambiarEstado:   () { Navigator.pop(ctx); _openCambioEstado(ctx, g); },
            onAnular:          () { Navigator.pop(ctx); _openAnular(ctx, g); },
          )));

  void _openAsignarDespacho(BuildContext ctx, GuiaModel g) => showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
          value: ctx.read<GuiaBloc>(),
          child: _AsignarDespachoSheet(guia: g)));

  void _openCambioEstado(BuildContext ctx, GuiaModel g) => showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
          value: ctx.read<GuiaBloc>(),
          child: _CambioEstadoSheet(guia: g)));

  void _openAnular(BuildContext ctx, GuiaModel g) => showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
          value: ctx.read<GuiaBloc>(),
          child: _AnularSheet(guia: g)));

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
    return BlocConsumer<GuiaBloc, GuiaState>(
      listener: (ctx, state) {
        if (state is GuiaLoaded && state.message != null)
          _snack(ctx, state.message!, ok: true);
        if (state is GuiaError) _snack(ctx, state.message, ok: false);
      },
      builder: (ctx, state) {
        final all = switch (state) {
          GuiaLoaded s => s.guias,
          GuiaError  s => s.guias,
          _            => <GuiaModel>[],
        };
        final filtered = _filter(all);
        final loading  = state is GuiaLoading;
        final errOnly  = state is GuiaError && all.isEmpty;

        // Conteos
        final generadas   = all.where((g) => g.estado == EstadoGuia.GENERADA).length;
        final asignadas   = all.where((g) => g.estado == EstadoGuia.ASIGNADA).length;
        final enTransito  = all.where((g) => g.estado == EstadoGuia.EN_TRANSITO).length;
        final entregadas  = all.where((g) => g.estado == EstadoGuia.ENTREGADA).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            _GuiHeader(
              total: all.length,
              onAdd:     () => _openCreate(ctx),
              onRefresh: () => ctx.read<GuiaBloc>().add(GuiaLoadAll()),
            ),
            if (all.isNotEmpty)
              _GuiStatsRow(
                  generadas: generadas, asignadas: asignadas,
                  enTransito: enTransito, entregadas: entregadas),
            _GuiFilterBar(
              searchCtrl:   _searchCtrl,
              filtroEstado: _filtroEstado,
              onSearch: (v) => setState(() => _q = v),
              onEstado: (e) => setState(() => _filtroEstado = e),
            ),
            Expanded(child: _body(ctx, state, filtered, loading, errOnly, isDesktop)),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext ctx, GuiaState state, List<GuiaModel> filtered,
      bool loading, bool errOnly, bool isDesktop) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    if (errOnly) return _GuiErrorView(
        message: (state as GuiaError).message,
        onRetry: () => ctx.read<GuiaBloc>().add(GuiaLoadAll()));
    if (filtered.isEmpty) return _GuiEmptyView(
        hasFilter: _q.isNotEmpty || _filtroEstado != null);
    return isDesktop
        ? _GuiasTable(guias: filtered,
        onDetail:          (g) => _openDetail(ctx, g),
        onAsignarDespacho: (g) => _openAsignarDespacho(ctx, g),
        onCambiarEstado:   (g) => _openCambioEstado(ctx, g),
        onAnular:          (g) => _openAnular(ctx, g))
        : _GuiasCards(guias: filtered,
        onDetail:          (g) => _openDetail(ctx, g),
        onAsignarDespacho: (g) => _openAsignarDespacho(ctx, g),
        onCambiarEstado:   (g) => _openCambioEstado(ctx, g),
        onAnular:          (g) => _openAnular(ctx, g));
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _GuiHeader extends StatelessWidget {
  final int total;
  final VoidCallback onAdd, onRefresh;
  const _GuiHeader({required this.total, required this.onAdd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Gestión de Guías',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          Text('$total guía${total == 1 ? '' : 's'} registrada${total == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ])),
        IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
            onPressed: onRefresh, tooltip: 'Actualizar'),
        const SizedBox(width: 6),
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12)),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(isWide ? 'Nueva guía' : 'Nueva',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ─── STATS ────────────────────────────────────────────────────────────────────
class _GuiStatsRow extends StatelessWidget {
  final int generadas, asignadas, enTransito, entregadas;
  const _GuiStatsRow({required this.generadas, required this.asignadas,
    required this.enTransito, required this.entregadas});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
    child: Row(children: [
      _StatCard(value: generadas,  label: 'Generadas',   color: const Color(0xFF1A237E), icon: Icons.description_outlined),
      const SizedBox(width: 10),
      _StatCard(value: asignadas,  label: 'Asignadas',   color: const Color(0xFF6A1B9A), icon: Icons.local_shipping_outlined),
      const SizedBox(width: 10),
      _StatCard(value: enTransito, label: 'En tránsito', color: const Color(0xFFE65100), icon: Icons.flight_takeoff_rounded),
      const SizedBox(width: 10),
      _StatCard(value: entregadas, label: 'Entregadas',  color: const Color(0xFF2E7D32), icon: Icons.check_circle_outline),
    ]),
  );
}

class _StatCard extends StatelessWidget {
  final int value; final String label; final Color color; final IconData icon;
  const _StatCard({required this.value, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
        ])),
      ]),
    ),
  );
}

// ─── FILTROS ──────────────────────────────────────────────────────────────────
class _GuiFilterBar extends StatelessWidget {
  final TextEditingController     searchCtrl;
  final EstadoGuia?               filtroEstado;
  final void Function(String)        onSearch;
  final void Function(EstadoGuia?)   onEstado;
  const _GuiFilterBar({required this.searchCtrl, required this.filtroEstado,
    required this.onSearch, required this.onEstado});

  Color _ec(EstadoGuia e) => switch (e) {
    EstadoGuia.GENERADA    => const Color(0xFF1A237E),
    EstadoGuia.ASIGNADA    => const Color(0xFF6A1B9A),
    EstadoGuia.EN_TRANSITO => const Color(0xFFE65100),
    EstadoGuia.ENTREGADA   => const Color(0xFF2E7D32),
    EstadoGuia.ANULADA     => const Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final search = _GuiSearchField(ctrl: searchCtrl,
        hint: 'Buscar por número, cliente, despacho...', onChanged: onSearch);
    final drop = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EstadoGuia?>(
          value: filtroEstado,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
          items: [
            const DropdownMenuItem(value: null,
                child: Text('Todos los estados', style: TextStyle(fontSize: 13))),
            ...EstadoGuia.values.map((e) => DropdownMenuItem(
              value: e,
              child: Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: _ec(e), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(e.label, style: const TextStyle(fontSize: 13)),
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
          ? Row(children: [Expanded(child: search), const SizedBox(width: 10), drop])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [search, const SizedBox(height: 10), drop]),
    );
  }
}

// ─── TABLA DESKTOP ────────────────────────────────────────────────────────────
class _GuiasTable extends StatelessWidget {
  final List<GuiaModel>          guias;
  final void Function(GuiaModel) onDetail, onAsignarDespacho, onCambiarEstado, onAnular;
  const _GuiasTable({required this.guias, required this.onDetail,
    required this.onAsignarDespacho, required this.onCambiarEstado, required this.onAnular});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
            0: FlexColumnWidth(1.6),
            1: FlexColumnWidth(1.8),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.8),
            4: FlexColumnWidth(1.2),
            5: FixedColumnWidth(140),
          },
          children: [
            TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: ['Nº Guía', 'Destinatario', 'Estado', 'Transporte', 'Costos', 'Acciones']
                    .map((h) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Text(h, style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                )).toList()),
            ...guias.map((g) => TableRow(
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                children: [
                  // Número
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.numeroGuia, style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12,
                          fontFamily: 'monospace', color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      Text(g.numeroPedido, style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF), fontFamily: 'monospace')),
                    ]),
                  ),
                  // Destinatario
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.destinatarioNombre, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                      Text(g.destinatarioCasillero,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                      if (g.sucursalOrigenNombre != null)
                        _RutaRow(
                            origen: '${g.sucursalOrigenNombre} (${g.sucursalOrigenPais ?? ''})',
                            destino: g.sucursalDestinoNombre ?? ''),
                    ]),
                  ),
                  // Estado
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: _EstadoBadge(estado: g.estado),
                  ),
                  // Transporte
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (g.numeroDespacho != null)
                        _InfoChip(Icons.local_shipping_outlined, g.numeroDespacho!),
                      if (g.aerolinea != null) ...[
                        const SizedBox(height: 4),
                        Text(g.aerolinea!, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                      if (g.numeroVuelo != null)
                        Text(g.numeroVuelo!,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    ]),
                  ),
                  // Costos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (g.costoTotal != null)
                        Text('\$${g.costoTotal!.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
                      if (g.pesoCobrable != null)
                        Text('${g.pesoCobrable!.toStringAsFixed(2)} lb',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    ]),
                  ),
                  // Acciones
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Wrap(spacing: 4, children: [
                      _GuiBtn(icon: Icons.visibility_outlined, color: const Color(0xFF1A237E),
                          tip: 'Ver detalle', onTap: () => onDetail(g)),
                      if (g.estado == EstadoGuia.GENERADA)
                        _GuiBtn(icon: Icons.local_shipping_outlined, color: const Color(0xFF6A1B9A),
                            tip: 'Asignar despacho', onTap: () => onAsignarDespacho(g)),
                      if (g.estado.transicionesValidas.isNotEmpty && g.estado != EstadoGuia.ANULADA)
                        _GuiBtn(icon: Icons.swap_horiz_rounded, color: const Color(0xFFE65100),
                            tip: 'Cambiar estado', onTap: () => onCambiarEstado(g)),
                      if (!g.estado.esFinal)
                        _GuiBtn(icon: Icons.block_rounded, color: const Color(0xFFC62828),
                            tip: 'Anular', onTap: () => onAnular(g)),
                    ]),
                  ),
                ])),
          ],
        ),
      ),
    ),
  );
}

// ─── CARDS MÓVIL ──────────────────────────────────────────────────────────────
class _GuiasCards extends StatelessWidget {
  final List<GuiaModel>          guias;
  final void Function(GuiaModel) onDetail, onAsignarDespacho, onCambiarEstado, onAnular;
  const _GuiasCards({required this.guias, required this.onDetail,
    required this.onAsignarDespacho, required this.onCambiarEstado, required this.onAnular});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    itemCount: guias.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _GuiaCard(
      g: guias[i],
      onDetail:          () => onDetail(guias[i]),
      onAsignarDespacho: () => onAsignarDespacho(guias[i]),
      onCambiarEstado:   () => onCambiarEstado(guias[i]),
      onAnular:          () => onAnular(guias[i]),
    ),
  );
}

class _GuiaCard extends StatelessWidget {
  final GuiaModel    g;
  final VoidCallback onDetail, onAsignarDespacho, onCambiarEstado, onAnular;
  const _GuiaCard({required this.g, required this.onDetail,
    required this.onAsignarDespacho, required this.onCambiarEstado, required this.onAnular});

  String _fmtShort(DateTime dt) =>
      '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} '
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Cabecera
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.numeroGuia, style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'monospace', color: Color(0xFF1A1A2E))),
          Text(g.numeroPedido, style: const TextStyle(
              fontSize: 11, color: Color(0xFF9CA3AF), fontFamily: 'monospace')),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            _popItem('detail', Icons.visibility_outlined, 'Ver detalle', const Color(0xFF1A237E)),
            if (g.estado == EstadoGuia.GENERADA)
              _popItem('despacho', Icons.local_shipping_outlined, 'Asignar despacho', const Color(0xFF6A1B9A)),
            if (g.estado.transicionesValidas.isNotEmpty && g.estado != EstadoGuia.ANULADA)
              _popItem('estado', Icons.swap_horiz_rounded, 'Cambiar estado', const Color(0xFFE65100)),
            if (!g.estado.esFinal)
              _popItem('anular', Icons.block_rounded, 'Anular guía', const Color(0xFFC62828)),
          ],
          onSelected: (v) {
            if (v == 'detail')   onDetail();
            if (v == 'despacho') onAsignarDespacho();
            if (v == 'estado')   onCambiarEstado();
            if (v == 'anular')   onAnular();
          },
        ),
      ]),
      const SizedBox(height: 10),

      // Destinatario + ruta
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Expanded(child: Text(g.destinatarioNombre, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)))),
            Text(g.destinatarioCasillero,
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ]),
          if (g.sucursalOrigenNombre != null) ...[
            const SizedBox(height: 6),
            _RutaRow(
                origen: '${g.sucursalOrigenNombre} (${g.sucursalOrigenPais ?? ''})',
                destino: g.sucursalDestinoNombre ?? ''),
          ],
        ]),
      ),
      const SizedBox(height: 10),

      // Badges
      Wrap(spacing: 6, runSpacing: 6, children: [
        _EstadoBadge(estado: g.estado),
        if (g.numeroDespacho != null)
          _InfoChip(Icons.local_shipping_outlined, g.numeroDespacho!),
        if (g.pesoCobrable != null)
          _InfoChip(Icons.scale_outlined, '${g.pesoCobrable!.toStringAsFixed(2)} lb'),
        if (g.costoTotal != null)
          _InfoChip(Icons.attach_money_rounded, '\$${g.costoTotal!.toStringAsFixed(2)}'),
      ]),

      const SizedBox(height: 10),
      Row(children: [
        const Icon(Icons.schedule_rounded, size: 11, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(_fmtShort(g.fechaGeneracion),
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        if (g.generadaPor != null) ...[
          const Text(' · ', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          Text(g.generadaPor!, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ]),
      const SizedBox(height: 12),

      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
            onPressed: onDetail,
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A237E),
                side: const BorderSide(color: Color(0xFFC5CAE9)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10)),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('Ver detalle', style: TextStyle(fontSize: 13))),
      ),
    ]),
  );

  PopupMenuItem<String> _popItem(String v, IconData icon, String label, Color c) =>
      PopupMenuItem(value: v, child: Row(children: [
        Icon(icon, size: 18, color: c), const SizedBox(width: 10), Text(label),
      ]));
}

// ─── SHEET DETALLE ────────────────────────────────────────────────────────────
class _GuiaDetailSheet extends StatelessWidget {
  final GuiaModel    guia;
  final VoidCallback onAsignarDespacho, onCambiarEstado, onAnular;
  const _GuiaDetailSheet({required this.guia, required this.onAsignarDespacho,
    required this.onCambiarEstado, required this.onAnular});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final g = guia;
    return _GuiSheet(
      title: g.numeroGuia,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _EstadoBadge(estado: g.estado),
          if (g.pesoCobrable != null)
            _InfoChip(Icons.scale_outlined, '${g.pesoCobrable!.toStringAsFixed(2)} lb cobrable'),
          if (g.costoTotal != null)
            _InfoChip(Icons.attach_money_rounded, '\$${g.costoTotal!.toStringAsFixed(2)} total'),
        ]),
        const SizedBox(height: 20),

        // Pedido vinculado
        _GuiSectionTitle('Pedido vinculado'),
        _GuiDetailRow(Icons.inventory_2_outlined, 'Nº Pedido', g.numeroPedido),
        if (g.trackingExterno != null)
          _GuiDetailRow(Icons.qr_code_outlined, 'Tracking externo', g.trackingExterno!),
        const SizedBox(height: 16),

        // Remitente
        _GuiSectionTitle('Remitente'),
        _GuiDetailRow(Icons.person_outline_rounded, 'Nombre', g.remitenteNombre),
        if (g.remitentePais != null)
          _GuiDetailRow(Icons.flag_outlined, 'País', g.remitentePais!),
        if (g.remitenteDireccion != null)
          _GuiDetailRow(Icons.location_on_outlined, 'Dirección', g.remitenteDireccion!),
        if (g.remitenteTelefono != null)
          _GuiDetailRow(Icons.phone_outlined, 'Teléfono', g.remitenteTelefono!),
        if (g.remitenteEmail != null)
          _GuiDetailRow(Icons.email_outlined, 'Email', g.remitenteEmail!),
        const SizedBox(height: 16),

        // Destinatario
        _GuiSectionTitle('Destinatario'),
        _GuiDetailRow(Icons.person_outline_rounded, 'Nombre', g.destinatarioNombre),
        _GuiDetailRow(Icons.tag_rounded, 'Casillero', g.destinatarioCasillero),
        if (g.destinatarioTelefono != null)
          _GuiDetailRow(Icons.phone_outlined, 'Teléfono', g.destinatarioTelefono!),
        const SizedBox(height: 16),

        // Ruta
        _GuiSectionTitle('Ruta'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            if (g.sucursalOrigenNombre != null)
              Row(children: [
                const Icon(Icons.flight_takeoff_rounded, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Origen', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                  Text('${g.sucursalOrigenNombre} (${g.sucursalOrigenPais ?? ''})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                ]),
              ]),
            if (g.sucursalOrigenNombre != null && g.sucursalDestinoNombre != null)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            if (g.sucursalDestinoNombre != null)
              Row(children: [
                const Icon(Icons.flight_land_rounded, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Destino', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                  Text('${g.sucursalDestinoNombre}${g.sucursalDestinoCiudad != null ? ' (${g.sucursalDestinoCiudad})' : ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                ]),
              ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Contenido y pesos
        _GuiSectionTitle('Contenido y pesos'),
        _GuiDetailRow(Icons.description_outlined, 'Descripción', g.descripcionContenido),
        if (g.cantidadPiezas != null)
          _GuiDetailRow(Icons.inventory_2_outlined, 'Piezas', '${g.cantidadPiezas}'),
        const SizedBox(height: 8),
        Row(children: [
          if (g.pesoDeclarado != null)
            Expanded(child: _PesoCard('${g.pesoDeclarado!.toStringAsFixed(2)} lb', 'Real', Icons.scale_outlined)),
          if (g.pesoVolumetrico != null) ...[
            const SizedBox(width: 10),
            Expanded(child: _PesoCard('${g.pesoVolumetrico!.toStringAsFixed(2)} lb', 'Volumétrico', Icons.straighten_outlined)),
          ],
          if (g.pesoCobrable != null) ...[
            const SizedBox(width: 10),
            Expanded(child: _PesoCard('${g.pesoCobrable!.toStringAsFixed(2)} lb', 'Cobrable', Icons.monetization_on_outlined)),
          ],
        ]),
        const SizedBox(height: 16),

        // Costos
        _GuiSectionTitle('Desglose de costos'),
        _CostosCard(guia: g),
        const SizedBox(height: 16),

        // Transporte
        if (g.numeroDespacho != null) ...[
          _GuiSectionTitle('Información de transporte'),
          _GuiDetailRow(Icons.local_shipping_outlined, 'Despacho', g.numeroDespacho!),
          if (g.aerolinea != null)  _GuiDetailRow(Icons.airplanemode_active_outlined, 'Aerolínea', g.aerolinea!),
          if (g.numeroVuelo != null) _GuiDetailRow(Icons.confirmation_number_outlined, 'Vuelo', g.numeroVuelo!),
          if (g.guiaAerea != null)  _GuiDetailRow(Icons.article_outlined, 'Guía aérea', g.guiaAerea!),
          const SizedBox(height: 16),
        ],

        // Auditoría
        _GuiSectionTitle('Auditoría'),
        _GuiDetailRow(Icons.schedule_rounded, 'Generada', _fmt(g.fechaGeneracion)),
        if (g.generadaPor != null) _GuiDetailRow(Icons.person_outline_rounded, 'Por', g.generadaPor!),
        if (g.fechaEntrega != null) _GuiDetailRow(Icons.check_circle_outline, 'Entregada', _fmt(g.fechaEntrega!)),

        if (g.observaciones != null && g.observaciones!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFDE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFF176))),
            child: Text(g.observaciones!, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          ),
        ],

        const SizedBox(height: 20),

        // Botones de acción
        Wrap(spacing: 10, runSpacing: 10, children: [
          if (g.estado == EstadoGuia.GENERADA)
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onAsignarDespacho,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A), foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.local_shipping_outlined, size: 16),
                label: const Text('Asignar despacho'),
              ),
            ),
          if (g.estado.transicionesValidas.isNotEmpty && g.estado != EstadoGuia.ANULADA)
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onCambiarEstado,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text('Cambiar estado'),
              ),
            ),
          if (!g.estado.esFinal)
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: onAnular,
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFEF9A9A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.block_rounded, size: 16),
                label: const Text('Anular guía'),
              ),
            ),
        ]),
      ]),
    );
  }
}

// Card desglose costos
class _CostosCard extends StatelessWidget {
  final GuiaModel guia;
  const _CostosCard({required this.guia});

  @override
  Widget build(BuildContext context) {
    final g = guia;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        if (g.tarifaPorLibra != null)
          _CostoRow('Tarifa por libra', '\$${g.tarifaPorLibra!.toStringAsFixed(2)}/lb', false),
        if (g.costoFlete != null)
          _CostoRow('Flete (${g.pesoCobrable?.toStringAsFixed(2) ?? '?'} lb)', '\$${g.costoFlete!.toStringAsFixed(2)}', false),
        if (g.costoManejo != null)
          _CostoRow('Manejo', '\$${g.costoManejo!.toStringAsFixed(2)}', false),
        if (g.costoSeguro != null)
          _CostoRow('Seguro (2%)', '\$${g.costoSeguro!.toStringAsFixed(2)}', false),
        if (g.costoTotal != null) ...[
          const Divider(height: 16),
          _CostoRow('TOTAL', '\$${g.costoTotal!.toStringAsFixed(2)}', true),
        ],
      ]),
    );
  }
}

class _CostoRow extends StatelessWidget {
  final String label, valor; final bool isTotal;
  const _CostoRow(this.label, this.valor, this.isTotal);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(
          fontSize: isTotal ? 14 : 12,
          fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          color: isTotal ? const Color(0xFF1A1A2E) : const Color(0xFF6B7280)))),
      Text(valor, style: TextStyle(
          fontSize: isTotal ? 15 : 13,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          color: isTotal ? const Color(0xFF1A237E) : const Color(0xFF374151))),
    ]),
  );
}

// ─── SHEET GENERAR GUÍA ───────────────────────────────────────────────────────
class _GuiaFormSheet extends StatefulWidget {
  const _GuiaFormSheet();
  @override
  State<_GuiaFormSheet> createState() => _GuiaFormSheetState();
}

class _GuiaFormSheetState extends State<_GuiaFormSheet> {
  final _key = GlobalKey<FormState>();

  List<_PedidoRef> _pedidos = [];
  bool _loadingPed = true;
  String? _pedidoId;

  final _remNombreCtrl = TextEditingController();
  final _remDirCtrl    = TextEditingController();
  final _remTelCtrl    = TextEditingController();
  final _remEmailCtrl  = TextEditingController();
  final _remPaisCtrl   = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _pesoCtrl      = TextEditingController();
  final _valorCtrl     = TextEditingController();
  final _piezasCtrl    = TextEditingController();
  final _largoCtrl     = TextEditingController();
  final _anchoCtrl     = TextEditingController();
  final _altoCtrl      = TextEditingController();
  final _obsCtrl       = TextEditingController();

  @override
  void initState() { super.initState(); _fetchPedidos(); }

  @override
  void dispose() {
    for (final c in [_remNombreCtrl, _remDirCtrl, _remTelCtrl, _remEmailCtrl,
      _remPaisCtrl, _descCtrl, _pesoCtrl, _valorCtrl, _piezasCtrl,
      _largoCtrl, _anchoCtrl, _altoCtrl, _obsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchPedidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/pedidos'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
      if (res.statusCode >= 200 && res.statusCode < 300 && mounted) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _pedidos = list.map((e) => _PedidoRef(
              id:      e['id'].toString(),
              numero:  e['numeroPedido'].toString(),
              cliente: '${e['clienteNombres']} ${e['clienteApellidos']}',
              casillero: e['clienteCasillero']?.toString() ?? '')).toList();
          _loadingPed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPed = false);
    }
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    if (_pedidoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona un pedido'), backgroundColor: Color(0xFFC62828)));
      return;
    }
    final data = <String, dynamic>{
      'pedidoId':           _pedidoId,
      'remitenteNombre':    _remNombreCtrl.text.trim(),
      'descripcionContenido': _descCtrl.text.trim(),
    };
    if (_remDirCtrl.text.trim().isNotEmpty)   data['remitenteDireccion'] = _remDirCtrl.text.trim();
    if (_remTelCtrl.text.trim().isNotEmpty)   data['remitenteTelefono']  = _remTelCtrl.text.trim();
    if (_remEmailCtrl.text.trim().isNotEmpty) data['remitenteEmail']     = _remEmailCtrl.text.trim();
    if (_remPaisCtrl.text.trim().isNotEmpty)  data['remitentePais']      = _remPaisCtrl.text.trim();
    if (_pesoCtrl.text.trim().isNotEmpty)     data['pesoDeclarado']      = double.tryParse(_pesoCtrl.text.trim());
    if (_valorCtrl.text.trim().isNotEmpty)    data['valorDeclarado']     = double.tryParse(_valorCtrl.text.trim());
    if (_piezasCtrl.text.trim().isNotEmpty)   data['cantidadPiezas']     = int.tryParse(_piezasCtrl.text.trim());
    if (_largoCtrl.text.trim().isNotEmpty)    data['largo']              = double.tryParse(_largoCtrl.text.trim());
    if (_anchoCtrl.text.trim().isNotEmpty)    data['ancho']              = double.tryParse(_anchoCtrl.text.trim());
    if (_altoCtrl.text.trim().isNotEmpty)     data['alto']               = double.tryParse(_altoCtrl.text.trim());
    if (_obsCtrl.text.trim().isNotEmpty)      data['observaciones']      = _obsCtrl.text.trim();

    context.read<GuiaBloc>().add(GuiaGenerarRequested(data));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _GuiSheet(
    title: 'Nueva guía',
    child: Form(
      key: _key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Pedido
        _GuiLabel('Pedido *'),
        const SizedBox(height: 8),
        _loadingPed
            ? const Center(child: Padding(padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(color: Color(0xFF1A237E))))
            : _PedidoDropdown(
            value: _pedidoId, pedidos: _pedidos,
            onChanged: (v) => setState(() => _pedidoId = v)),
        const SizedBox(height: 16),

        // Remitente
        _GuiLabel('Remitente *'),
        const SizedBox(height: 8),
        TextFormField(controller: _remNombreCtrl,
            decoration: _guiDeco('Nombre del remitente'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(controller: _remPaisCtrl, decoration: _guiDeco('País'))),
          const SizedBox(width: 10),
          Expanded(child: TextFormField(controller: _remTelCtrl, decoration: _guiDeco('Teléfono'))),
        ]),
        const SizedBox(height: 10),
        TextFormField(controller: _remDirCtrl, decoration: _guiDeco('Dirección')),
        const SizedBox(height: 10),
        TextFormField(controller: _remEmailCtrl, decoration: _guiDeco('Email'),
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),

        // Contenido
        _GuiLabel('Descripción del contenido *'),
        const SizedBox(height: 8),
        TextFormField(controller: _descCtrl, maxLines: 2,
            decoration: _guiDeco('Ej: Laptop Dell XPS 15'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _GuiLabel('Peso (lb)'),
            const SizedBox(height: 6),
            TextFormField(controller: _pesoCtrl, keyboardType: TextInputType.number,
                decoration: _guiDeco('Ej: 2.5')),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _GuiLabel('Valor USD'),
            const SizedBox(height: 6),
            TextFormField(controller: _valorCtrl, keyboardType: TextInputType.number,
                decoration: _guiDeco('Ej: 1200.00')),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _GuiLabel('Piezas'),
            const SizedBox(height: 6),
            TextFormField(controller: _piezasCtrl, keyboardType: TextInputType.number,
                decoration: _guiDeco('Ej: 1')),
          ])),
        ]),
        const SizedBox(height: 10),

        // Dimensiones
        _GuiLabel('Dimensiones (cm) — para peso volumétrico'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextFormField(controller: _largoCtrl, keyboardType: TextInputType.number, decoration: _guiDeco('Largo'))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _anchoCtrl, keyboardType: TextInputType.number, decoration: _guiDeco('Ancho'))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: _altoCtrl, keyboardType: TextInputType.number, decoration: _guiDeco('Alto'))),
        ]),
        const SizedBox(height: 10),

        TextFormField(controller: _obsCtrl, maxLines: 2, decoration: _guiDeco('Observaciones (opcional)')),
        const SizedBox(height: 24),

        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Generar guía', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );
}

// ─── SHEET ASIGNAR DESPACHO ───────────────────────────────────────────────────
class _AsignarDespachoSheet extends StatefulWidget {
  final GuiaModel guia;
  const _AsignarDespachoSheet({required this.guia});
  @override
  State<_AsignarDespachoSheet> createState() => _AsignarDespachoSheetState();
}

class _AsignarDespachoSheetState extends State<_AsignarDespachoSheet> {
  final _key         = GlobalKey<FormState>();
  final _despachoCtrl = TextEditingController();
  final _aeroCtrl    = TextEditingController();
  final _vueloCtrl   = TextEditingController();
  final _awbCtrl     = TextEditingController();

  @override
  void dispose() { _despachoCtrl.dispose(); _aeroCtrl.dispose(); _vueloCtrl.dispose(); _awbCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    context.read<GuiaBloc>().add(GuiaAsignarDespacho(widget.guia.id, {
      'numeroDespacho': _despachoCtrl.text.trim(),
      'aerolinea':      _aeroCtrl.text.trim(),
      'numeroVuelo':    _vueloCtrl.text.trim(),
      'guiaAerea':      _awbCtrl.text.trim(),
    }));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _GuiSheet(
    title: 'Asignar a despacho',
    child: Form(
      key: _key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.description_outlined, size: 16, color: Color(0xFF1A237E)),
            const SizedBox(width: 8),
            Text(widget.guia.numeroGuia,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
          ]),
        ),
        const SizedBox(height: 16),

        _GuiLabel('Número de despacho *'),
        const SizedBox(height: 8),
        TextFormField(controller: _despachoCtrl,
            decoration: _guiDeco('Ej: DES-2026-00001'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _GuiLabel('Aerolínea'),
            const SizedBox(height: 6),
            TextFormField(controller: _aeroCtrl, decoration: _guiDeco('Ej: American Airlines')),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _GuiLabel('Nº Vuelo'),
            const SizedBox(height: 6),
            TextFormField(controller: _vueloCtrl, decoration: _guiDeco('Ej: AA-1234')),
          ])),
        ]),
        const SizedBox(height: 12),

        _GuiLabel('Guía aérea (AWB)'),
        const SizedBox(height: 8),
        TextFormField(controller: _awbCtrl, decoration: _guiDeco('Ej: 001-12345678')),
        const SizedBox(height: 24),

        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A), foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text('Asignar despacho', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );
}

// ─── SHEET CAMBIO ESTADO ──────────────────────────────────────────────────────
class _CambioEstadoSheet extends StatefulWidget {
  final GuiaModel guia;
  const _CambioEstadoSheet({required this.guia});
  @override
  State<_CambioEstadoSheet> createState() => _CambioEstadoSheetState();
}

class _CambioEstadoSheetState extends State<_CambioEstadoSheet> {
  EstadoGuia? _nuevo;

  Color _ec(EstadoGuia e) => switch (e) {
    EstadoGuia.GENERADA    => const Color(0xFF1A237E),
    EstadoGuia.ASIGNADA    => const Color(0xFF6A1B9A),
    EstadoGuia.EN_TRANSITO => const Color(0xFFE65100),
    EstadoGuia.ENTREGADA   => const Color(0xFF2E7D32),
    EstadoGuia.ANULADA     => const Color(0xFFC62828),
  };

  String _desc(EstadoGuia e) => switch (e) {
    EstadoGuia.ASIGNADA    => 'Guía asignada a un despacho',
    EstadoGuia.EN_TRANSITO => 'El paquete viaja con el despacho',
    EstadoGuia.ENTREGADA   => 'Paquete entregado al destinatario',
    EstadoGuia.ANULADA     => 'Cancela la guía',
    _                      => '',
  };

  void _submit() {
    if (_nuevo == null) return;
    context.read<GuiaBloc>().add(GuiaCambiarEstado(widget.guia.id, _nuevo!));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final transiciones = widget.guia.estado.transicionesValidas;
    return _GuiSheet(
      title: 'Cambiar estado',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Text('Estado actual: ', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            _EstadoBadge(estado: widget.guia.estado),
          ]),
        ),
        const SizedBox(height: 20),
        _GuiLabel('Selecciona el nuevo estado'),
        const SizedBox(height: 12),

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
                    border: Border.all(color: sel ? c : const Color(0xFFE5E7EB), width: sel ? 2 : 1)),
                child: Row(children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                        color: sel ? c : const Color(0xFF374151))),
                    Text(_desc(e), style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ])),
                  if (sel) Icon(Icons.check_circle_rounded, color: c, size: 20),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _nuevo != null ? _submit : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: _nuevo != null ? _ec(_nuevo!) : const Color(0xFF9CA3AF),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(_nuevo != null ? 'Cambiar a ${_nuevo!.label}' : 'Selecciona un estado',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ─── SHEET ANULAR ─────────────────────────────────────────────────────────────
class _AnularSheet extends StatefulWidget {
  final GuiaModel guia;
  const _AnularSheet({required this.guia});
  @override
  State<_AnularSheet> createState() => _AnularSheetState();
}

class _AnularSheetState extends State<_AnularSheet> {
  final _key      = GlobalKey<FormState>();
  final _motCtrl  = TextEditingController();
  @override
  void dispose() { _motCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    context.read<GuiaBloc>().add(GuiaAnular(widget.guia.id, _motCtrl.text.trim()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _GuiSheet(
    title: 'Anular guía',
    child: Form(
      key: _key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF9A9A))),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('¿Anular esta guía?', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFC62828))),
              Text(widget.guia.numeroGuia, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        _GuiLabel('Motivo de anulación *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _motCtrl, maxLines: 3,
          decoration: _guiDeco('Describe el motivo de anulación...'),
          validator: (v) => v == null || v.trim().isEmpty ? 'El motivo es obligatorio' : null,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.block_rounded, size: 18),
            label: const Text('Confirmar anulación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );
}

// ─── WIDGETS REUTILIZABLES ────────────────────────────────────────────────────

class _RutaRow extends StatelessWidget {
  final String origen, destino;
  const _RutaRow({required this.origen, required this.destino});
  @override
  Widget build(BuildContext context) => Row(children: [
    const Icon(Icons.flight_takeoff_rounded, size: 11, color: Color(0xFF9CA3AF)),
    const SizedBox(width: 4),
    Flexible(child: Text(origen, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)))),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.arrow_forward_rounded, size: 10, color: Color(0xFF9CA3AF))),
    const Icon(Icons.flight_land_rounded, size: 11, color: Color(0xFF9CA3AF)),
    const SizedBox(width: 4),
    Flexible(child: Text(destino, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)))),
  ]);
}

Color _estadoColor(EstadoGuia e) => switch (e) {
  EstadoGuia.GENERADA    => const Color(0xFF1A237E),
  EstadoGuia.ASIGNADA    => const Color(0xFF6A1B9A),
  EstadoGuia.EN_TRANSITO => const Color(0xFFE65100),
  EstadoGuia.ENTREGADA   => const Color(0xFF2E7D32),
  EstadoGuia.ANULADA     => const Color(0xFFC62828),
};

class _EstadoBadge extends StatelessWidget {
  final EstadoGuia estado;
  const _EstadoBadge({required this.estado});
  @override
  Widget build(BuildContext context) {
    final c = _estadoColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(estado.label, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: const Color(0xFF1A237E)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
    ]),
  );
}

class _PesoCard extends StatelessWidget {
  final String value, label; final IconData icon;
  const _PesoCard(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Icon(icon, size: 18, color: const Color(0xFF1A237E)),
      const SizedBox(height: 4),
      Text(value, textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1A1A2E))),
      Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
    ]),
  );
}

class _GuiBtn extends StatelessWidget {
  final IconData icon; final Color color; final String tip; final VoidCallback onTap;
  const _GuiBtn({required this.icon, required this.color, required this.tip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    child: Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
          borderRadius: BorderRadius.circular(8), onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, color: color, size: 16))),
    ),
  );
}

class _GuiSectionTitle extends StatelessWidget {
  final String text;
  const _GuiSectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(
          color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
    ]),
  );
}

class _GuiDetailRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _GuiDetailRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w500)),
      ])),
    ]),
  );
}

class _GuiSheet extends StatelessWidget {
  final String title; final Widget child;
  const _GuiSheet({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 12),
      Container(width: 40, height: 4, decoration: BoxDecoration(
          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
      Flexible(child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 18),
          child,
        ]),
      )),
    ]),
  );
}

class _GuiLabel extends StatelessWidget {
  final String text;
  const _GuiLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)));
}

class _GuiSearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final void Function(String) onChanged;
  const _GuiSearchField({required this.ctrl, required this.hint, required this.onChanged});

  OutlineInputBorder _b({Color? c, double w = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c ?? const Color(0xFFE5E7EB), width: w));

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
      suffixIcon: ctrl.text.isNotEmpty
          ? IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
          onPressed: () { ctrl.clear(); onChanged(''); })
          : null,
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: _b(), enabledBorder: _b(), focusedBorder: _b(c: const Color(0xFF1A237E), w: 2),
    ),
  );
}

class _GuiEmptyView extends StatelessWidget {
  final bool hasFilter;
  const _GuiEmptyView({required this.hasFilter});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFE8EAF6), shape: BoxShape.circle),
            child: const Icon(Icons.description_outlined, size: 48, color: Color(0xFF1A237E))),
        const SizedBox(height: 16),
        Text(hasFilter ? 'Sin resultados' : 'No hay guías',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Text(hasFilter ? 'Intenta con otro término o filtro' : 'Genera la primera guía con "Nueva guía"',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _GuiErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _GuiErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFC62828))),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 20),
        ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar')),
      ]),
    ),
  );
}

class _PedidoDropdown extends StatelessWidget {
  final String?          value;
  final List<_PedidoRef> pedidos;
  final void Function(String?) onChanged;
  const _PedidoDropdown({required this.value, required this.pedidos, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = (value != null && pedidos.any((p) => p.id == value)) ? value : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          hint: const Text('Seleccionar pedido', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
          isExpanded: true,
          items: pedidos.map((p) => DropdownMenuItem(
            value: p.id,
            child: Text('${p.numero} — ${p.cliente} (${p.casillero})',
                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PedidoRef {
  final String id, numero, cliente, casillero;
  const _PedidoRef({required this.id, required this.numero, required this.cliente, required this.casillero});
}

InputDecoration _guiDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
  errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC62828))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC62828), width: 2)),
);