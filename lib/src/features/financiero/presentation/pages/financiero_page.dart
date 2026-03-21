// lib/src/features/financiero/presentation/pages/financiero_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../domain/models/financiero_models.dart';
import '../bloc/financiero_loc.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS DE COLOR
// ═══════════════════════════════════════════════════════════════════════════════

Color _cotizacionColor(EstadoCotizacion e) => switch (e) {
  EstadoCotizacion.PENDIENTE  => const Color(0xFFF59E0B),
  EstadoCotizacion.APROBADA   => const Color(0xFF2E7D32),
  EstadoCotizacion.FACTURADA  => const Color(0xFF1A237E),
  EstadoCotizacion.VENCIDA    => const Color(0xFF9CA3AF),
  EstadoCotizacion.CANCELADA  => const Color(0xFFC62828),
};

Color _facturaColor(EstadoFactura e) => switch (e) {
  EstadoFactura.BORRADOR => const Color(0xFF6B7280),
  EstadoFactura.EMITIDA  => const Color(0xFFF59E0B),
  EstadoFactura.PAGADA   => const Color(0xFF2E7D32),
  EstadoFactura.ANULADA  => const Color(0xFFC62828),
  EstadoFactura.VENCIDA  => const Color(0xFFE65100),
};

Color _pagoColor(EstadoPago e) => switch (e) {
  EstadoPago.PENDIENTE  => const Color(0xFFF59E0B),
  EstadoPago.CONFIRMADO => const Color(0xFF2E7D32),
  EstadoPago.RECHAZADO  => const Color(0xFFC62828),
  EstadoPago.DEVUELTO   => const Color(0xFFE65100),
};

String _fmtFecha(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  try {
    final d = DateTime.parse(raw);
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  } catch (_) { return raw.split('T').first; }
}

String _fmtMonto(double v) => '\$${v.toStringAsFixed(2)}';

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPAL  — 4 tabs
// ═══════════════════════════════════════════════════════════════════════════════

class FinancieroPage extends StatelessWidget {
  const FinancieroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<FinancieroBloc>()..add(TarifasLoadRequested()),
      child: const _FinancieroView(),
    );
  }
}

class _FinancieroView extends StatefulWidget {
  const _FinancieroView();
  @override
  State<_FinancieroView> createState() => _FinancieroViewState();
}

