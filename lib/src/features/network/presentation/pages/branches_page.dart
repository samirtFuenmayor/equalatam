// lib/src/features/network/presentation/pages/branches_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../domain/models/sucursal_model.dart';
import '../bloc/sucursal_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<SucursalBloc>()..add(SucursalLoadAll()),
      child: const _BranchesView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _BranchesView extends StatefulWidget {
  const _BranchesView();
  @override
  State<_BranchesView> createState() => _BranchesViewState();
}

class _BranchesViewState extends State<_BranchesView> {
  final _searchCtrl = TextEditingController();
  String       _q        = '';
  TipoSucursal? _tipoFilt; // null = todas
  bool         _soloActivas = false;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  // ── Filtro client-side ────────────────────────────────────────────────────
  List<SucursalModel> _filter(List<SucursalModel> src) {
    return src.where((s) {
      final q    = _q.toLowerCase();
      final okQ  = _q.isEmpty ||
          s.nombre.toLowerCase().contains(q)  ||
          s.codigo.toLowerCase().contains(q)  ||
          s.ciudad.toLowerCase().contains(q)  ||
          s.pais.toLowerCase().contains(q)    ||
          (s.responsable?.toLowerCase().contains(q) ?? false);
      final okT  = _tipoFilt == null || s.tipo == _tipoFilt;
      final okA  = !_soloActivas || s.activa;
      return okQ && okT && okA;
    }).toList();
  }

