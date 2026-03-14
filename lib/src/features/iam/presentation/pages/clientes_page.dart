// lib/src/features/clientes/presentation/pages/clientes_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../domain/models/cliente_model.dart';
import '../bloc/cliente_bloc.dart';
import '../../../network/presentation/domain/models/sucursal_model.dart';
import '../../../network/presentation/bloc/sucursal_bloc.dart';

// ─── Helpers de color/icono por estado ───────────────────────────────────────
Color _estadoColor(EstadoCliente e) => switch (e) {
  EstadoCliente.ACTIVO     => const Color(0xFF2E7D32),
  EstadoCliente.SUSPENDIDO => const Color(0xFFE65100),
  EstadoCliente.INACTIVO   => const Color(0xFF9CA3AF),
};

Color _tipoIdColor(TipoIdentificacion t) => switch (t) {
  TipoIdentificacion.CEDULA    => const Color(0xFF1A237E),
  TipoIdentificacion.RUC       => const Color(0xFF7B1FA2),
  TipoIdentificacion.PASAPORTE => const Color(0xFF00695C),
};

Color _avatarColor(String iniciales) {
  final colors = [
    const Color(0xFF1A237E),
    const Color(0xFF7B1FA2),
    const Color(0xFF00695C),
    const Color(0xFFE65100),
    const Color(0xFF1565C0),
    const Color(0xFF283593),
  ];
  return colors[iniciales.codeUnitAt(0) % colors.length];
}

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  try {
    final d = DateTime.parse(raw);
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  } catch (_) {
    return raw.split('T').first;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<ClienteBloc>()..add(ClientesLoadRequested()),
        ),
        BlocProvider(
          create: (_) => di.sl<SucursalBloc>()..add(SucursalLoadAll()),
        ),
      ],
      child: const _ClientesView(),
    );
  }
}