class _FinancieroViewState extends State<_FinancieroView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _loadTab(_tab.index);
    });
  }

  void _loadTab(int i) {
    final bloc = context.read<FinancieroBloc>();
    switch (i) {
      case 0: bloc.add(TarifasLoadRequested()); break;
      case 1: bloc.add(CotizacionesLoadRequested()); break;
      case 2: bloc.add(FacturasPendientesRequested()); break;
      case 3: bloc.add(PagosPendientesRequested()); break;
    }
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _ok(String msg) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));

  void _err(String msg) => ScaffoldMessenger.of(context)
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    ));

  @override
  Widget build(BuildContext context) {
    return BlocListener<FinancieroBloc, FinancieroState>(
      listener: (ctx, state) {
        if (state is TarifasLoaded      && state.message != null) _ok(state.message!);
        if (state is CotizacionesLoaded && state.message != null) _ok(state.message!);
        if (state is FacturasLoaded     && state.message != null) _ok(state.message!);
        if (state is PagosLoaded        && state.message != null) _ok(state.message!);
        if (state is FinancieroError) _err(state.message);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(children: [
          _FinancieroHeader(
            tabController: _tab,
            onRefresh: () => _loadTab(_tab.index),
            onAdd: () => _onAdd(context),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _TarifasTab(
                  onAdd:    () => _openTarifaForm(context),
                  onEdit:   (t) => _openTarifaForm(context, tarifa: t),
                  onDelete: (t) => _confirmarDesactivar(context, t),
                ),
                _CotizacionesTab(
                  onAdd:      () => _openCotizacionForm(context),
                  onAprobar:  (c) => _confirmarAprobar(context, c),
                  onCancelar: (c) => _confirmarCancelar(context, c),
                  onFacturar: (c) => _facturarDesdeCotizacion(context, c),
                ),
                _FacturasTab(
                  onAdd:    () => _openFacturaForm(context),
                  onEmitir: (f) => _confirmarEmitir(context, f),
                  onAnular: (f) => _openAnularDialog(context, f),
                  onDetail: (f) => _openFacturaDetail(context, f),
                ),
                _PagosTab(
                  onAdd:       () => _openPagoForm(context),
                  onConfirmar: (p) => _confirmarPago(context, p),
                  onRechazar:  (p) => _openRechazarDialog(context, p),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _onAdd(BuildContext ctx) {
    switch (_tab.index) {
      case 0: _openTarifaForm(ctx); break;
      case 1: _openCotizacionForm(ctx); break;
      case 2: _openFacturaForm(ctx); break;
      case 3: _openPagoForm(ctx); break;
    }
  }

  // ── Confirmaciones ────────────────────────────────────────────────────────

  void _confirmarDesactivar(BuildContext ctx, TarifaModel t) =>
      _confirmDialog(ctx,
        icon: Icons.block_rounded, iconColor: const Color(0xFFC62828),
        title: 'Desactivar tarifa',
        content: '¿Desactivar "${t.nombre}"?\nNo se podrá usar en nuevas cotizaciones.',
        labelOk: 'Desactivar', colorOk: const Color(0xFFC62828),
        onOk: () => ctx.read<FinancieroBloc>().add(TarifaDesactivarRequested(t.id)),
      );

  void _confirmarAprobar(BuildContext ctx, CotizacionModel c) =>
      _confirmDialog(ctx,
        icon: Icons.check_circle_outline, iconColor: const Color(0xFF2E7D32),
        title: 'Aprobar cotización',
        content: '¿Aprobar ${c.numeroCotizacion}?\nTotal: ${_fmtMonto(c.total)}',
        labelOk: 'Aprobar', colorOk: const Color(0xFF2E7D32),
        onOk: () => ctx.read<FinancieroBloc>().add(CotizacionAprobarRequested(c.id)),
      );

  void _confirmarCancelar(BuildContext ctx, CotizacionModel c) =>
      _confirmDialog(ctx,
        icon: Icons.cancel_outlined, iconColor: const Color(0xFFC62828),
        title: 'Cancelar cotización',
        content: '¿Cancelar ${c.numeroCotizacion}? Esta acción no se puede deshacer.',
        labelOk: 'Cancelar cotización', colorOk: const Color(0xFFC62828),
        onOk: () => ctx.read<FinancieroBloc>().add(CotizacionCancelarRequested(c.id)),
      );

  void _confirmarEmitir(BuildContext ctx, FacturaModel f) =>
      _confirmDialog(ctx,
        icon: Icons.send_rounded, iconColor: const Color(0xFF1A237E),
        title: 'Emitir factura',
        content: 'Se asignará un número SRI definitivo.\nTotal: ${_fmtMonto(f.total)}',
        labelOk: 'Emitir', colorOk: const Color(0xFF1A237E),
        onOk: () => ctx.read<FinancieroBloc>().add(FacturaEmitirRequested(f.id)),
      );

  void _confirmarPago(BuildContext ctx, PagoModel p) =>
      _confirmDialog(ctx,
        icon: Icons.check_circle_outline, iconColor: const Color(0xFF2E7D32),
        title: 'Confirmar pago',
        content: 'Confirmar ${p.numeroPago}\nMonto: ${_fmtMonto(p.monto)}\n\nSi el total está cubierto, la factura pasará a PAGADA.',
        labelOk: 'Confirmar', colorOk: const Color(0xFF2E7D32),
        onOk: () => ctx.read<FinancieroBloc>().add(PagoConfirmarRequested(p.id)),
      );

  void _confirmDialog(BuildContext ctx, {
    required IconData icon, required Color iconColor,
    required String title, required String content,
    required String labelOk, required Color colorOk,
    required VoidCallback onOk,
  }) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(title, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(content, textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); onOk(); },
            style: ElevatedButton.styleFrom(
                backgroundColor: colorOk, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(labelOk),
          ),
        ],
      ),
    );
  }

  void _openAnularDialog(BuildContext ctx, FacturaModel f) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Anular factura', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Factura: ${f.numeroFactura ?? f.id.substring(0,8)}',
              style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 14),
          TextField(controller: ctrl, decoration: _deco('Motivo de anulación *'), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              ctx.read<FinancieroBloc>().add(FacturaAnularRequested(f.id, ctrl.text.trim()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }

  void _openRechazarDialog(BuildContext ctx, PagoModel p) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rechazar pago', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${p.numeroPago} — ${_fmtMonto(p.monto)}',
              style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 14),
          TextField(controller: ctrl, decoration: _deco('Motivo del rechazo *'), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              ctx.read<FinancieroBloc>().add(PagoRechazarRequested(p.id, ctrl.text.trim()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheets ─────────────────────────────────────────────────────────

  void _openTarifaForm(BuildContext ctx, {TarifaModel? tarifa}) =>
      showModalBottomSheet(context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(value: ctx.read<FinancieroBloc>(),
              child: _TarifaFormSheet(tarifa: tarifa)));

  void _openCotizacionForm(BuildContext ctx) =>
      showModalBottomSheet(context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(value: ctx.read<FinancieroBloc>(),
              child: const _CotizacionFormSheet()));

  void _openFacturaForm(BuildContext ctx) =>
      showModalBottomSheet(context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(value: ctx.read<FinancieroBloc>(),
              child: const _FacturaFormSheet()));

  // ── NUEVO: Facturar desde cotización aprobada ────────────────────────────
  void _facturarDesdeCotizacion(BuildContext ctx, CotizacionModel c) =>
      showModalBottomSheet(context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(value: ctx.read<FinancieroBloc>(),
              child: _FacturaFormSheet(
                cotizacionId: c.id,
                clienteId: c.clienteId,
              )));

  void _openFacturaDetail(BuildContext ctx, FacturaModel f) {
    ctx.read<FinancieroBloc>().add(FacturaDetailRequested(f.id));
    showModalBottomSheet(context: ctx, isScrollControlled: true,
        useSafeArea: true, backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(value: ctx.read<FinancieroBloc>(),
            child: _FacturaDetailSheet(facturaId: f.id)));
  }

  void _openPagoForm(BuildContext ctx) =>
      showModalBottomSheet(context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(value: ctx.read<FinancieroBloc>(),
              child: const _PagoFormSheet()));
}

// ═══════════════════════════════════════════════════════════════════════════════
// HEADER CON TABS
// ═══════════════════════════════════════════════════════════════════════════════

class _FinancieroHeader extends StatelessWidget {
  final TabController tabController;
  final VoidCallback  onRefresh;
  final VoidCallback  onAdd;
  const _FinancieroHeader({required this.tabController, required this.onRefresh, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Container(
      color: Colors.white,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Módulo Financiero', style: TextStyle(fontSize: 22,
                  fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              const Text('Tarifas · Cotizaciones · Facturas · Pagos',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
                onPressed: onRefresh, tooltip: 'Actualizar'),
            const SizedBox(width: 6),
            SizedBox(height: 42, child: ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12)),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(isWide ? 'Nuevo' : '+',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: tabController,
          labelColor: const Color(0xFF1A237E),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF1A237E),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: const Color(0xFFE5E7EB),
          isScrollable: MediaQuery.of(context).size.width < 500,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.local_offer_outlined, size: 16),   text: 'Tarifas'),
            Tab(icon: Icon(Icons.request_quote_outlined, size: 16), text: 'Cotizaciones'),
            Tab(icon: Icon(Icons.receipt_long_outlined, size: 16),  text: 'Facturas'),
            Tab(icon: Icon(Icons.payments_outlined, size: 16),      text: 'Pagos'),
          ],
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB TARIFAS
// ═══════════════════════════════════════════════════════════════════════════════

class _TarifasTab extends StatelessWidget {
  final VoidCallback               onAdd;
  final void Function(TarifaModel) onEdit;
  final void Function(TarifaModel) onDelete;
  const _TarifasTab({required this.onAdd, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinancieroBloc, FinancieroState>(
      builder: (ctx, state) {
        if (state is FinancieroLoading) return _loading();
        final tarifas = state is TarifasLoaded ? state.tarifas : <TarifaModel>[];
        if (tarifas.isEmpty) return _empty('No hay tarifas configuradas', onAdd);
        final isDesktop = MediaQuery.of(context).size.width >= 900;
        return isDesktop
            ? _TarifasDesktop(items: tarifas, onEdit: onEdit, onDelete: onDelete)
            : _TarifasMobile(items: tarifas, onEdit: onEdit, onDelete: onDelete);
      },
    );
  }
}

class _TarifasDesktop extends StatelessWidget {
  final List<TarifaModel>          items;
  final void Function(TarifaModel) onEdit;
  final void Function(TarifaModel) onDelete;
  const _TarifasDesktop({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.0), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.0), 4: FlexColumnWidth(1.0), 5: FlexColumnWidth(0.8),
              6: FixedColumnWidth(100),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: ['Nombre','Categoría','Tipo','Precio Base','Por Libra','Estado','Acciones']
                    .map((h) => _th(h)).toList(),
              ),
              ...items.map((t) => TableRow(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                children: [
                  _td(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (t.descripcion != null)
                      Text(t.descripcion!, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ])),
                  _td(_Pill(t.categoria.label, const Color(0xFF7B1FA2))),
                  _td(_Pill(t.tipoPedido.label, const Color(0xFF00695C))),
                  _td(Text(_fmtMonto(t.precioBase), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  _td(Text(t.precioPorLibra != null ? _fmtMonto(t.precioPorLibra!) : '—', style: const TextStyle(fontSize: 13))),
                  _td(_ActiveBadge(t.activo)),
                  _td(Row(mainAxisSize: MainAxisSize.min, children: [
                    _ActBtn(Icons.edit_outlined, const Color(0xFF7B1FA2), 'Editar', () => onEdit(t)),
                    const SizedBox(width: 4),
                    _ActBtn(Icons.block_rounded, const Color(0xFFC62828), 'Desactivar', () => onDelete(t)),
                  ])),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarifasMobile extends StatelessWidget {
  final List<TarifaModel>          items;
  final void Function(TarifaModel) onEdit;
  final void Function(TarifaModel) onDelete;
  const _TarifasMobile({required this.items, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    itemCount: items.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) {
      final t = items[i];
      return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            if (t.descripcion != null)
              Text(t.descripcion!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ])),
          _ActiveBadge(t.activo),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              _popItem('edit',   Icons.edit_outlined, 'Editar',     const Color(0xFF7B1FA2)),
              _popItem('delete', Icons.block_rounded, 'Desactivar', const Color(0xFFC62828)),
            ],
            onSelected: (v) { if (v == 'edit') onEdit(t); if (v == 'delete') onDelete(t); },
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _Pill(t.categoria.label, const Color(0xFF7B1FA2)),
          _Pill(t.tipoPedido.label, const Color(0xFF00695C)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _InfoChip(Icons.attach_money_rounded, 'Base', _fmtMonto(t.precioBase)),
          const SizedBox(width: 12),
          if (t.precioPorLibra != null)
            _InfoChip(Icons.scale_rounded, 'Por lb', _fmtMonto(t.precioPorLibra!)),
          const SizedBox(width: 12),
          _InfoChip(Icons.percent_rounded, 'IVA', '${t.porcentajeIva.toStringAsFixed(0)}%'),
        ]),
      ]));
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB COTIZACIONES
// ═══════════════════════════════════════════════════════════════════════════════

class _CotizacionesTab extends StatelessWidget {
  final VoidCallback                   onAdd;
  final void Function(CotizacionModel) onAprobar;
  final void Function(CotizacionModel) onCancelar;
  final void Function(CotizacionModel) onFacturar;
  const _CotizacionesTab({required this.onAdd, required this.onAprobar,
    required this.onCancelar, required this.onFacturar});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinancieroBloc, FinancieroState>(
      builder: (ctx, state) {
        if (state is FinancieroLoading) return _loading();
        final lista = state is CotizacionesLoaded ? state.cotizaciones : <CotizacionModel>[];
        if (lista.isEmpty) return _empty('No hay cotizaciones pendientes', onAdd);
        final isDesktop = MediaQuery.of(context).size.width >= 900;
        return isDesktop
            ? _CotizacionesDesktop(items: lista, onAprobar: onAprobar, onCancelar: onCancelar, onFacturar: onFacturar)
            : _CotizacionesMobile(items: lista, onAprobar: onAprobar, onCancelar: onCancelar, onFacturar: onFacturar);
      },
    );
  }
}

class _CotizacionesDesktop extends StatelessWidget {
  final List<CotizacionModel>          items;
  final void Function(CotizacionModel) onAprobar;
  final void Function(CotizacionModel) onCancelar;
  final void Function(CotizacionModel) onFacturar;
  const _CotizacionesDesktop({required this.items, required this.onAprobar,
    required this.onCancelar, required this.onFacturar});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5), 1: FlexColumnWidth(2.0), 2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.0), 4: FlexColumnWidth(1.0), 5: FlexColumnWidth(1.2),
              6: FixedColumnWidth(130),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: ['Número','Cliente','Categoría','Peso','Total','Estado','Acciones']
                    .map((h) => _th(h)).toList(),
              ),
              ...items.map((c) => TableRow(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                children: [
                  _td(Text(c.numeroCotizacion, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1A237E)))),
                  _td(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.clienteNombre ?? c.clienteId.substring(0,8),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    if (c.pedidoNumero != null)
                      Text(c.pedidoNumero!, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ])),
                  _td(c.categoria != null ? _Pill(c.categoria!.label, const Color(0xFF7B1FA2)) : const Text('—')),
                  _td(Text(c.pesoFacturable != null ? '${c.pesoFacturable!.toStringAsFixed(2)} lb' : '—',
                      style: const TextStyle(fontSize: 13))),
                  _td(Text(_fmtMonto(c.total), style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E)))),
                  _td(_EstadoBadgeGeneric(c.estado.label, _cotizacionColor(c.estado))),
                  _td(Row(mainAxisSize: MainAxisSize.min, children: [
                    if (c.estado == EstadoCotizacion.PENDIENTE) ...[
                      _ActBtn(Icons.check_rounded, const Color(0xFF2E7D32), 'Aprobar', () => onAprobar(c)),
                      const SizedBox(width: 4),
                    ],
                    if (c.estado == EstadoCotizacion.APROBADA) ...[
                      _ActBtn(Icons.receipt_long_outlined, const Color(0xFF1A237E), 'Facturar', () => onFacturar(c)),
                      const SizedBox(width: 4),
                    ],
                    if (c.estado != EstadoCotizacion.FACTURADA)
                      _ActBtn(Icons.close_rounded, const Color(0xFFC62828), 'Cancelar', () => onCancelar(c)),
                  ])),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _CotizacionesMobile extends StatelessWidget {
  final List<CotizacionModel>          items;
  final void Function(CotizacionModel) onAprobar;
  final void Function(CotizacionModel) onCancelar;
  final void Function(CotizacionModel) onFacturar;
  const _CotizacionesMobile({required this.items, required this.onAprobar,
    required this.onCancelar, required this.onFacturar});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    itemCount: items.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) {
      final c = items[i];
      return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.numeroCotizacion, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A237E))),
            Text(c.clienteNombre ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          ])),
          _EstadoBadgeGeneric(c.estado.label, _cotizacionColor(c.estado)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _InfoChip(Icons.scale_rounded, 'Peso',
              c.pesoFacturable != null ? '${c.pesoFacturable!.toStringAsFixed(2)} lb' : '—'),
          const SizedBox(width: 12),
          _InfoChip(Icons.attach_money_rounded, 'Total', _fmtMonto(c.total)),
          const SizedBox(width: 12),
          _InfoChip(Icons.calendar_today_outlined, 'Válida', _fmtFecha(c.validaHasta)),
        ]),
        // Botones según estado
        if (c.estado == EstadoCotizacion.PENDIENTE) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => onCancelar(c),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC62828),
                  side: const BorderSide(color: Color(0xFFC62828)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Cancelar', style: TextStyle(fontSize: 13)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => onAprobar(c),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Aprobar', style: TextStyle(fontSize: 13)),
            )),
          ]),
        ],
        if (c.estado == EstadoCotizacion.APROBADA) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => onFacturar(c),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.receipt_long_outlined, size: 16),
            label: const Text('Facturar', style: TextStyle(fontSize: 13)),
          )),
        ],
      ]));
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB FACTURAS
// ═══════════════════════════════════════════════════════════════════════════════