  // ── Sheets ────────────────────────────────────────────────────────────────
  void _openForm(BuildContext ctx, {SucursalModel? suc}) {
    showModalBottomSheet(
        context: ctx, isScrollControlled: true,
        useSafeArea: true, backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
            value: ctx.read<SucursalBloc>(),
            child: _SucursalFormSheet(sucursal: suc)));
  }

  void _openDetail(BuildContext ctx, SucursalModel suc) {
    showModalBottomSheet(
        context: ctx, isScrollControlled: true,
        useSafeArea: true, backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
            value: ctx.read<SucursalBloc>(),
            child: _SucursalDetailSheet(sucursal: suc,
                onEdit: () { Navigator.pop(ctx); _openForm(ctx, suc: suc); })));
  }

  // ── Toggle activo/inactivo ────────────────────────────────────────────────
  void _toggle(BuildContext ctx, SucursalModel suc) {
    if (suc.activa) {
      _confirmDesactivar(ctx, suc);
    } else {
      ctx.read<SucursalBloc>().add(SucursalReactivarRequested(suc.id));
    }
  }

  void _confirmDesactivar(BuildContext ctx, SucursalModel suc) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0), shape: BoxShape.circle),
            child: const Icon(Icons.pause_circle_outline_rounded,
                color: Color(0xFFE65100), size: 28)),
        title: const Text('Desactivar sucursal',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        content: Text(
            '¿Desactivar "${suc.nombre}"?\n'
                'Podrás reactivarla más adelante.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(d),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280)))),
          const SizedBox(width: 8),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(d);
                ctx.read<SucursalBloc>()
                    .add(SucursalDesactivarRequested(suc.id));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Desactivar')),
        ],
      ),
    );
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────
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

    return BlocConsumer<SucursalBloc, SucursalState>(
      listener: (ctx, state) {
        if (state is SucursalLoaded && state.message != null)
          _snack(ctx, state.message!, ok: true);
        if (state is SucursalError) _snack(ctx, state.message, ok: false);
      },
      builder: (ctx, state) {
        final all = switch (state) {
          SucursalLoaded s => s.sucursales,
          SucursalError s  => s.sucursales,
          _                => <SucursalModel>[],
        };
        final filtered = _filter(all);
        final loading  = state is SucursalLoading;
        final errOnly  = state is SucursalError && all.isEmpty;

        // Estadísticas
        final totalActivas  = all.where((s) => s.activa).length;
        final totalInact    = all.where((s) => !s.activa).length;
        final totalIntl     = all.where((s) => s.tipo == TipoSucursal.INTERNACIONAL).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            // ── Header ──────────────────────────────────────────────────────
            _SucHeader(
              total: all.length,
              onAdd:     () => _openForm(ctx),
              onRefresh: () => ctx.read<SucursalBloc>().add(SucursalLoadAll()),
            ),
            // ── Stats rápidas ────────────────────────────────────────────────
            if (all.isNotEmpty)
              _StatsRow(
                activas: totalActivas,
                inactivas: totalInact,
                internacionales: totalIntl,
              ),
            // ── Filtros ──────────────────────────────────────────────────────
            _FilterBar(
              searchCtrl: _searchCtrl,
              tipoFilt:   _tipoFilt,
              soloActivas: _soloActivas,
              onSearch:   (v) => setState(() => _q = v),
              onTipo:     (t) => setState(() => _tipoFilt = t),
              onActivas:  (v) => setState(() => _soloActivas = v),
            ),
            // ── Cuerpo ───────────────────────────────────────────────────────
            Expanded(child: _body(ctx, state, filtered, loading, errOnly, isDesktop)),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext ctx, SucursalState state,
      List<SucursalModel> filtered, bool loading, bool errOnly, bool isDesktop) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }
    if (errOnly) {
      return _SucErrorView(
        message: (state as SucursalError).message,
        onRetry: () => ctx.read<SucursalBloc>().add(SucursalLoadAll()),
      );
    }
    if (filtered.isEmpty) {
      return _SucEmptyView(hasFilter: _q.isNotEmpty || _tipoFilt != null || _soloActivas);
    }
    return isDesktop
        ? _SucursalTable(
      sucursales: filtered,
      onDetail: (s) => _openDetail(ctx, s),
      onEdit:   (s) => _openForm(ctx, suc: s),
      onToggle: (s) => _toggle(ctx, s),
    )
        : _SucursalCards(
      sucursales: filtered,
      onDetail: (s) => _openDetail(ctx, s),
      onEdit:   (s) => _openForm(ctx, suc: s),
      onToggle: (s) => _toggle(ctx, s),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _SucHeader extends StatelessWidget {
  final int total;
  final VoidCallback onAdd, onRefresh;
  const _SucHeader({required this.total, required this.onAdd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gestión de Sucursales',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Text('$total sucursal${total == 1 ? '' : 'es'} registrada${total == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ])),
        IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
            onPressed: onRefresh, tooltip: 'Actualizar'),
        const SizedBox(width: 6),
        SizedBox(height: 42,
            child: ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12)),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(isWide ? 'Nueva sucursal' : 'Nueva',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))),
      ]),
    );
  }
}

// ─── STATS ROW ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int activas, inactivas, internacionales;
  const _StatsRow({required this.activas, required this.inactivas,
    required this.internacionales});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(children: [
        _StatCard(label: 'Activas',         value: activas,
            color: const Color(0xFF2E7D32), icon: Icons.check_circle_outline),
        const SizedBox(width: 10),
        _StatCard(label: 'Inactivas',       value: inactivas,
            color: const Color(0xFF9CA3AF), icon: Icons.pause_circle_outline),
        const SizedBox(width: 10),
        _StatCard(label: 'Internacionales', value: internacionales,
            color: const Color(0xFF1A237E), icon: Icons.flight_outlined),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String   label;
  final int      value;
  final Color    color;
  final IconData icon;
  const _StatCard({required this.label, required this.value,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(
              fontSize: 10, color: Color(0xFF6B7280))),
        ]),
      ]),
    ),
  );
}