// ─── View ─────────────────────────────────────────────────────────────────────
class _ClientesView extends StatefulWidget {
  const _ClientesView();
  @override
  State<_ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<_ClientesView> {
  final _searchCtrl = TextEditingController();
  String         _q          = '';
  EstadoCliente? _estadoFilt;
  bool           _soloActivos = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClienteModel> _filter(List<ClienteModel> src) {
    return src.where((c) {
      final q   = _q.toLowerCase();
      final okQ = _q.isEmpty ||
          c.nombres.toLowerCase().contains(q) ||
          c.apellidos.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.numeroIdentificacion.toLowerCase().contains(q) ||
          (c.casillero?.toLowerCase().contains(q) ?? false) ||
          (c.sucursalNombre?.toLowerCase().contains(q) ?? false);
      final okE = _estadoFilt == null || c.estado == _estadoFilt;
      final okA = !_soloActivos || c.estado == EstadoCliente.ACTIVO;
      return okQ && okE && okA;
    }).toList();
  }

  void _ok(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
      ));
  }

  void _openForm(BuildContext ctx, [ClienteModel? c]) {
    final sucursales = _getSucursales(ctx);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<ClienteBloc>(),
        child: _ClienteFormSheet(cliente: c, sucursales: sucursales),
      ),
    );
  }

  void _openDetail(BuildContext ctx, ClienteModel c) {
    final sucursales = _getSucursales(ctx);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<ClienteBloc>(),
        child: _ClienteDetailSheet(
          cliente: c,
          sucursales: sucursales,
          onEdit: () {
            Navigator.pop(ctx);
            _openForm(ctx, c);
          },
          onEstado: () {
            Navigator.pop(ctx);
            _openEstadoDialog(ctx, c);
          },
          onSucursal: () {
            Navigator.pop(ctx);
            _openSucursalDialog(ctx, c, sucursales);
          },
        ),
      ),
    );
  }

  void _openEstadoDialog(BuildContext ctx, ClienteModel c) {
    EstadoCliente selected = c.estado;
    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (_, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cambiar estado',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(c.nombreCompleto,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.normal)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: EstadoCliente.values
                .map((e) => RadioListTile<EstadoCliente>(
              value: e,
              groupValue: selected,
              onChanged: (v) => setSt(() => selected = v!),
              activeColor: _estadoColor(e),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              title: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _estadoColor(e),
                        shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(e.label,
                    style: const TextStyle(fontSize: 14)),
              ]),
            ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _estadoColor(selected),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dCtx);
                ctx
                    .read<ClienteBloc>()
                    .add(ClienteEstadoRequested(c.id, selected));
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSucursalDialog(
      BuildContext ctx, ClienteModel c, List<SucursalModel> sucursales) {
    String? selectedId = c.sucursalId;
    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (_, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Asignar sucursal',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(c.nombreCompleto,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.normal)),
          ]),
          content: SizedBox(
            width: 340,
            child: sucursales.isEmpty
                ? const Text('No hay sucursales disponibles')
                : DropdownButtonFormField<String>(
              value: selectedId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                labelText: 'Sucursal',
              ),
              items: sucursales
                  .map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(
                    '${s.nombre} (${s.prefijoCasillero})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
              ))
                  .toList(),
              onChanged: (v) => setSt(() => selectedId = v),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: selectedId == null
                  ? null
                  : () {
                Navigator.pop(dCtx);
                ctx.read<ClienteBloc>().add(
                    ClienteSucursalRequested(c.id, selectedId!));
              },
              child: const Text('Asignar'),
            ),
          ],
        ),
      ),
    );
  }

  List<SucursalModel> _getSucursales(BuildContext ctx) {
    final state = ctx.read<SucursalBloc>().state;
    if (state is SucursalLoaded) return state.sucursales;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return BlocConsumer<ClienteBloc, ClienteState>(
      listener: (ctx, state) {
        if (state is ClientesLoaded && state.message != null) {
          _ok(state.message!);
        }
        if (state is ClienteAfiliadosLoaded && state.message != null) {
          _ok(state.message!);
        }
        if (state is ClienteError) _err(state.message);
      },
      builder: (ctx, state) {
        // ✅ switch exhaustivo que incluye el nuevo estado de afiliados
        final all = switch (state) {
          ClientesLoaded        s => s.clientes,
          ClienteAfiliadosLoaded s => s.clientes,
          ClienteError          s => s.clientes,
          _                       => <ClienteModel>[],
        };
        final filtered = _filter(all);
        final loading  = state is ClienteLoading;
        final errOnly  = state is ClienteError && all.isEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            _Header(
              total:     all.length,
              onAdd:     () => _openForm(ctx),
              onRefresh: () =>
                  ctx.read<ClienteBloc>().add(ClientesLoadRequested()),
            ),
            if (all.isNotEmpty) _StatsRow(clientes: all),
            _FilterBar(
              searchCtrl:  _searchCtrl,
              estadoFilt:  _estadoFilt,
              soloActivos: _soloActivos,
              onSearch:    (v) => setState(() => _q = v),
              onEstado:    (e) => setState(() => _estadoFilt = e),
              onActivos:   (v) => setState(() => _soloActivos = v),
            ),
            Expanded(
              child: _buildBody(
                  ctx, state, filtered, loading, errOnly, isDesktop),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildBody(BuildContext ctx, ClienteState state,
      List<ClienteModel> filtered, bool loading, bool errOnly,
      bool isDesktop) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }
    if (errOnly) {
      return _ErrorView(
        message: (state as ClienteError).message,
        onRetry: () =>
            ctx.read<ClienteBloc>().add(ClientesLoadRequested()),
      );
    }
    if (filtered.isEmpty) {
      return _EmptyView(
        hasFilter: _q.isNotEmpty || _estadoFilt != null || _soloActivos,
        onAdd: () => _openForm(ctx),
      );
    }
    return isDesktop
        ? _DesktopTable(
      items:    filtered,
      onDetail: (c) => _openDetail(ctx, c),
      onEdit:   (c) => _openForm(ctx, c),
      onEstado: (c) => _openEstadoDialog(ctx, c),
    )
        : _MobileCards(
      items:    filtered,
      onDetail: (c) => _openDetail(ctx, c),
      onEdit:   (c) => _openForm(ctx, c),
      onEstado: (c) => _openEstadoDialog(ctx, c),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HEADER  — sin cambios
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final int total;
  final VoidCallback onAdd, onRefresh;
  const _Header(
      {required this.total, required this.onAdd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(children: [
        Expanded(
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Gestión de Clientes',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            Text(
                '$total cliente${total == 1 ? '' : 's'} registrado${total == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
          ]),
        ),
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
                padding:
                EdgeInsets.symmetric(horizontal: isWide ? 16 : 12)),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: Text(isWide ? 'Nuevo cliente' : 'Nuevo',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATS ROW  — sin cambios
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final List<ClienteModel> clientes;
  const _StatsRow({required this.clientes});

  @override
  Widget build(BuildContext context) {
    final activos =
        clientes.where((c) => c.estado == EstadoCliente.ACTIVO).length;
    final suspendidos =
        clientes.where((c) => c.estado == EstadoCliente.SUSPENDIDO).length;
    final conCasillero =
        clientes.where((c) => c.casillero != null).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _StatChip('Activos', activos, const Color(0xFF2E7D32),
              Icons.check_circle_outline),
          const SizedBox(width: 10),
          _StatChip('Suspendidos', suspendidos, const Color(0xFFE65100),
              Icons.pause_circle_outline),
          const SizedBox(width: 10),
          _StatChip('Con casillero', conCasillero, const Color(0xFF1A237E),
              Icons.inbox_rounded),
        ]),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;
  final IconData icon;
  const _StatChip(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF6B7280))),
      ]),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FILTER BAR  — sin cambios
// ═══════════════════════════════════════════════════════════════════════════════

class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final EstadoCliente?        estadoFilt;
  final bool                  soloActivos;
  final void Function(String)         onSearch;
  final void Function(EstadoCliente?) onEstado;
  final void Function(bool)           onActivos;

  const _FilterBar({
    required this.searchCtrl,
    required this.estadoFilt,
    required this.soloActivos,
    required this.onSearch,
    required this.onEstado,
    required this.onActivos,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    final searchField = _SearchField(
      ctrl:      searchCtrl,
      hint:      'Buscar por nombre, cédula, casillero...',
      onChanged: onSearch,
    );

    final estadoDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EstadoCliente?>(
          value: estadoFilt,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280)),
          items: [
            const DropdownMenuItem(
                value: null,
                child: Text('Todos', style: TextStyle(fontSize: 13))),
            ...EstadoCliente.values.map((e) => DropdownMenuItem(
              value: e,
              child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _estadoColor(e), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(e.label, style: const TextStyle(fontSize: 13)),
              ]),
            )),
          ],
          onChanged: onEstado,
        ),
      ),
    );

    final activosSwitch = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('Solo activos',
            style: TextStyle(fontSize: 13, color: Color(0xFF374151))),
        const SizedBox(width: 6),
        Switch(
          value: soloActivos,
          onChanged: onActivos,
          activeColor: const Color(0xFF1A237E),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: isWide
          ? Row(children: [
        Expanded(child: searchField),
        const SizedBox(width: 10),
        estadoDropdown,
        const SizedBox(width: 10),
        activosSwitch,
      ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        searchField,
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: estadoDropdown),
          const SizedBox(width: 10),
          activosSwitch,
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP TABLE  — sin cambios
// ═══════════════════════════════════════════════════════════════════════════════

class _DesktopTable extends StatelessWidget {
  final List<ClienteModel> items;
  final void Function(ClienteModel) onDetail, onEdit, onEstado;
  const _DesktopTable(
      {required this.items,
        required this.onDetail,
        required this.onEdit,
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
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.8),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1.5),
              5: FlexColumnWidth(1.2),
              6: FixedColumnWidth(120),
            },
            children: [
              TableRow(
                decoration:
                const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: [
                  'Cliente',
                  'Identificación',
                  'Contacto',
                  'Casillero',
                  'Sucursal',
                  'Estado',
                  'Acciones',
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
                    .toList(),
              ),
              ...items.map((c) => TableRow(
                decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB)))),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(children: [
                      _Avatar(iniciales: c.iniciales),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(c.nombreCompleto,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF1A1A2E))),
                              if (c.ciudad != null)
                                Text(
                                    '${c.ciudad}${c.pais.isNotEmpty ? ', ${c.pais}' : ''}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF))),
                            ]),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TipoIdBadge(tipo: c.tipoIdentificacion),
                          const SizedBox(height: 4),
                          Text(c.numeroIdentificacion,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF374151))),
                        ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF374151))),
                          if (c.telefono != null)
                            Text(c.telefono!,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF))),
                        ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: c.casillero != null
                        ? _CasilleroBadge(casillero: c.casillero!)
                        : const Text('—',
                        style:
                        TextStyle(color: Color(0xFF9CA3AF))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: c.sucursalNombre != null
                        ? Text(c.sucursalNombre!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF374151)))
                        : const Text('Sin asignar',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: _EstadoBadge(estado: c.estado),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _ActionBtn(
                          icon: Icons.visibility_outlined,
                          color: const Color(0xFF1A237E),
                          tip: 'Ver detalle',
                          onTap: () => onDetail(c)),
                      const SizedBox(width: 4),
                      _ActionBtn(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFF7B1FA2),
                          tip: 'Editar',
                          onTap: () => onEdit(c)),
                      const SizedBox(width: 4),
                      _ActionBtn(
                          icon: Icons.swap_horiz_rounded,
                          color: _estadoColor(c.estado),
                          tip: 'Cambiar estado',
                          onTap: () => onEstado(c)),
                    ]),
                  ),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE CARDS  — sin cambios
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileCards extends StatelessWidget {
  final List<ClienteModel> items;
  final void Function(ClienteModel) onDetail, onEdit, onEstado;
  const _MobileCards(
      {required this.items,
        required this.onDetail,
        required this.onEdit,
        required this.onEstado});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    itemCount: items.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) {
      final c = items[i];
      return _ClienteCard(
        c:        c,
        onDetail: () => onDetail(c),
        onEdit:   () => onEdit(c),
        onEstado: () => onEstado(c),
      );
    },
  );
}