class _FacturasTab extends StatelessWidget {
  final VoidCallback                onAdd;
  final void Function(FacturaModel) onEmitir;
  final void Function(FacturaModel) onAnular;
  final void Function(FacturaModel) onDetail;
  const _FacturasTab({required this.onAdd, required this.onEmitir,
    required this.onAnular, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinancieroBloc, FinancieroState>(
      builder: (ctx, state) {
        if (state is FinancieroLoading) return _loading();
        final lista = switch (state) {
          FacturasLoaded   s => s.facturas,
          FacturaDetallada s => s.facturas,
          _ => <FacturaModel>[],
        };
        if (lista.isEmpty) return _empty('No hay facturas', onAdd);
        final isDesktop = MediaQuery.of(context).size.width >= 900;
        return isDesktop
            ? _FacturasDesktop(items: lista, onEmitir: onEmitir, onAnular: onAnular, onDetail: onDetail)
            : _FacturasMobile(items: lista, onEmitir: onEmitir, onAnular: onAnular, onDetail: onDetail);
      },
    );
  }
}

class _FacturasDesktop extends StatelessWidget {
  final List<FacturaModel>          items;
  final void Function(FacturaModel) onEmitir;
  final void Function(FacturaModel) onAnular;
  final void Function(FacturaModel) onDetail;
  const _FacturasDesktop({required this.items, required this.onEmitir,
    required this.onAnular, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.8), 1: FlexColumnWidth(2.0), 2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.0), 4: FlexColumnWidth(1.0), 5: FlexColumnWidth(1.2),
              6: FixedColumnWidth(120),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: ['Número','Cliente','Emisión','IVA','Total','Estado','Acciones']
                    .map((h) => _th(h)).toList(),
              ),
              ...items.map((f) => TableRow(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                children: [
                  _td(Text(f.numeroFactura ?? 'BORRADOR', style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12,
                      color: f.numeroFactura != null ? const Color(0xFF1A237E) : const Color(0xFF9CA3AF)))),
                  _td(Text(f.clienteNombre ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  _td(Text(_fmtFecha(f.fechaEmision), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
                  _td(Text(_fmtMonto(f.iva), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
                  _td(Text(_fmtMonto(f.total), style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E)))),
                  _td(_EstadoBadgeGeneric(f.estado.label, _facturaColor(f.estado))),
                  _td(Row(mainAxisSize: MainAxisSize.min, children: [
                    _ActBtn(Icons.visibility_outlined, const Color(0xFF1A237E), 'Ver', () => onDetail(f)),
                    const SizedBox(width: 4),
                    if (f.estado == EstadoFactura.BORRADOR)
                      _ActBtn(Icons.send_rounded, const Color(0xFF2E7D32), 'Emitir', () => onEmitir(f)),
                    if (f.estado == EstadoFactura.EMITIDA) ...[
                      const SizedBox(width: 4),
                      _ActBtn(Icons.cancel_outlined, const Color(0xFFC62828), 'Anular', () => onAnular(f)),
                    ],
                  ])),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacturasMobile extends StatelessWidget {
  final List<FacturaModel>          items;
  final void Function(FacturaModel) onEmitir;
  final void Function(FacturaModel) onAnular;
  final void Function(FacturaModel) onDetail;
  const _FacturasMobile({required this.items, required this.onEmitir,
    required this.onAnular, required this.onDetail});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    itemCount: items.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) {
      final f = items[i];
      return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.numeroFactura ?? 'BORRADOR', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14,
                color: f.numeroFactura != null ? const Color(0xFF1A237E) : const Color(0xFF9CA3AF))),
            Text(f.clienteNombre ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          ])),
          _EstadoBadgeGeneric(f.estado.label, _facturaColor(f.estado)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _InfoChip(Icons.attach_money_rounded, 'Total', _fmtMonto(f.total)),
          const SizedBox(width: 12),
          _InfoChip(Icons.percent_rounded, 'IVA', _fmtMonto(f.iva)),
          const SizedBox(width: 12),
          _InfoChip(Icons.calendar_today_outlined, 'Emisión', _fmtFecha(f.fechaEmision)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => onDetail(f),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A237E),
                side: const BorderSide(color: Color(0xFFC5CAE9)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('Ver', style: TextStyle(fontSize: 13)),
          )),
          if (f.estado == EstadoFactura.BORRADOR) ...[
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => onEmitir(f),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Emitir', style: TextStyle(fontSize: 13)),
            )),
          ],
          if (f.estado == EstadoFactura.EMITIDA) ...[
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => onAnular(f),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC62828),
                  side: const BorderSide(color: Color(0xFFC62828)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Anular', style: TextStyle(fontSize: 13)),
            )),
          ],
        ]),
      ]));
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB PAGOS
// ═══════════════════════════════════════════════════════════════════════════════