// ─── BARRA DE FILTROS ─────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final TipoSucursal?  tipoFilt;
  final bool           soloActivas;
  final void Function(String)       onSearch;
  final void Function(TipoSucursal?) onTipo;
  final void Function(bool)         onActivas;

  const _FilterBar({
    required this.searchCtrl, required this.tipoFilt,
    required this.soloActivas, required this.onSearch,
    required this.onTipo, required this.onActivas,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    final search = _SucSearchField(
      ctrl: searchCtrl,
      hint: 'Buscar por nombre, código, ciudad...',
      onChanged: onSearch,
    );

    final tipoDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TipoSucursal?>(
          value: tipoFilt,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280)),
          items: [
            const DropdownMenuItem(value: null,
                child: Text('Todos los tipos',
                    style: TextStyle(fontSize: 13))),
            ...TipoSucursal.values.map((t) => DropdownMenuItem(
              value: t,
              child: Row(children: [
                Icon(_tipoIcon(t), size: 14, color: _tipoColor(t)),
                const SizedBox(width: 6),
                Text(t.label, style: const TextStyle(fontSize: 13)),
              ]),
            )),
          ],
          onChanged: onTipo,
        ),
      ),
    );

    final activasSwitch = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('Solo activas',
            style: TextStyle(fontSize: 13, color: Color(0xFF374151))),
        const SizedBox(width: 8),
        Switch(
          value: soloActivas, onChanged: onActivas,
          activeColor: const Color(0xFF1A237E),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: isWide
          ? Row(children: [
        Expanded(child: search),
        const SizedBox(width: 10),
        tipoDropdown,
        const SizedBox(width: 10),
        activasSwitch,
      ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        search,
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: tipoDropdown),
          const SizedBox(width: 10),
          activasSwitch,
        ]),
      ]),
    );
  }

  IconData _tipoIcon(TipoSucursal t) => switch (t) {
    TipoSucursal.MATRIZ        => Icons.home_work_outlined,
    TipoSucursal.NACIONAL      => Icons.location_city_outlined,
    TipoSucursal.INTERNACIONAL => Icons.flight_outlined,
  };

  Color _tipoColor(TipoSucursal t) => switch (t) {
    TipoSucursal.MATRIZ        => const Color(0xFF7B1FA2),
    TipoSucursal.NACIONAL      => const Color(0xFF1A237E),
    TipoSucursal.INTERNACIONAL => const Color(0xFFE65100),
  };
}