class _ClienteCard extends StatelessWidget {
  final ClienteModel c;
  final VoidCallback onDetail, onEdit, onEstado;
  const _ClienteCard(
      {required this.c,
        required this.onDetail,
        required this.onEdit,
        required this.onEstado});

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
        Row(children: [
          _Avatar(iniciales: c.iniciales),
          const SizedBox(width: 12),
          Expanded(
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.nombreCompleto,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
              Text(c.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
            ]),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: Color(0xFF9CA3AF), size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              _mItem('detail', Icons.visibility_outlined, 'Ver detalle',
                  const Color(0xFF1A237E)),
              _mItem('edit', Icons.edit_outlined, 'Editar',
                  const Color(0xFF7B1FA2)),
              _mItem('estado', Icons.swap_horiz_rounded, 'Cambiar estado',
                  _estadoColor(c.estado)),
            ],
            onSelected: (v) {
              if (v == 'detail') onDetail();
              if (v == 'edit')   onEdit();
              if (v == 'estado') onEstado();
            },
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _TipoIdBadge(tipo: c.tipoIdentificacion),
          _EstadoBadge(estado: c.estado),
          if (c.casillero != null) _CasilleroBadge(casillero: c.casillero!),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Text(c.numeroIdentificacion,
              style:
              const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ]),
        if (c.telefono != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.phone_outlined,
                size: 14, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Text(c.telefono!,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF374151))),
          ]),
        ],
        if (c.sucursalNombre != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.business_outlined,
                size: 14, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(c.sucursalNombre!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF374151))),
            ),
          ]),
        ],
        const SizedBox(height: 12),
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
            label:
            const Text('Ver detalle', style: TextStyle(fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  PopupMenuItem<String> _mItem(
      String v, IconData icon, String label, Color color) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(label),
          ]));
}