class _PagosTab extends StatelessWidget {
  final VoidCallback             onAdd;
  final void Function(PagoModel) onConfirmar;
  final void Function(PagoModel) onRechazar;
  const _PagosTab({required this.onAdd, required this.onConfirmar, required this.onRechazar});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinancieroBloc, FinancieroState>(
      builder: (ctx, state) {
        if (state is FinancieroLoading) return _loading();
        final lista = state is PagosLoaded ? state.pagos : <PagoModel>[];
        if (lista.isEmpty) return _empty('No hay pagos pendientes', onAdd);
        final isDesktop = MediaQuery.of(context).size.width >= 900;
        return isDesktop
            ? _PagosDesktop(items: lista, onConfirmar: onConfirmar, onRechazar: onRechazar)
            : _PagosMobile(items: lista, onConfirmar: onConfirmar, onRechazar: onRechazar);
      },
    );
  }
}

class _PagosDesktop extends StatelessWidget {
  final List<PagoModel>          items;
  final void Function(PagoModel) onConfirmar;
  final void Function(PagoModel) onRechazar;
  const _PagosDesktop({required this.items, required this.onConfirmar, required this.onRechazar});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.8), 2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.0), 4: FlexColumnWidth(1.2), 5: FlexColumnWidth(1.2),
              6: FixedColumnWidth(110),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: ['Número','Cliente','Factura','Monto','Forma Pago','Estado','Acciones']
                    .map((h) => _th(h)).toList(),
              ),
              ...items.map((p) => TableRow(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
                children: [
                  _td(Text(p.numeroPago, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1A237E)))),
                  _td(Text(p.clienteNombre ?? '—', style: const TextStyle(fontSize: 13))),
                  _td(Text(p.facturaNumero ?? p.facturaId.substring(0,8),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
                  _td(Text(_fmtMonto(p.monto), style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E)))),
                  _td(_Pill(p.formaPago.label, const Color(0xFF00695C))),
                  _td(_EstadoBadgeGeneric(p.estado.label, _pagoColor(p.estado))),
                  _td(Row(mainAxisSize: MainAxisSize.min, children: [
                    if (p.estado == EstadoPago.PENDIENTE) ...[
                      _ActBtn(Icons.check_rounded, const Color(0xFF2E7D32), 'Confirmar', () => onConfirmar(p)),
                      const SizedBox(width: 4),
                      _ActBtn(Icons.close_rounded, const Color(0xFFC62828), 'Rechazar', () => onRechazar(p)),
                    ],
                  ])),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PagosMobile extends StatelessWidget {
  final List<PagoModel>          items;
  final void Function(PagoModel) onConfirmar;
  final void Function(PagoModel) onRechazar;
  const _PagosMobile({required this.items, required this.onConfirmar, required this.onRechazar});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    itemCount: items.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) {
      final p = items[i];
      return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.numeroPago, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A237E))),
            Text(p.clienteNombre ?? '—', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          ])),
          _EstadoBadgeGeneric(p.estado.label, _pagoColor(p.estado)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _Pill(p.formaPago.label, const Color(0xFF00695C)),
          if (p.referencia != null) _Pill(p.referencia!, const Color(0xFF374151)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _InfoChip(Icons.attach_money_rounded, 'Monto', _fmtMonto(p.monto)),
          const SizedBox(width: 12),
          _InfoChip(Icons.calendar_today_outlined, 'Fecha', _fmtFecha(p.fechaPago)),
        ]),
        if (p.estado == EstadoPago.PENDIENTE) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => onRechazar(p),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC62828),
                  side: const BorderSide(color: Color(0xFFC62828)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Rechazar', style: TextStyle(fontSize: 13)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => onConfirmar(p),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Confirmar', style: TextStyle(fontSize: 13)),
            )),
          ]),
        ],
      ]));
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// DETALLE DE FACTURA
// ═══════════════════════════════════════════════════════════════════════════════