// ─── TABLA DESKTOP ────────────────────────────────────────────────────────────
class _SucursalTable extends StatelessWidget {
  final List<SucursalModel> sucursales;
  final void Function(SucursalModel) onDetail, onEdit, onToggle;
  const _SucursalTable({required this.sucursales, required this.onDetail,
    required this.onEdit, required this.onToggle});

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
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(1.5),
              5: FixedColumnWidth(130),
            },
            children: [
              // Encabezado
              TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    'Sucursal', 'Código', 'Tipo', 'Ubicación', 'Estado', 'Acciones'
                  ].map((h) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Text(h, style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280))))).toList()),
              // Filas
              ...sucursales.map((s) => TableRow(
                  decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Color(0xFFE5E7EB)))),
                  children: [
                    // Nombre + prefijo
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(children: [
                          _SucAvatar(suc: s),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.nombre, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13,
                                        color: s.activa
                                            ? const Color(0xFF1A1A2E)
                                            : const Color(0xFF9CA3AF))),
                                Text(s.prefijoCasillero,
                                    style: const TextStyle(
                                        fontSize: 10, color: Color(0xFF9CA3AF))),
                              ])),
                        ])),
                    // Código
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Text(s.codigo,
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'monospace',
                                color: Color(0xFF374151)))),
                    // Tipo
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: _TipoBadge(tipo: s.tipo)),
                    // Ubicación
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Text(s.ubicacion,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF374151)))),
                    // Estado
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: _EstadoBadge(activa: s.activa)),
                    // Acciones
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(children: [
                          _SucBtn(
                              icon: Icons.visibility_outlined,
                              color: const Color(0xFF1A237E),
                              tip: 'Ver detalle',
                              onTap: () => onDetail(s)),
                          const SizedBox(width: 4),
                          _SucBtn(
                              icon: Icons.edit_outlined,
                              color: const Color(0xFF7B1FA2),
                              tip: 'Editar',
                              onTap: () => onEdit(s)),
                          const SizedBox(width: 4),
                          _SucBtn(
                              icon: s.activa
                                  ? Icons.pause_circle_outline_rounded
                                  : Icons.play_circle_outline_rounded,
                              color: s.activa
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF2E7D32),
                              tip: s.activa ? 'Desactivar' : 'Reactivar',
                              onTap: () => onToggle(s)),
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
class _SucursalCards extends StatelessWidget {
  final List<SucursalModel> sucursales;
  final void Function(SucursalModel) onDetail, onEdit, onToggle;
  const _SucursalCards({required this.sucursales, required this.onDetail,
    required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    itemCount: sucursales.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _SucCard(
      suc: sucursales[i],
      onDetail: () => onDetail(sucursales[i]),
      onEdit:   () => onEdit(sucursales[i]),
      onToggle: () => onToggle(sucursales[i]),
    ),
  );
}

class _SucCard extends StatelessWidget {
  final SucursalModel suc;
  final VoidCallback onDetail, onEdit, onToggle;
  const _SucCard({required this.suc,
    required this.onDetail, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: suc.activa
            ? const Color(0xFFE5E7EB) : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabecera
        Row(children: [
          _SucAvatar(suc: suc),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suc.nombre, style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15,
                    color: suc.activa
                        ? const Color(0xFF1A1A2E) : const Color(0xFF9CA3AF))),
                Text('${suc.codigo} · ${suc.prefijoCasillero}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: Color(0xFF9CA3AF), size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'detail', child: Row(children: [
                const Icon(Icons.visibility_outlined, size: 18,
                    color: Color(0xFF1A237E)),
                const SizedBox(width: 10), const Text('Ver detalle')])),
              PopupMenuItem(value: 'edit', child: Row(children: [
                const Icon(Icons.edit_outlined, size: 18,
                    color: Color(0xFF7B1FA2)),
                const SizedBox(width: 10), const Text('Editar')])),
              PopupMenuItem(value: 'toggle', child: Row(children: [
                Icon(suc.activa
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                    size: 18,
                    color: suc.activa
                        ? const Color(0xFFE65100) : const Color(0xFF2E7D32)),
                const SizedBox(width: 10),
                Text(suc.activa ? 'Desactivar' : 'Reactivar')])),
            ],
            onSelected: (v) {
              if (v == 'detail') onDetail();
              if (v == 'edit')   onEdit();
              if (v == 'toggle') onToggle();
            },
          ),
        ]),
        const SizedBox(height: 12),
        // Info
        Row(children: [
          _InfoChip(
              icon: Icons.location_on_outlined, label: suc.ubicacion),
          const SizedBox(width: 8),
          _TipoBadge(tipo: suc.tipo),
          const SizedBox(width: 8),
          _EstadoBadge(activa: suc.activa),
        ]),
        if (suc.responsable != null && suc.responsable!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person_outline_rounded,
                size: 14, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(suc.responsable!,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
          ]),
        ],
        const SizedBox(height: 12),
        // Botón ver detalle
        SizedBox(width: double.infinity,
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
}

// ─── SHEET DETALLE ────────────────────────────────────────────────────────────
class _SucursalDetailSheet extends StatelessWidget {
  final SucursalModel sucursal;
  final VoidCallback  onEdit;
  const _SucursalDetailSheet(
      {required this.sucursal, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return _SucSheet(
      title: sucursal.nombre,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Badges
        Row(children: [
          _TipoBadge(tipo: sucursal.tipo),
          const SizedBox(width: 8),
          _EstadoBadge(activa: sucursal.activa),
          const SizedBox(width: 8),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(sucursal.prefijoCasillero,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFF374151)))),
        ]),
        const SizedBox(height: 20),
        // Campos de detalle
        _DetailRow(icon: Icons.qr_code_rounded,
            label: 'Código', value: sucursal.codigo),
        _DetailRow(icon: Icons.flag_outlined,
            label: 'País', value: sucursal.pais),
        _DetailRow(icon: Icons.location_city_outlined,
            label: 'Ciudad', value: sucursal.ciudad),
        _DetailRow(icon: Icons.map_outlined,
            label: 'Dirección', value: sucursal.direccion),
        if (sucursal.telefono != null && sucursal.telefono!.isNotEmpty)
          _DetailRow(icon: Icons.phone_outlined,
              label: 'Teléfono', value: sucursal.telefono!),
        if (sucursal.email != null && sucursal.email!.isNotEmpty)
          _DetailRow(icon: Icons.email_outlined,
              label: 'Email', value: sucursal.email!),
        if (sucursal.responsable != null && sucursal.responsable!.isNotEmpty)
          _DetailRow(icon: Icons.person_outline_rounded,
              label: 'Responsable', value: sucursal.responsable!),
        if (sucursal.creadoEn != null)
          _DetailRow(icon: Icons.calendar_today_outlined,
              label: 'Creado',
              value: _fmtDate(sucursal.creadoEn!)),
        const SizedBox(height: 20),
        // Botón editar
        _SucSubmitBtn(label: 'Editar sucursal', onTap: onEdit),
      ]),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(
              fontSize: 14, color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}