// ═══════════════════════════════════════════════════════════════════════════════
// DETAIL SHEET ── MODIFICADO: ahora StatefulWidget con tabs
// Solo este widget cambia respecto al original. El resto del archivo es idéntico.
// ═══════════════════════════════════════════════════════════════════════════════

class _ClienteDetailSheet extends StatefulWidget {
  final ClienteModel        cliente;
  final List<SucursalModel> sucursales;
  final VoidCallback        onEdit, onEstado, onSucursal;

  const _ClienteDetailSheet({
    required this.cliente,
    required this.sucursales,
    required this.onEdit,
    required this.onEstado,
    required this.onSucursal,
  });

  @override
  State<_ClienteDetailSheet> createState() => _ClienteDetailSheetState();
}

class _ClienteDetailSheetState extends State<_ClienteDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // Cargar afiliados en segundo plano al abrir el detalle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<ClienteBloc>()
            .add(ClienteAfiliadosRequested(widget.cliente.id));
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
    return _Sheet(
      title:    c.nombreCompleto,
      subtitle: c.email,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Badges superiores ─────────────────────────────────────────────────
        Wrap(spacing: 8, runSpacing: 6, children: [
          _EstadoBadge(estado: c.estado),
          _TipoIdBadge(tipo: c.tipoIdentificacion),
          if (c.casillero != null) _CasilleroBadge(casillero: c.casillero!),
        ]),
        const SizedBox(height: 20),

        // ── Avatar centrado ───────────────────────────────────────────────────
        Center(child: _Avatar(iniciales: c.iniciales, size: 64)),
        const SizedBox(height: 8),
        Center(
          child: Text(c.nombreCompleto,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
        ),
        const SizedBox(height: 16),

        // ── TabBar ────────────────────────────────────────────────────────────
        TabBar(
          controller: _tab,
          labelColor:          const Color(0xFF1A237E),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor:      const Color(0xFF1A237E),
          indicatorSize:       TabBarIndicatorSize.tab,
          dividerColor:        const Color(0xFFE5E7EB),
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline_rounded,    size: 16),
                text: 'Información'),
            Tab(icon: Icon(Icons.people_outline_rounded,  size: 16),
                text: 'Familia'),
          ],
        ),
        const SizedBox(height: 14),

        // ── TabBarView ────────────────────────────────────────────────────────
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.52,
          ),
          child: TabBarView(
            controller: _tab,
            children: [
              // ── Tab 0: Información (contenido original inalterado) ──────────
              SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionTitle('Identificación'),
                      const SizedBox(height: 8),
                      _DRow(Icons.badge_outlined, 'Tipo',
                          c.tipoIdentificacion.label),
                      _DRow(Icons.numbers_rounded, 'Número',
                          c.numeroIdentificacion),
                      const SizedBox(height: 16),

                      _SectionTitle('Datos de contacto'),
                      const SizedBox(height: 8),
                      _DRow(Icons.email_outlined, 'Email', c.email),
                      if (c.telefono != null)
                        _DRow(Icons.phone_outlined, 'Teléfono', c.telefono!),
                      const SizedBox(height: 16),

                      _SectionTitle('Ubicación'),
                      const SizedBox(height: 8),
                      _DRow(Icons.flag_outlined, 'País', c.pais),
                      if (c.provincia != null)
                        _DRow(Icons.map_outlined, 'Provincia', c.provincia!),
                      if (c.ciudad != null)
                        _DRow(Icons.location_city_outlined, 'Ciudad', c.ciudad!),
                      if (c.direccion != null)
                        _DRow(Icons.home_outlined, 'Dirección', c.direccion!),
                      const SizedBox(height: 16),

                      _SectionTitle('Casillero / Sucursal'),
                      const SizedBox(height: 8),
                      if (c.casillero != null)
                        _DRow(Icons.inbox_rounded, 'Casillero', c.casillero!)
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(10),
                              border:
                              Border.all(color: const Color(0xFFFFECB3))),
                          child: const Row(children: [
                            Icon(Icons.info_outline_rounded,
                                color: Color(0xFFFF8F00), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'Este cliente no tiene casillero asignado todavía.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5D4037))),
                            ),
                          ]),
                        ),
                      if (c.sucursalNombre != null) ...[
                        const SizedBox(height: 4),
                        _DRow(Icons.business_outlined, 'Sucursal',
                            '${c.sucursalNombre}${c.sucursalPais != null ? " · ${c.sucursalPais}" : ""}'),
                      ],
                      if (c.creadoEn != null) ...[
                        const SizedBox(height: 4),
                        _DRow(Icons.calendar_today_outlined, 'Registrado',
                            _fmtDate(c.creadoEn)),
                      ],
                      if (c.observaciones != null &&
                          c.observaciones!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SectionTitle('Observaciones'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFFDE7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFFFF176))),
                          child: Text(c.observaciones!,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF5D4037))),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _SheetBtn(
                          label: 'Editar información',
                          icon:  Icons.edit_outlined,
                          onTap: widget.onEdit),
                      const SizedBox(height: 10),
                      _SheetBtn(
                          label:    'Cambiar estado',
                          icon:     Icons.swap_horiz_rounded,
                          color:    _estadoColor(c.estado),
                          onTap:    widget.onEstado,
                          outlined: true),
                      const SizedBox(height: 10),
                      _SheetBtn(
                          label: c.sucursalId != null
                              ? 'Cambiar sucursal'
                              : 'Asignar sucursal y generar casillero',
                          icon:     Icons.business_outlined,
                          color:    const Color(0xFF00695C),
                          onTap:    widget.onSucursal,
                          outlined: true),
                    ]),
              ),

              // ── Tab 1: Familia ──────────────────────────────────────────────
              _FamiliaTab(titularId: widget.cliente.id),
            ],
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB FAMILIA — lista de afiliados con vincular/desvincular
// ═══════════════════════════════════════════════════════════════════════════════