class _FacturaDetailSheet extends StatelessWidget {
  final String facturaId;
  const _FacturaDetailSheet({required this.facturaId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinancieroBloc, FinancieroState>(
      builder: (ctx, state) {
        if (state is FinancieroLoading) {
          return _Sheet(title: 'Detalle de factura',
              child: const Center(child: Padding(padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF1A237E)))));
        }
        if (state is! FacturaDetallada) {
          return _Sheet(title: 'Detalle de factura',
              child: const Center(child: Text('Cargando...')));
        }
        final f = state.factura;
        final pagos = state.pagos;
        return _Sheet(
          title: f.numeroFactura ?? 'Factura en borrador',
          subtitle: f.clienteNombre,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _EstadoBadgeGeneric(f.estado.label, _facturaColor(f.estado)),
            const SizedBox(height: 16),
            _SectionTitle('Resumen de montos'),
            const SizedBox(height: 8),
            _MontoRow('Subtotal 0%',  f.subtotal0),
            _MontoRow('Subtotal 15%', f.subtotal15),
            if (f.descuento > 0) _MontoRow('Descuento', f.descuento, isNegative: true),
            _MontoRow('IVA 15%',      f.iva),
            const Divider(height: 20),
            _MontoRow('TOTAL', f.total, isBold: true, isTotal: true),
            const SizedBox(height: 16),
            if (f.detalles.isNotEmpty) ...[
              _SectionTitle('Líneas de factura'),
              const SizedBox(height: 8),
              ...f.detalles.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.descripcion, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('${d.cantidad.toStringAsFixed(0)} × ${_fmtMonto(d.precioUnitario)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ])),
                  Text(_fmtMonto(d.subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              )),
              const SizedBox(height: 8),
            ],
            _SectionTitle('Pagos registrados'),
            const SizedBox(height: 8),
            if (pagos.isEmpty)
              const Text('Sin pagos registrados', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))
            else
              ...pagos.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.numeroPago, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${p.formaPago.label} · ${_fmtFecha(p.fechaPago)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ])),
                  _EstadoBadgeGeneric(p.estado.label, _pagoColor(p.estado)),
                  const SizedBox(width: 8),
                  Text(_fmtMonto(p.monto), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              )),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORMULARIOS
// ═══════════════════════════════════════════════════════════════════════════════

class _TarifaFormSheet extends StatefulWidget {
  final TarifaModel? tarifa;
  const _TarifaFormSheet({this.tarifa});
  @override State<_TarifaFormSheet> createState() => _TarifaFormSheetState();
}

class _TarifaFormSheetState extends State<_TarifaFormSheet> {
  final _key = GlobalKey<FormState>();
  final _nombreC = TextEditingController();
  final _descC = TextEditingController();
  final _precioBaseC = TextEditingController();
  final _porLibraC = TextEditingController();
  final _pesoMinC = TextEditingController();
  final _ivaC = TextEditingController();