// ─── SHEET FORMULARIO ─────────────────────────────────────────────────────────
class _SucursalFormSheet extends StatefulWidget {
  final SucursalModel? sucursal;
  const _SucursalFormSheet({this.sucursal});
  @override
  State<_SucursalFormSheet> createState() => _SucursalFormSheetState();
}

class _SucursalFormSheetState extends State<_SucursalFormSheet> {
  final _key      = GlobalKey<FormState>();
  late final TextEditingController _nombre    = TextEditingController();
  late final TextEditingController _codigo    = TextEditingController();
  late final TextEditingController _pais      = TextEditingController();
  late final TextEditingController _ciudad    = TextEditingController();
  late final TextEditingController _direccion = TextEditingController();
  late final TextEditingController _telefono  = TextEditingController();
  late final TextEditingController _email     = TextEditingController();
  late final TextEditingController _respons   = TextEditingController();
  late final TextEditingController _prefijo   = TextEditingController();
  TipoSucursal _tipo = TipoSucursal.NACIONAL;

  bool get _isEdit => widget.sucursal != null;

  @override
  void initState() {
    super.initState();
    final s = widget.sucursal;
    if (s != null) {
      _nombre.text    = s.nombre;
      _codigo.text    = s.codigo;
      _pais.text      = s.pais;
      _ciudad.text    = s.ciudad;
      _direccion.text = s.direccion;
      _telefono.text  = s.telefono ?? '';
      _email.text     = s.email    ?? '';
      _respons.text   = s.responsable ?? '';
      _prefijo.text   = s.prefijoCasillero;
      _tipo           = s.tipo;
    }
  }

  @override
  void dispose() {
    _nombre.dispose(); _codigo.dispose(); _pais.dispose();
    _ciudad.dispose(); _direccion.dispose(); _telefono.dispose();
    _email.dispose();  _respons.dispose(); _prefijo.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final data = {
      'nombre':           _nombre.text.trim(),
      'codigo':           _codigo.text.trim().toUpperCase(),
      'tipo':             _tipo.name,
      'pais':             _pais.text.trim(),
      'ciudad':           _ciudad.text.trim(),
      'direccion':        _direccion.text.trim(),
      'telefono':         _telefono.text.trim(),
      'email':            _email.text.trim(),
      'responsable':      _respons.text.trim(),
      'prefijoCasillero': _prefijo.text.trim().toUpperCase(),
    };
    if (_isEdit) {
      context.read<SucursalBloc>()
          .add(SucursalUpdateRequested(widget.sucursal!.id, data));
    } else {
      context.read<SucursalBloc>().add(SucursalCreateRequested(data));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _SucSheet(
      title: _isEdit ? 'Editar sucursal' : 'Nueva sucursal',
      child: Form(
        key: _key,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Tipo de sucursal ────────────────────────────────────────────
          _SucLabel('Tipo de sucursal'),
          const SizedBox(height: 8),
          Row(children: TipoSucursal.values.map((t) {
            final sel = _tipo == t;
            return Expanded(child: Padding(
              padding: EdgeInsets.only(
                  right: t != TipoSucursal.values.last ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _tipo = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: sel
                          ? _tipoColor(t).withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? _tipoColor(t) : const Color(0xFFE5E7EB),
                          width: sel ? 2 : 1)),
                  child: Column(children: [
                    Icon(_tipoIcon(t), color: _tipoColor(t), size: 20),
                    const SizedBox(height: 4),
                    Text(t.label, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: _tipoColor(t))),
                  ]),
                ),
              ),
            ));
          }).toList()),
          const SizedBox(height: 16),