class _FamiliaTab extends StatelessWidget {
  final String titularId;
  const _FamiliaTab({required this.titularId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClienteBloc, ClienteState>(
      builder: (ctx, state) {
        final List<AfiliadoModel> afiliados;
        final bool cargando;

        if (state is ClienteAfiliadosLoaded && state.titularId == titularId) {
          afiliados = state.afiliados;
          cargando  = false;
        } else if (state is ClienteLoading) {
          afiliados = const [];
          cargando  = true;
        } else {
          afiliados = const [];
          cargando  = false;
        }

        return SingleChildScrollView(
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Encabezado ──────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Afiliados vinculados',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      Text(
                        cargando
                            ? 'Cargando...'
                            : '${afiliados.length} '
                            'miembro${afiliados.length == 1 ? "" : "s"}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ]),
              ),
              OutlinedButton.icon(
                onPressed: () => _abrirVincular(ctx),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                    side: const BorderSide(color: Color(0xFFC5CAE9)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8)),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Vincular',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Loading ──────────────────────────────────────────────────────
            if (cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: Color(0xFF1A237E), strokeWidth: 2),
                ),
              )

            // ── Sin afiliados ────────────────────────────────────────────────
            else if (afiliados.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                child: const Column(children: [
                  Icon(Icons.people_outline_rounded,
                      color: Color(0xFF9CA3AF), size: 36),
                  SizedBox(height: 8),
                  Text('Sin afiliados vinculados',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                  SizedBox(height: 4),
                  Text('Pulsa "Vincular" para agregar un familiar.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                      textAlign: TextAlign.center),
                ]),
              )

            // ── Lista ────────────────────────────────────────────────────────
            else
              ...afiliados.map((a) => _AfiliadoTile(
                afiliado:      a,
                onDesvincular: () => _confirmarDesvincular(ctx, a),
              )),
          ]),
        );
      },
    );
  }

  void _abrirVincular(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<ClienteBloc>(),
        child: _VincularSheet(titularId: titularId),
      ),
    );
  }

  void _confirmarDesvincular(BuildContext ctx, AfiliadoModel a) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE), shape: BoxShape.circle),
          child: const Icon(Icons.link_off_rounded,
              color: Color(0xFFC62828), size: 28),
        ),
        title: const Text('Desvincular afiliado',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            '¿Desvincular a ${a.nombreCompleto}?\n'
                'El cliente seguirá existiendo de forma independiente.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(dCtx),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280)))),
          const SizedBox(width: 8),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(dCtx);
                ctx.read<ClienteBloc>().add(ClienteDesvincularRequested(
                  titularId:  titularId,
                  afiliadoId: a.id,
                ));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Sí, desvincular')),
        ],
      ),
    );
  }
}