  CategoriaPaquete     _cat    = CategoriaPaquete.PEQUENO;
  TipoPedidoFinanciero _tipo   = TipoPedidoFinanciero.IMPORTACION;
  bool                 _activo = true;
  bool get _isEdit => widget.tarifa != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tarifa;
    if (t != null) {
      _nombreC.text     = t.nombre;
      _descC.text       = t.descripcion ?? '';
      _precioBaseC.text = t.precioBase.toString();
      _porLibraC.text   = t.precioPorLibra?.toString() ?? '';
      _pesoMinC.text    = t.pesoMinimo?.toString() ?? '';
      _ivaC.text        = t.porcentajeIva.toString();
      _cat              = t.categoria;
      _tipo             = t.tipoPedido;
      _activo           = t.activo;
    } else {
      _ivaC.text = '15.0';
    }
  }

  @override
  void dispose() {
    for (final c in [_nombreC, _descC, _precioBaseC, _porLibraC, _pesoMinC, _ivaC]) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final data = <String, dynamic>{
      'nombre': _nombreC.text.trim(), 'categoria': _cat.name, 'tipoPedido': _tipo.name,
      'precioBase': double.tryParse(_precioBaseC.text) ?? 0,
      'porcentajeIva': double.tryParse(_ivaC.text) ?? 15.0, 'activo': _activo,
      if (_descC.text.isNotEmpty)     'descripcion':    _descC.text.trim(),
      if (_porLibraC.text.isNotEmpty) 'precioPorLibra': double.tryParse(_porLibraC.text),
      if (_pesoMinC.text.isNotEmpty)  'pesoMinimo':     double.tryParse(_pesoMinC.text),
    };
    if (_isEdit) {
      context.read<FinancieroBloc>().add(TarifaUpdateRequested(widget.tarifa!.id, data));
    } else {
      context.read<FinancieroBloc>().add(TarifaCreateRequested(data));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: _isEdit ? 'Editar tarifa' : 'Nueva tarifa',
    subtitle: _isEdit ? widget.tarifa!.nombre : null,
    child: Form(key: _key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Label('Nombre *'), const SizedBox(height: 8),
      TextFormField(controller: _nombreC, decoration: _deco('Ej: Paquete Pequeño Importación'),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
      const SizedBox(height: 14),
      const _Label('Descripción'), const SizedBox(height: 8),
      TextFormField(controller: _descC, decoration: _deco('Descripción opcional'), maxLines: 2),
      const SizedBox(height: 14),
      const _Label('Categoría *'), const SizedBox(height: 8),
      DropdownButtonFormField<CategoriaPaquete>(value: _cat, decoration: _deco(''),
          items: CategoriaPaquete.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
          onChanged: (v) => setState(() => _cat = v!)),
      const SizedBox(height: 14),
      const _Label('Tipo de pedido *'), const SizedBox(height: 8),
      DropdownButtonFormField<TipoPedidoFinanciero>(value: _tipo, decoration: _deco(''),
          items: TipoPedidoFinanciero.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
          onChanged: (v) => setState(() => _tipo = v!)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Label('Precio base (USD) *'), const SizedBox(height: 8),
          TextFormField(controller: _precioBaseC, decoration: _deco('0.00'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Label('Por libra (USD)'), const SizedBox(height: 8),
          TextFormField(controller: _porLibraC, decoration: _deco('0.00'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        ])),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Label('Peso mínimo (lb)'), const SizedBox(height: 8),
          TextFormField(controller: _pesoMinC, decoration: _deco('0.0'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Label('IVA (%)'), const SizedBox(height: 8),
          TextFormField(controller: _ivaC, decoration: _deco('15.0'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        ])),
      ]),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const _Label('Tarifa activa'),
        Switch(value: _activo, onChanged: (v) => setState(() => _activo = v),
            activeColor: const Color(0xFF1A237E)),
      ]),
      const SizedBox(height: 24),
      _SheetBtn(label: _isEdit ? 'Guardar cambios' : 'Crear tarifa',
          icon: _isEdit ? Icons.save_outlined : Icons.add_rounded, onTap: _submit),
    ])),
  );
}

// ── Cotización Form ───────────────────────────────────────────────────────────

class _CotizacionFormSheet extends StatefulWidget {
  const _CotizacionFormSheet();
  @override State<_CotizacionFormSheet> createState() => _CotizacionFormSheetState();
}

class _CotizacionFormSheetState extends State<_CotizacionFormSheet> {
  final _key        = GlobalKey<FormState>();
  final _clienteIdC = TextEditingController();
  final _pedidoIdC  = TextEditingController();
  final _pesoC      = TextEditingController();
  final _largoC     = TextEditingController();
  final _anchoC     = TextEditingController();
  final _altoC      = TextEditingController();
  final _valorC     = TextEditingController();
  final _obsC       = TextEditingController();
  CategoriaPaquete _cat = CategoriaPaquete.PEQUENO;