          // ── Nombre ─────────────────────────────────────────────────────
          _SucLabel('Nombre de la sucursal *'),
          const SizedBox(height: 8),
          TextFormField(
              controller: _nombre,
              decoration: _deco('Ej: Sucursal Riobamba'),
              validator: _req),
          const SizedBox(height: 14),

          // ── Código y Prefijo ────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SucLabel('Código *'),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _codigo,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _deco('Ej: RIO-001'),
                      validator: _req),
                ])),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SucLabel('Prefijo casillero *'),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _prefijo,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _deco('Ej: RIO'),
                      validator: _req),
                ])),
          ]),
          const SizedBox(height: 14),

          // ── País y Ciudad ───────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SucLabel('País *'),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _pais,
                      decoration: _deco('Ej: Ecuador'),
                      validator: _req),
                ])),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SucLabel('Ciudad *'),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _ciudad,
                      decoration: _deco('Ej: Riobamba'),
                      validator: _req),
                ])),
          ]),
          const SizedBox(height: 14),

          // ── Dirección ───────────────────────────────────────────────────
          _SucLabel('Dirección *'),
          const SizedBox(height: 8),
          TextFormField(
              controller: _direccion, maxLines: 2,
              decoration: _deco('Av. Daniel León Borja y Uruguay'),
              validator: _req),
          const SizedBox(height: 14),

          // ── Teléfono y Email ────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SucLabel('Teléfono'),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _telefono,
                      keyboardType: TextInputType.phone,
                      decoration: _deco('0987654321')),
                ])),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SucLabel('Email'),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _deco('sucursal@equalatam.com'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (!v.contains('@')) return 'Email inválido';
                        return null;
                      }),
                ])),
          ]),
          const SizedBox(height: 14),

          // ── Responsable ─────────────────────────────────────────────────
          _SucLabel('Responsable'),
          const SizedBox(height: 8),
          TextFormField(
              controller: _respons,
              decoration: _deco('Nombre del responsable')),
          const SizedBox(height: 24),

          _SucSubmitBtn(
              label: _isEdit ? 'Guardar cambios' : 'Crear sucursal',
              onTap: _submit),
        ]),
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  Color _tipoColor(TipoSucursal t) => switch (t) {
    TipoSucursal.MATRIZ        => const Color(0xFF7B1FA2),
    TipoSucursal.NACIONAL      => const Color(0xFF1A237E),
    TipoSucursal.INTERNACIONAL => const Color(0xFFE65100),
  };
  IconData _tipoIcon(TipoSucursal t) => switch (t) {
    TipoSucursal.MATRIZ        => Icons.home_work_outlined,
    TipoSucursal.NACIONAL      => Icons.location_city_outlined,
    TipoSucursal.INTERNACIONAL => Icons.flight_outlined,
  };
}

// ─── WIDGETS PROPIOS DEL MÓDULO ───────────────────────────────────────────────

class _SucAvatar extends StatelessWidget {
  final SucursalModel suc;
  const _SucAvatar({required this.suc});