// ─── Tile de un afiliado ──────────────────────────────────────────────────────
class _AfiliadoTile extends StatelessWidget {
  final AfiliadoModel afiliado;
  final VoidCallback  onDesvincular;
  const _AfiliadoTile(
      {required this.afiliado, required this.onDesvincular});

  @override
  Widget build(BuildContext context) {
    final a = afiliado;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: _avatarColor(a.iniciales).withOpacity(0.12),
              shape: BoxShape.circle),
          child: Center(
            child: Text(a.iniciales,
                style: TextStyle(
                    color: _avatarColor(a.iniciales),
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(a.nombreCompleto,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1A2E))),
                  ),
                  _EstadoBadge(estado: a.estado),
                ]),
                const SizedBox(height: 2),
                Text(a.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  if (a.parentesco != null)
                    _PillBadge(
                        label: a.parentesco!,
                        color: const Color(0xFF7B1FA2)),
                  if (a.casillero != null)
                    _CasilleroBadge(casillero: a.casillero!),
                ]),
              ]),
        ),
        const SizedBox(width: 8),

        // Botón desvincular
        Tooltip(
          message: 'Desvincular',
          child: Material(
            color: const Color(0xFFC62828).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onDesvincular,
                child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.link_off_rounded,
                        color: Color(0xFFC62828), size: 18))),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHEET VINCULAR: buscar por cédula + seleccionar parentesco
// ═══════════════════════════════════════════════════════════════════════════════

class _VincularSheet extends StatefulWidget {
  final String titularId;
  const _VincularSheet({required this.titularId});

  @override
  State<_VincularSheet> createState() => _VincularSheetState();
}

class _VincularSheetState extends State<_VincularSheet> {
  final _ctrl      = TextEditingController();
  bool    _loading  = false;
  String? _error;
  String? _afiliadoId;
  String? _afiliadoNombre;
  String  _parentesco = 'HIJO';