  @override
  void dispose() {
    for (final c in [_clienteIdC, _pedidoIdC, _pesoC, _largoC, _anchoC, _altoC, _valorC, _obsC]) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final data = <String, dynamic>{
      'clienteId': _clienteIdC.text.trim(), 'categoria': _cat.name,
      if (_pedidoIdC.text.isNotEmpty) 'pedidoId':      _pedidoIdC.text.trim(),
      if (_pesoC.text.isNotEmpty)     'pesoReal':       double.tryParse(_pesoC.text),
      if (_largoC.text.isNotEmpty)    'largo':          double.tryParse(_largoC.text),
      if (_anchoC.text.isNotEmpty)    'ancho':          double.tryParse(_anchoC.text),
      if (_altoC.text.isNotEmpty)     'alto':           double.tryParse(_altoC.text),
      if (_valorC.text.isNotEmpty)    'valorDeclarado': double.tryParse(_valorC.text),
      if (_obsC.text.isNotEmpty)      'observaciones':  _obsC.text.trim(),
    };
    context.read<FinancieroBloc>().add(CotizacionCreateRequested(data));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: 'Nueva cotización',
    child: Form(key: _key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Label('ID del cliente *'), const SizedBox(height: 8),
      TextFormField(controller: _clienteIdC, decoration: _deco('UUID del cliente'),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
      const SizedBox(height: 14),
      const _Label('ID del pedido (opcional)'), const SizedBox(height: 8),
      TextFormField(controller: _pedidoIdC, decoration: _deco('UUID del pedido')),
      const SizedBox(height: 14),
      const _Label('Categoría del paquete *'), const SizedBox(height: 8),
      DropdownButtonFormField<CategoriaPaquete>(value: _cat, decoration: _deco(''),
          items: CategoriaPaquete.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
          onChanged: (v) => setState(() => _cat = v!)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _NumField(label: 'Peso (lbs)', ctrl: _pesoC, hint: '2.5')),
        const SizedBox(width: 12),
        Expanded(child: _NumField(label: 'Valor declarado (USD)', ctrl: _valorC, hint: '150.00')),
      ]),
      const SizedBox(height: 14),
      const _Label('Dimensiones (cm)'), const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _NumField(label: 'Largo', ctrl: _largoC, hint: '20')),
        const SizedBox(width: 8),
        Expanded(child: _NumField(label: 'Ancho', ctrl: _anchoC, hint: '15')),
        const SizedBox(width: 8),
        Expanded(child: _NumField(label: 'Alto',  ctrl: _altoC,  hint: '10')),
      ]),
      const SizedBox(height: 14),
      const _Label('Observaciones'), const SizedBox(height: 8),
      TextFormField(controller: _obsC, decoration: _deco('Notas opcionales'), maxLines: 2),
      const SizedBox(height: 24),
      _SheetBtn(label: 'Crear cotización', icon: Icons.request_quote_outlined, onTap: _submit),
    ])),
  );
}

// ── Factura Form — ACTUALIZADO con cotizacionId y clienteId precargados ───────

class _FacturaFormSheet extends StatefulWidget {
  final String? cotizacionId;
  final String? clienteId;
  const _FacturaFormSheet({this.cotizacionId, this.clienteId});
  @override State<_FacturaFormSheet> createState() => _FacturaFormSheetState();
}

class _FacturaFormSheetState extends State<_FacturaFormSheet> {
  final _key        = GlobalKey<FormState>();
  final _clienteIdC = TextEditingController();
  final _cotizIdC   = TextEditingController();
  final _pedidoIdC  = TextEditingController();
  final _obsC       = TextEditingController();
  FormaPago _formaPago = FormaPago.TRANSFERENCIA;

  @override
  void initState() {
    super.initState();
    // Precargar si viene desde cotización
    if (widget.cotizacionId != null) _cotizIdC.text = widget.cotizacionId!;
    if (widget.clienteId    != null) _clienteIdC.text = widget.clienteId!;
  }

  @override
  void dispose() {
    for (final c in [_clienteIdC, _cotizIdC, _pedidoIdC, _obsC]) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final data = <String, dynamic>{
      'clienteId': _clienteIdC.text.trim(), 'formaPago': _formaPago.name,
      if (_cotizIdC.text.isNotEmpty)  'cotizacionId': _cotizIdC.text.trim(),
      if (_pedidoIdC.text.isNotEmpty) 'pedidoId':     _pedidoIdC.text.trim(),
      if (_obsC.text.isNotEmpty)      'observaciones':_obsC.text.trim(),
    };
    context.read<FinancieroBloc>().add(FacturaCreateRequested(data));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: widget.cotizacionId != null ? 'Facturar cotización' : 'Nueva factura',
    child: Form(key: _key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF01579B)),
          SizedBox(width: 8),
          Expanded(child: Text(
              'Si hay una cotización aprobada vinculada, los montos se cargarán automáticamente.',
              style: TextStyle(fontSize: 12, color: Color(0xFF01579B)))),
        ]),
      ),
      const SizedBox(height: 16),
      const _Label('ID del cliente *'), const SizedBox(height: 8),
      TextFormField(controller: _clienteIdC, decoration: _deco('UUID del cliente'),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
      const SizedBox(height: 14),
      const _Label('ID de la cotización'), const SizedBox(height: 8),
      TextFormField(controller: _cotizIdC, decoration: _deco('UUID de la cotización aprobada')),
      const SizedBox(height: 14),
      const _Label('ID del pedido (opcional)'), const SizedBox(height: 8),
      TextFormField(controller: _pedidoIdC, decoration: _deco('UUID del pedido')),
      const SizedBox(height: 14),
      const _Label('Forma de pago *'), const SizedBox(height: 8),
      DropdownButtonFormField<FormaPago>(value: _formaPago, decoration: _deco(''),
          items: FormaPago.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
          onChanged: (v) => setState(() => _formaPago = v!)),
      const SizedBox(height: 14),
      const _Label('Observaciones'), const SizedBox(height: 8),
      TextFormField(controller: _obsC, decoration: _deco('Notas opcionales'), maxLines: 2),
      const SizedBox(height: 24),
      _SheetBtn(label: 'Crear factura', icon: Icons.receipt_long_outlined, onTap: _submit),
    ])),
  );
}

// ── Pago Form ─────────────────────────────────────────────────────────────────

class _PagoFormSheet extends StatefulWidget {
  const _PagoFormSheet();
  @override State<_PagoFormSheet> createState() => _PagoFormSheetState();
}