  Color get _c => switch (suc.tipo) {
    TipoSucursal.MATRIZ        => const Color(0xFF7B1FA2),
    TipoSucursal.NACIONAL      => const Color(0xFF1A237E),
    TipoSucursal.INTERNACIONAL => const Color(0xFFE65100),
  };
  IconData get _icon => switch (suc.tipo) {
    TipoSucursal.MATRIZ        => Icons.home_work_outlined,
    TipoSucursal.NACIONAL      => Icons.location_city_outlined,
    TipoSucursal.INTERNACIONAL => Icons.flight_outlined,
  };

  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
        color: suc.activa
            ? _c.withOpacity(0.12)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10)),
    child: Icon(_icon,
        color: suc.activa ? _c : const Color(0xFF9CA3AF), size: 18),
  );
}

class _TipoBadge extends StatelessWidget {
  final TipoSucursal tipo;
  const _TipoBadge({required this.tipo});

  Color get _c => switch (tipo) {
    TipoSucursal.MATRIZ        => const Color(0xFF7B1FA2),
    TipoSucursal.NACIONAL      => const Color(0xFF1A237E),
    TipoSucursal.INTERNACIONAL => const Color(0xFFE65100),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: _c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _c.withOpacity(0.2))),
    child: Text(tipo.label, style: TextStyle(
        color: _c, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _EstadoBadge extends StatelessWidget {
  final bool activa;
  const _EstadoBadge({required this.activa});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: activa
            ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: BoxDecoration(
              color: activa
                  ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
              shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(activa ? 'Activa' : 'Inactiva',
          style: TextStyle(
              color: activa
                  ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
              fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
    const SizedBox(width: 4),
    Flexible(child: Text(label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
  ]);
}

class _SucBtn extends StatelessWidget {
  final IconData icon; final Color color;
  final String tip; final VoidCallback onTap;
  const _SucBtn({required this.icon, required this.color,
    required this.tip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
            borderRadius: BorderRadius.circular(8), onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(7),
                child: Icon(icon, color: color, size: 16)))),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS BASE — autosuficientes (sin depender de archivos externos)
// ═════════════════════════════════════════════════════════════════════════════

class _SucSheet extends StatelessWidget {
  final String title; final Widget child;
  const _SucSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        Flexible(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
      ]),
    );
  }
}

class _SucLabel extends StatelessWidget {
  final String text; const _SucLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: Color(0xFF374151)));
}

class _SucSubmitBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  final Color color;
  const _SucSubmitBtn({required this.label, required this.onTap,
    this.color = const Color(0xFF1A237E)});

  @override
  Widget build(BuildContext context) => SizedBox(height: 50,
      child: ElevatedButton(onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: color, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
          child: Text(label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600))));
}

class _SucSearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint; final void Function(String) onChanged;
  const _SucSearchField({required this.ctrl, required this.hint,
    required this.onChanged});

  OutlineInputBorder _b({Color? c, double w = 1}) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12),
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
      contentPadding:
      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: _b(), enabledBorder: _b(),
      focusedBorder: _b(c: const Color(0xFF1A237E), w: 2),
    ),
  );
}

class _SucEmptyView extends StatelessWidget {
  final bool hasFilter;
  const _SucEmptyView({required this.hasFilter});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: Color(0xFFE8EAF6), shape: BoxShape.circle),
                child: const Icon(Icons.business_outlined,
                    size: 48, color: Color(0xFF1A237E))),
            const SizedBox(height: 16),
            Text(hasFilter ? 'Sin resultados' : 'No hay sucursales',
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            Text(hasFilter
                ? 'Intenta con otro término o filtro'
                : 'Crea la primera sucursal con "Nueva sucursal"',
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                textAlign: TextAlign.center),
          ])));
}

class _SucErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _SucErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(padding: const EdgeInsets.all(32),
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
          ])));
}

InputDecoration _deco(String hint, {Widget? suf}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
  suffixIcon: suf, filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  border:             _ib(), enabledBorder: _ib(),
  focusedBorder:      _ib(c: const Color(0xFF1A237E), w: 2),
  errorBorder:        _ib(c: const Color(0xFFC62828)),
  focusedErrorBorder: _ib(c: const Color(0xFFC62828), w: 2),
);

OutlineInputBorder _ib({Color? c, double w = 1}) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: c ?? const Color(0xFFE5E7EB), width: w));