  static const _parentescos = [
    'HIJO', 'HIJA', 'CONYUGE', 'PADRE', 'MADRE',
    'HERMANO', 'HERMANA', 'AMIGO', 'OTRO',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final num = _ctrl.text.trim();
    if (num.isEmpty) {
      setState(() => _error = 'Ingresa el número de identificación');
      return;
    }
    setState(() {
      _loading        = true;
      _error          = null;
      _afiliadoId     = null;
      _afiliadoNombre = null;
    });
    try {
      final data = await context
          .read<ClienteBloc>()
          .repo
          .buscarPorIdentificacion(num);
      if (!mounted) return;
      setState(() {
        _afiliadoId =
            data['id']?.toString();
        _afiliadoNombre =
            '${data["nombres"] ?? ""} ${data["apellidos"] ?? ""}'.trim();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _vincular() {
    if (_afiliadoId == null || _afiliadoId!.isEmpty) {
      setState(() => _error = 'Primero busca al cliente');
      return;
    }
    context.read<ClienteBloc>().add(ClienteVincularRequested(
      titularId:  widget.titularId,
      afiliadoId: _afiliadoId!,
      parentesco: _parentesco,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title:    'Vincular afiliado',
      subtitle: 'Busca al cliente por su número de identificación',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Aviso
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF01579B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  'El cliente seleccionado quedará vinculado como afiliado de este titular.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF01579B))),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Campo búsqueda + botón
        const _Label('Número de identificación *'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej: 1104567890',
                hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(Icons.badge_outlined,
                    color: Color(0xFF9CA3AF), size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                errorText: _error,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A237E), width: 2)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFFC62828))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _buscar,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16)),
              child: _loading
                  ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Buscar',
                  style:
                  TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),

        // Resultado encontrado
        if (_afiliadoNombre != null && _afiliadoNombre!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF2E7D32).withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.check_circle_outline,
                  color: Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cliente encontrado',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32))),
                      Text(_afiliadoNombre!,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20))),
                    ]),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 16),

        // Parentesco
        const _Label('Parentesco con el titular'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _parentescos.map((p) {
            final sel = p == _parentesco;
            return GestureDetector(
              onTap: () => setState(() => _parentesco = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF1A237E)
                        : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? const Color(0xFF1A237E)
                            : const Color(0xFFE5E7EB))),
                child: Text(p,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? Colors.white
                            : const Color(0xFF6B7280))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        _SheetBtn(
          label: 'Vincular afiliado',
          icon:  Icons.link_rounded,
          onTap: _vincular,
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORM SHEET  — sin cambios
// ═══════════════════════════════════════════════════════════════════════════════

class _ClienteFormSheet extends StatefulWidget {
  final ClienteModel?       cliente;
  final List<SucursalModel> sucursales;
  const _ClienteFormSheet({this.cliente, required this.sucursales});

  @override
  State<_ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends State<_ClienteFormSheet> {
  final _key         = GlobalKey<FormState>();
  final _nombresC    = TextEditingController();
  final _apellidosC  = TextEditingController();
  final _emailC      = TextEditingController();
  final _telC        = TextEditingController();
  final _idNumC      = TextEditingController();
  final _paisC       = TextEditingController();
  final _provinciaC  = TextEditingController();
  final _ciudadC     = TextEditingController();
  final _direccionC  = TextEditingController();
  final _obsC        = TextEditingController();

  TipoIdentificacion _tipoId    = TipoIdentificacion.CEDULA;
  String?            _sucursalId;

  bool get _isEdit => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    if (c != null) {
      _nombresC.text   = c.nombres;
      _apellidosC.text = c.apellidos;
      _emailC.text     = c.email;
      _telC.text       = c.telefono      ?? '';
      _idNumC.text     = c.numeroIdentificacion;
      _paisC.text      = c.pais;
      _provinciaC.text = c.provincia     ?? '';
      _ciudadC.text    = c.ciudad        ?? '';
      _direccionC.text = c.direccion     ?? '';
      _obsC.text       = c.observaciones ?? '';
      _tipoId          = c.tipoIdentificacion;
      _sucursalId      = c.sucursalId;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nombresC, _apellidosC, _emailC, _telC, _idNumC,
      _paisC, _provinciaC, _ciudadC, _direccionC, _obsC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final data = <String, dynamic>{
      'tipoIdentificacion':   _tipoId.name,
      'numeroIdentificacion': _idNumC.text.trim(),
      'nombres':    _nombresC.text.trim(),
      'apellidos':  _apellidosC.text.trim(),
      'email':      _emailC.text.trim(),
      'pais':       _paisC.text.trim(),
      if (_telC.text.isNotEmpty)       'telefono':      _telC.text.trim(),
      if (_provinciaC.text.isNotEmpty) 'provincia':     _provinciaC.text.trim(),
      if (_ciudadC.text.isNotEmpty)    'ciudad':        _ciudadC.text.trim(),
      if (_direccionC.text.isNotEmpty) 'direccion':     _direccionC.text.trim(),
      if (_obsC.text.isNotEmpty)       'observaciones': _obsC.text.trim(),
      if (_sucursalId != null)         'sucursalId':    _sucursalId,
    };
    if (_isEdit) {
      context
          .read<ClienteBloc>()
          .add(ClienteUpdateRequested(widget.cliente!.id, data));
    } else {
      context.read<ClienteBloc>().add(ClienteCreateRequested(data));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title:    _isEdit ? 'Editar cliente' : 'Nuevo cliente',
      subtitle: _isEdit ? widget.cliente!.nombreCompleto : null,
      child: Form(
        key: _key,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Label('Tipo de identificación *'),
              const SizedBox(height: 10),
              Row(
                  children: TipoIdentificacion.values.map((t) {
                    final sel = _tipoId == t;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: t != TipoIdentificacion.values.last ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _tipoId = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                                color: sel
                                    ? _tipoIdColor(t).withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: sel
                                        ? _tipoIdColor(t)
                                        : const Color(0xFFE5E7EB),
                                    width: sel ? 2 : 1)),
                            child: Column(children: [
                              Icon(Icons.badge_outlined,
                                  color: _tipoIdColor(t), size: 20),
                              const SizedBox(height: 4),
                              Text(t.label,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _tipoIdColor(t))),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }).toList()),
              const SizedBox(height: 16),

              const _Label('Número de identificación *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idNumC,
                keyboardType: TextInputType.number,
                decoration: _deco('Ingresa el número'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: _FCol(
                    label: 'Nombres *', ctrl: _nombresC,
                    hint: 'Nombres completos', required: true)),
                const SizedBox(width: 12),
                Expanded(child: _FCol(
                    label: 'Apellidos *', ctrl: _apellidosC,
                    hint: 'Apellidos completos', required: true)),
              ]),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: _FCol(
                    label: 'Email *', ctrl: _emailC,
                    hint: 'correo@ejemplo.com', required: true,
                    keyboard: TextInputType.emailAddress, emailVal: true)),
                const SizedBox(width: 12),
                Expanded(child: _FCol(
                    label: 'Teléfono', ctrl: _telC,
                    hint: '0987654321', keyboard: TextInputType.phone)),
              ]),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: _FCol(
                    label: 'País *', ctrl: _paisC,
                    hint: 'Ecuador', required: true)),
                const SizedBox(width: 12),
                Expanded(child: _FCol(
                    label: 'Provincia', ctrl: _provinciaC, hint: 'Pichincha')),
              ]),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: _FCol(
                    label: 'Ciudad', ctrl: _ciudadC, hint: 'Quito')),
                const SizedBox(width: 12),
                Expanded(child: _FCol(
                    label: 'Dirección', ctrl: _direccionC,
                    hint: 'Av. Principal 123')),
              ]),
              const SizedBox(height: 14),

              const _Label('Sucursal asignada'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sucursalId,
                decoration: _deco('Selecciona una sucursal (opcional)'),
                items: [
                  const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Sin sucursal',
                          style: TextStyle(fontSize: 13))),
                  ...widget.sucursales.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(
                        '${s.nombre} (${s.prefijoCasillero})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  )),
                ],
                onChanged: (v) => setState(() => _sucursalId = v),
              ),
              const SizedBox(height: 14),

              const _Label('Observaciones'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _obsC,
                maxLines: 3,
                decoration: _deco('Notas adicionales...'),
              ),
              const SizedBox(height: 24),

              _SheetBtn(
                label: _isEdit ? 'Guardar cambios' : 'Crear cliente',
                icon:  _isEdit ? Icons.save_outlined : Icons.person_add_rounded,
                onTap: _submit,
              ),
            ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES  — todos sin cambios respecto al original