class _PagoFormSheetState extends State<_PagoFormSheet> {
  final _key        = GlobalKey<FormState>();
  final _facturaIdC = TextEditingController();
  final _montoC     = TextEditingController();
  final _refC       = TextEditingController();
  final _bancoC     = TextEditingController();
  final _obsC       = TextEditingController();
  FormaPago _formaPago = FormaPago.TRANSFERENCIA;

  @override
  void dispose() {
    for (final c in [_facturaIdC, _montoC, _refC, _bancoC, _obsC]) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final data = <String, dynamic>{
      'facturaId': _facturaIdC.text.trim(),
      'monto':     double.tryParse(_montoC.text) ?? 0.0,
      'formaPago': _formaPago.name,
      'fechaPago': DateTime.now().toIso8601String(),
      if (_refC.text.isNotEmpty)   'referencia':    _refC.text.trim(),
      if (_bancoC.text.isNotEmpty) 'banco':         _bancoC.text.trim(),
      if (_obsC.text.isNotEmpty)   'observaciones': _obsC.text.trim(),
    };
    context.read<FinancieroBloc>().add(PagoRegistrarRequested(data));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: 'Registrar pago',
    child: Form(key: _key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Label('ID de la factura *'), const SizedBox(height: 8),
      TextFormField(controller: _facturaIdC, decoration: _deco('UUID de la factura emitida'),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
      const SizedBox(height: 14),
      const _Label('Monto (USD) *'), const SizedBox(height: 8),
      TextFormField(controller: _montoC, decoration: _deco('0.00'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
      const SizedBox(height: 14),
      const _Label('Forma de pago *'), const SizedBox(height: 8),
      DropdownButtonFormField<FormaPago>(value: _formaPago, decoration: _deco(''),
          items: FormaPago.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
          onChanged: (v) => setState(() => _formaPago = v!)),
      const SizedBox(height: 14),
      const _Label('Referencia (transferencia/voucher)'), const SizedBox(height: 8),
      TextFormField(controller: _refC, decoration: _deco('TRF-20260312-001')),
      const SizedBox(height: 14),
      const _Label('Banco'), const SizedBox(height: 8),
      TextFormField(controller: _bancoC, decoration: _deco('Banco Pichincha')),
      const SizedBox(height: 14),
      const _Label('Observaciones'), const SizedBox(height: 8),
      TextFormField(controller: _obsC, decoration: _deco('Notas opcionales'), maxLines: 2),
      const SizedBox(height: 24),
      _SheetBtn(label: 'Registrar pago', icon: Icons.payments_outlined, onTap: _submit),
    ])),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════════

Widget _loading() => const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));

Widget _empty(String msg, VoidCallback onAdd) => Center(
  child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFE8EAF6), shape: BoxShape.circle),
            child: const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF1A237E))),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: onAdd,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar')),
      ])),
);

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
    child: child,
  );
}

class _Sheet extends StatelessWidget {
  final String title; final String? subtitle; final Widget child;
  const _Sheet({required this.title, this.subtitle, required this.child});

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
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
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

class _Label extends StatelessWidget {
  final String text; const _Label(this.text);
  @override Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)));
}

class _SectionTitle extends StatelessWidget {
  final String text; const _SectionTitle(this.text);
  @override Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)));
}

class _Pill extends StatelessWidget {
  final String label; final Color color;
  const _Pill(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

class _EstadoBadgeGeneric extends StatelessWidget {
  final String label; final Color color;
  const _EstadoBadgeGeneric(this.label, this.color);
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}

class _ActiveBadge extends StatelessWidget {
  final bool activo; const _ActiveBadge(this.activo);
  @override
  Widget build(BuildContext context) => _EstadoBadgeGeneric(
    activo ? 'Activo' : 'Inactivo',
    activo ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoChip(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
    ]),
    Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
  ]);
}

class _ActBtn extends StatelessWidget {
  final IconData icon; final Color color; final String tip; final VoidCallback onTap;
  const _ActBtn(this.icon, this.color, this.tip, this.onTap);
  @override
  Widget build(BuildContext context) => Tooltip(message: tip,
      child: Material(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
          child: InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap,
              child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, color: color, size: 16)))));
}

class _SheetBtn extends StatelessWidget {
  final String label; final IconData? icon; final Color color; final VoidCallback onTap; final bool outlined;
  const _SheetBtn({required this.label, this.icon, this.color = const Color(0xFF1A237E),
    required this.onTap, this.outlined = false});
  @override
  Widget build(BuildContext context) {
    final child = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (icon != null) ...[Icon(icon, size: 18, color: outlined ? color : Colors.white), const SizedBox(width: 8)],
      Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: outlined ? color : Colors.white)),
    ]);
    if (outlined) {
      return SizedBox(height: 50, child: OutlinedButton(onPressed: onTap,
          style: OutlinedButton.styleFrom(side: BorderSide(color: color),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: child));
    }
    return SizedBox(height: 50, child: ElevatedButton(onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: child));
  }
}

class _NumField extends StatelessWidget {
  final String label; final TextEditingController ctrl; final String hint;
  const _NumField({required this.label, required this.ctrl, required this.hint});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _Label(label), const SizedBox(height: 8),
    TextFormField(controller: ctrl, decoration: _deco(hint),
        keyboardType: const TextInputType.numberWithOptions(decimal: true)),
  ]);
}

class _MontoRow extends StatelessWidget {
  final String label; final double value;
  final bool isBold; final bool isTotal; final bool isNegative;
  const _MontoRow(this.label, this.value, {this.isBold = false, this.isTotal = false, this.isNegative = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontSize: isTotal ? 15 : 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? const Color(0xFF1A1A2E) : const Color(0xFF6B7280)))),
      Text('${isNegative ? '-' : ''}${_fmtMonto(value)}', style: TextStyle(fontSize: isTotal ? 15 : 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? const Color(0xFF1A237E) : isNegative ? const Color(0xFFC62828) : const Color(0xFF374151))),
    ]),
  );
}

PopupMenuItem<String> _popItem(String v, IconData icon, String label, Color color) =>
    PopupMenuItem(value: v, child: Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 10), Text(label)]));

Widget _th(String h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))));

Widget _td(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: child);

InputDecoration _deco(String hint) => InputDecoration(
  hintText: hint, hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
  filled: true, fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
  focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
  errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC62828))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC62828), width: 2)),
);