// ═══════════════════════════════════════════════════════════════════════════════

class _Avatar extends StatelessWidget {
  final String iniciales;
  final double size;
  const _Avatar({required this.iniciales, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(iniciales);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(iniciales,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.35)),
      ),
    );
  }
}

class _TipoIdBadge extends StatelessWidget {
  final TipoIdentificacion tipo;
  const _TipoIdBadge({required this.tipo});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: _tipoIdColor(tipo).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tipoIdColor(tipo).withOpacity(0.2))),
    child: Text(tipo.label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _tipoIdColor(tipo))),
  );
}

class _EstadoBadge extends StatelessWidget {
  final EstadoCliente estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: _estadoColor(estado).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
                color: _estadoColor(estado), shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(estado.label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _estadoColor(estado))),
      ]),
    ),
  );
}

class _CasilleroBadge extends StatelessWidget {
  final String casillero;
  const _CasilleroBadge({required this.casillero});

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xFF1A237E).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF1A237E).withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inbox_rounded, size: 11, color: Color(0xFF1A237E)),
        const SizedBox(width: 3),
        Text(casillero,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A237E),
                letterSpacing: 0.3)),
      ]),
    ),
  );
}

// Badge genérico para parentesco u otras etiquetas de color
class _PillBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color)),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   tip;
  final VoidCallback onTap;
  const _ActionBtn(
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

class _Sheet extends StatelessWidget {
  final String  title;
  final String? subtitle;
  final Widget  child;
  const _Sheet({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
        ),
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
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E))),
                            if (subtitle != null)
                              Text(subtitle!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF6B7280))),
                          ]),
                    ),
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
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)));
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)));
}

class _DRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _DRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500)),
      ]),
    ]),
  );
}

class _FCol extends StatelessWidget {
  final String               label;
  final TextEditingController ctrl;
  final String?              hint;
  final bool                 required;
  final bool                 emailVal;
  final TextInputType        keyboard;
  const _FCol({
    required this.label,
    required this.ctrl,
    this.hint,
    this.required = false,
    this.emailVal = false,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: _deco(hint ?? ''),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return 'Campo requerido';
            }
            if (emailVal && v != null && v.isNotEmpty && !v.contains('@')) {
              return 'Email inválido';
            }
            return null;
          },
        ),
      ]);
}

class _SheetBtn extends StatelessWidget {
  final String    label;
  final IconData? icon;
  final Color     color;
  final VoidCallback onTap;
  final bool      outlined;
  const _SheetBtn({
    required this.label,
    this.icon,
    this.color = const Color(0xFF1A237E),
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: outlined ? color : Colors.white),
            const SizedBox(width: 8),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: outlined ? color : Colors.white)),
        ]);
    if (outlined) {
      return SizedBox(
          height: 50,
          child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: child));
    }
    return SizedBox(
        height: 50,
        child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: child));
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final void Function(String) onChanged;
  const _SearchField(
      {required this.ctrl, required this.hint, required this.onChanged});

  OutlineInputBorder _b({Color? c, double w = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c ?? const Color(0xFFE5E7EB), width: w));

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle:
      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
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
      contentPadding:
      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: _b(),
      enabledBorder: _b(),
      focusedBorder: _b(c: const Color(0xFF1A237E), w: 2),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onAdd;
  const _EmptyView({required this.hasFilter, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFE8EAF6), shape: BoxShape.circle),
            child: const Icon(Icons.people_outline_rounded,
                size: 48, color: Color(0xFF1A237E))),
        const SizedBox(height: 16),
        Text(
            hasFilter
                ? 'Sin resultados'
                : 'No hay clientes registrados',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Text(
            hasFilter
                ? 'Intenta con otro término o filtro'
                : 'Registra el primer cliente con "Nuevo cliente"',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center),
        if (!hasFilter) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Nuevo cliente'),
          ),
        ],
      ]),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

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

InputDecoration _deco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle:
  const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
  filled: true,
  fillColor: Colors.white,
  contentPadding:
  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
      const BorderSide(color: Color(0xFF1A237E), width: 2)),
  errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFC62828))),
  focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
      const BorderSide(color: Color(0xFFC62828), width: 2)),
);