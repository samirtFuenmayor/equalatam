// lib/src/features/tracking/presentation/pages/tracking_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../../../core/constants/api_constants.dart';
import '../domain/models/tracking_model.dart';
import '../bloc/tracking_bloc.dart';
import '../../pedidos/domain/model/pedido_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => di.sl<TrackingBloc>(),
    child: const _TrackingView(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class _TrackingView extends StatefulWidget {
  const _TrackingView();
  @override
  State<_TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<_TrackingView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _buscarCtrl = TextEditingController();
  String _modoBusqueda = 'numero'; // 'numero' | 'tracking'

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _buscar(BuildContext ctx) {
    final q = _buscarCtrl.text.trim();
    if (q.isEmpty) return;
    if (_modoBusqueda == 'numero') {
      ctx.read<TrackingBloc>().add(TrackingBuscarPorNumero(q));
    } else {
      ctx.read<TrackingBloc>().add(TrackingBuscarPorExterno(q));
    }
  }

  void _openEventoSheet(BuildContext ctx, String pedidoId) =>
      showModalBottomSheet(
          context: ctx, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(
              value: ctx.read<TrackingBloc>(),
              child: _RegistrarEventoSheet(pedidoId: pedidoId)));

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
    return BlocConsumer<TrackingBloc, TrackingState>(
      listener: (ctx, state) {
        if (state is TrackingResumenLoaded && state.message != null)
          _snack(ctx, state.message!, ok: true);
        if (state is TrackingError) _snack(ctx, state.message, ok: false);
      },
      builder: (ctx, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            _TrkHeader(
              onRefresh: state is TrackingResumenLoaded
                  ? () => ctx.read<TrackingBloc>().add(TrackingLoadCompleto(state.resumen.pedidoId))
                  : null,
              onLimpiar: state is! TrackingInitial
                  ? () {
                ctx.read<TrackingBloc>().add(TrackingLimpiar());
                _buscarCtrl.clear();
              }
                  : null,
            ),
            // Buscador
            _TrkBuscador(
              ctrl:      _buscarCtrl,
              modo:      _modoBusqueda,
              onModo:    (m) => setState(() => _modoBusqueda = m),
              onBuscar:  () => _buscar(ctx),
              loading:   state is TrackingLoading,
            ),
            Expanded(child: _body(ctx, state)),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext ctx, TrackingState state) {
    if (state is TrackingInitial) return const _TrkEmptySearch();
    if (state is TrackingLoading) return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    if (state is TrackingError) return _TrkErrorView(
        message: state.message,
        onRetry: () => _buscar(ctx));
    if (state is TrackingResumenLoaded) return _TrkResumenView(
        resumen: state.resumen,
        onAgregarEvento: () => _openEventoSheet(ctx, state.resumen.pedidoId));
    if (state is TrackingListResumenLoaded) return _TrkListaResumenes(resumenes: state.resumenes);
    if (state is TrackingEventosLoaded) return _TrkListaEventos(
        eventos: state.eventos, titulo: state.titulo);
    return const SizedBox.shrink();
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _TrkHeader extends StatelessWidget {
  final VoidCallback? onRefresh, onLimpiar;
  const _TrkHeader({this.onRefresh, this.onLimpiar});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tracking de Pedidos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const Text('Consulta el estado y ubicación de tus envíos',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      ])),
      if (onRefresh != null)
        IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
            onPressed: onRefresh, tooltip: 'Actualizar'),
      if (onLimpiar != null)
        IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
            onPressed: onLimpiar, tooltip: 'Nueva búsqueda'),
    ]),
  );
}

// ─── BUSCADOR ─────────────────────────────────────────────────────────────────
class _TrkBuscador extends StatelessWidget {
  final TextEditingController ctrl;
  final String modo;
  final void Function(String)  onModo;
  final VoidCallback           onBuscar;
  final bool                   loading;
  const _TrkBuscador({required this.ctrl, required this.modo, required this.onModo,
    required this.onBuscar, required this.loading});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 650;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Toggle modo
        Row(children: [
          _ModoBtn(label: 'Nº Pedido', icon: Icons.tag_rounded, value: 'numero', selected: modo, onTap: onModo),
          const SizedBox(width: 10),
          _ModoBtn(label: 'Tracking externo', icon: Icons.qr_code_outlined, value: 'tracking', selected: modo, onTap: onModo),
        ]),
        const SizedBox(height: 10),
        // Campo búsqueda
        Row(children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              onSubmitted: (_) => onBuscar(),
              decoration: InputDecoration(
                hintText: modo == 'numero' ? 'Ej: PED-2026-00001' : 'Ej: TBA123456789',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: Icon(
                    modo == 'numero' ? Icons.tag_rounded : Icons.qr_code_outlined,
                    color: const Color(0xFF9CA3AF), size: 18),
                suffixIcon: ctrl.text.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
                    onPressed: () { ctrl.clear(); })
                    : null,
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onBuscar,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 14)),
              child: loading
                  ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.search_rounded, size: 18),
                if (isWide) ...[const SizedBox(width: 6), const Text('Rastrear', style: TextStyle(fontWeight: FontWeight.w600))],
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _ModoBtn extends StatelessWidget {
  final String label, value, selected;
  final IconData icon;
  final void Function(String) onTap;
  const _ModoBtn({required this.label, required this.icon, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: sel ? const Color(0xFF1A237E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? const Color(0xFF1A237E) : const Color(0xFFE5E7EB))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: sel ? Colors.white : const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: sel ? Colors.white : const Color(0xFF6B7280))),
        ]),
      ),
    );
  }
}

// ─── VISTA RESUMEN ────────────────────────────────────────────────────────────
class _TrkResumenView extends StatelessWidget {
  final TrackingResumenModel resumen;
  final VoidCallback         onAgregarEvento;
  const _TrkResumenView({required this.resumen, required this.onAgregarEvento});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: isDesktop
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 2, child: _columnaIzq(context)),
        const SizedBox(width: 20),
        Expanded(flex: 3, child: _columnaDer(context)),
      ])
          : Column(children: [
        _columnaIzq(context),
        const SizedBox(height: 16),
        _columnaDer(context),
      ]),
    );
  }

  Widget _columnaIzq(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Card resumen pedido
      _TrkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.inventory_2_outlined, size: 22, color: Color(0xFF1A237E))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(resumen.numeroPedido,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: Color(0xFF1A1A2E))),
            _EstadoBadge(estado: resumen.estadoActual),
          ])),
          IconButton(
              icon: const Icon(Icons.copy_outlined, size: 16, color: Color(0xFF9CA3AF)),
              tooltip: 'Copiar número',
              onPressed: () => Clipboard.setData(ClipboardData(text: resumen.numeroPedido))),
        ]),
        const SizedBox(height: 14),
        // Barra de progreso
        _ProgressBar(progreso: resumen.progreso, estado: resumen.estadoActual),
        const SizedBox(height: 14),
        // Descripción
        Text(resumen.descripcion,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
      ])),
      const SizedBox(height: 14),

      // Card cliente
      _TrkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SecTitle('Cliente'),
        const SizedBox(height: 10),
        _TrkRow(Icons.person_outline_rounded, resumen.clienteNombre),
        const SizedBox(height: 6),
        _TrkRow(Icons.tag_rounded, resumen.clienteCasillero),
      ])),
      const SizedBox(height: 14),

      // Card tracking externo
      if (resumen.trackingExterno != null) ...[
        _TrkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SecTitle('Tracking externo'),
          const SizedBox(height: 10),
          _TrkRow(Icons.qr_code_outlined, resumen.trackingExterno!),
          if (resumen.proveedor != null) ...[
            const SizedBox(height: 6),
            _TrkRow(Icons.store_outlined, resumen.proveedor!),
          ],
        ])),
        const SizedBox(height: 14),
      ],

      // Card ruta
      _TrkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SecTitle('Ruta'),
        const SizedBox(height: 10),
        if (resumen.sucursalOrigen != null)
          _TrkRutaRow(Icons.flight_takeoff_rounded, 'Origen', resumen.sucursalOrigen!),
        if (resumen.sucursalOrigen != null && resumen.sucursalDestino != null)
          const Padding(padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [SizedBox(width: 22), SizedBox(width: 2, height: 16, child: ColoredBox(color: Color(0xFFE5E7EB)))])),
        if (resumen.sucursalDestino != null)
          _TrkRutaRow(Icons.flight_land_rounded, 'Destino', resumen.sucursalDestino!),
      ])),
      const SizedBox(height: 14),

      // Botón agregar evento
      ElevatedButton.icon(
        onPressed: onAgregarEvento,
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14)),
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text('Registrar evento', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );

  Widget _columnaDer(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Fechas clave
      _TrkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SecTitle('Fechas clave'),
        const SizedBox(height: 12),
        _FechasTimeline(resumen: resumen),
      ])),
      const SizedBox(height: 14),

      // Historial de eventos
      _TrkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _SecTitle('Historial de eventos')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(20)),
            child: Text('${resumen.historial.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
          ),
        ]),
        const SizedBox(height: 12),
        if (resumen.historial.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Sin eventos registrados', style: TextStyle(color: Color(0xFF9CA3AF))),
          ))
        else
          ...resumen.historial.asMap().entries.map((entry) =>
              _EventoItem(evento: entry.value, isLast: entry.key == resumen.historial.length - 1)),
      ])),
    ],
  );
}

// Barra de progreso
class _ProgressBar extends StatelessWidget {
  final double       progreso;
  final EstadoPedido estado;
  const _ProgressBar({required this.progreso, required this.estado});

  Color get _color => switch (estado) {
    EstadoPedido.ENTREGADO              => const Color(0xFF2E7D32),
    EstadoPedido.DEVUELTO               => const Color(0xFF546E7A),
    EstadoPedido.EXTRAVIADO             => const Color(0xFFB71C1C),
    EstadoPedido.RETENIDO_ADUANA        => const Color(0xFFC62828),
    EstadoPedido.EN_ADUANA              => const Color(0xFF7B1FA2),
    _                                   => const Color(0xFF1A237E),
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Progreso del envío', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        Text('${(progreso * 100).toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progreso,
          minHeight: 8,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: AlwaysStoppedAnimation<Color>(_color),
        ),
      ),
    ],
  );
}

// Fechas timeline
class _FechasTimeline extends StatelessWidget {
  final TrackingResumenModel resumen;
  const _FechasTimeline({required this.resumen});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final hitos = <_Hito>[
      _Hito('Registrado', resumen.fechaRegistro, Icons.add_circle_outline, const Color(0xFF1A237E), true),
      _Hito('Recibido en sede', resumen.fechaRecepcionSede, Icons.inbox_outlined, const Color(0xFF00695C), resumen.fechaRecepcionSede != null),
      _Hito('Salida al exterior', resumen.fechaSalidaExterior, Icons.flight_takeoff_rounded, const Color(0xFFE65100), resumen.fechaSalidaExterior != null),
      _Hito('Llegada a Ecuador', resumen.fechaLlegadaEcuador, Icons.flight_land_rounded, const Color(0xFF1565C0), resumen.fechaLlegadaEcuador != null),
      _Hito('Disponible para retiro', resumen.fechaDisponible, Icons.store_outlined, const Color(0xFF00897B), resumen.fechaDisponible != null),
      _Hito('Entregado', resumen.fechaEntrega, Icons.check_circle_outline, const Color(0xFF2E7D32), resumen.fechaEntrega != null),
    ];

    return Column(
      children: hitos.asMap().entries.map((entry) {
        final i = entry.key;
        final h = entry.value;
        final isLast = i == hitos.length - 1;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: h.activo ? h.color.withOpacity(0.12) : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: h.activo ? h.color : const Color(0xFFE5E7EB), width: h.activo ? 2 : 1)),
              child: Icon(h.icon, size: 15, color: h.activo ? h.color : const Color(0xFFD1D5DB)),
            ),
            if (!isLast) Container(width: 2, height: 28, color: h.activo ? h.color.withOpacity(0.3) : const Color(0xFFE5E7EB)),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 6),
              Text(h.label, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: h.activo ? const Color(0xFF1A1A2E) : const Color(0xFF9CA3AF))),
              if (h.fecha != null)
                Text(_fmt(h.fecha!), style: TextStyle(fontSize: 11, color: h.color)),
              if (h.fecha == null)
                const Text('Pendiente', style: TextStyle(fontSize: 11, color: Color(0xFFD1D5DB))),
            ]),
          )),
        ]);
      }).toList(),
    );
  }
}

class _Hito {
  final String   label;
  final DateTime? fecha;
  final IconData  icon;
  final Color     color;
  final bool      activo;
  const _Hito(this.label, this.fecha, this.icon, this.color, this.activo);
}

// Evento individual en historial
class _EventoItem extends StatelessWidget {
  final TrackingEventoModel evento;
  final bool                isLast;
  const _EventoItem({required this.evento, required this.isLast});

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  Color get _color => _estadoColor(evento.estado);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        if (!isLast) Container(width: 2, height: 60, color: const Color(0xFFE5E7EB)),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(evento.descripcion,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
            if (!evento.visibleParaCliente)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                child: const Text('Interno', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
              ),
          ]),
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _EstadoBadge(estado: evento.estado),
            if (evento.sucursalNombre != null)
              _TrkChip(Icons.location_on_outlined, evento.sucursalNombre!),
            if (evento.numeroDespacho != null)
              _TrkChip(Icons.local_shipping_outlined, evento.numeroDespacho!),
          ]),
          if (evento.ubicacionDetalle != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place_outlined, size: 11, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Flexible(child: Text(evento.ubicacionDetalle!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)))),
            ]),
          ],
          if (evento.notaInterna != null && evento.notaInterna!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFECB3))),
              child: Row(children: [
                const Icon(Icons.notes_rounded, size: 12, color: Color(0xFFE65100)),
                const SizedBox(width: 6),
                Flexible(child: Text(evento.notaInterna!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF374151)))),
              ]),
            ),
          ],
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(_fmt(evento.fechaEvento),
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            if (evento.registradoPor != null) ...[
              const Text(' · ', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              Text(evento.registradoPor!, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ]),
        ]),
      )),
    ],
  );
}

// ─── LISTA DE RESUMENES (por cliente) ─────────────────────────────────────────
class _TrkListaResumenes extends StatelessWidget {
  final List<TrackingResumenModel> resumenes;
  const _TrkListaResumenes({required this.resumenes});

  @override
  Widget build(BuildContext context) {
    if (resumenes.isEmpty) return const _TrkEmptySearch(mensaje: 'Este cliente no tiene pedidos');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      itemCount: resumenes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _ResumenCard(resumen: resumenes[i]),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final TrackingResumenModel resumen;
  const _ResumenCard({required this.resumen});

  @override
  Widget build(BuildContext context) => _TrkCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(resumen.numeroPedido,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: Color(0xFF1A1A2E))),
          Text(resumen.descripcion, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ])),
        _EstadoBadge(estado: resumen.estadoActual),
      ]),
      const SizedBox(height: 10),
      _ProgressBar(progreso: resumen.progreso, estado: resumen.estadoActual),
      const SizedBox(height: 10),
      Row(children: [
        if (resumen.sucursalOrigen != null)
          Flexible(child: _TrkChip(Icons.flight_takeoff_rounded, resumen.sucursalOrigen!)),
        if (resumen.sucursalOrigen != null && resumen.sucursalDestino != null)
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF9CA3AF))),
        if (resumen.sucursalDestino != null)
          Flexible(child: _TrkChip(Icons.flight_land_rounded, resumen.sucursalDestino!)),
      ]),
    ]),
  );
}

// ─── LISTA DE EVENTOS (sucursal / despacho) ───────────────────────────────────
class _TrkListaEventos extends StatelessWidget {
  final List<TrackingEventoModel> eventos;
  final String                    titulo;
  const _TrkListaEventos({required this.eventos, required this.titulo});

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) return _TrkEmptySearch(mensaje: 'Sin eventos registrados para $titulo');
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Row(children: [
          const Icon(Icons.history_rounded, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const Spacer(),
          Text('${eventos.length} eventos', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ]),
      ),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        itemCount: eventos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _TrkCard(
          child: _EventoItem(evento: eventos[i], isLast: true),
        ),
      )),
    ]);
  }
}

// ─── SHEET REGISTRAR EVENTO ───────────────────────────────────────────────────
class _RegistrarEventoSheet extends StatefulWidget {
  final String pedidoId;
  const _RegistrarEventoSheet({required this.pedidoId});
  @override
  State<_RegistrarEventoSheet> createState() => _RegistrarEventoSheetState();
}

class _RegistrarEventoSheetState extends State<_RegistrarEventoSheet> {
  final _key      = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _ubicCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();

  List<_SucRef> _sucursales = [];
  String?       _sucursalId;
  bool          _visible    = true;
  bool          _loading    = false;

  @override
  void initState() { super.initState(); _fetchSucursales(); }

  @override
  void dispose() { _descCtrl.dispose(); _ubicCtrl.dispose(); _notaCtrl.dispose(); super.dispose(); }

  Future<void> _fetchSucursales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('eq_token') ?? '';
      final res = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/sucursales'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
      if (res.statusCode >= 200 && res.statusCode < 300 && mounted) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        setState(() {
          _sucursales = list.map((e) => _SucRef(
              id: e['id'].toString(), nombre: e['nombre'].toString(), pais: e['pais'].toString())).toList();
        });
      }
    } catch (_) {}
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final data = <String, dynamic>{
      'descripcion':       _descCtrl.text.trim(),
      'visibleParaCliente': _visible,
    };
    if (_sucursalId != null) data['sucursalId']      = _sucursalId;
    if (_ubicCtrl.text.trim().isNotEmpty) data['ubicacionDetalle'] = _ubicCtrl.text.trim();
    if (_notaCtrl.text.trim().isNotEmpty) data['notaInterna']      = _notaCtrl.text.trim();

    context.read<TrackingBloc>().add(TrackingRegistrarEvento(widget.pedidoId, data));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _TrkSheet(
    title: 'Registrar evento',
    child: Form(
      key: _key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Descripción
        _TrkLabel('Descripción del evento *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl, maxLines: 3,
          decoration: _trkDeco('Ej: Paquete revisado en aduana sin novedad'),
          validator: (v) => v == null || v.trim().isEmpty ? 'La descripción es obligatoria' : null,
        ),
        const SizedBox(height: 14),

        // Sucursal
        _TrkLabel('Sucursal (opcional)'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _sucursalId,
              hint: const Text('Sin sucursal específica', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin sucursal específica', style: TextStyle(fontSize: 14))),
                ..._sucursales.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text('${s.nombre} (${s.pais})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                )),
              ],
              onChanged: (v) => setState(() => _sucursalId = v),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Ubicación
        _TrkLabel('Ubicación detallada (opcional)'),
        const SizedBox(height: 8),
        TextFormField(controller: _ubicCtrl, decoration: _trkDeco('Ej: Bodega 2, anaquel 5')),
        const SizedBox(height: 14),

        // Nota interna
        _TrkLabel('Nota interna (solo empleados)'),
        const SizedBox(height: 8),
        TextFormField(controller: _notaCtrl, maxLines: 2, decoration: _trkDeco('Ej: Inspector Juan Pérez revisó el contenido')),
        const SizedBox(height: 14),

        // Visible para cliente
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(children: [
            const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Visible para el cliente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              Text(_visible ? 'El cliente podrá ver este evento' : 'Solo visible para empleados',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ])),
            Switch(
              value: _visible,
              onChanged: (v) => setState(() => _visible = v),
              activeColor: const Color(0xFF1A237E),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Registrar evento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );
}

// ─── WIDGETS PROPIOS ──────────────────────────────────────────────────────────

Color _estadoColor(EstadoPedido e) => switch (e) {
  EstadoPedido.REGISTRADO             => const Color(0xFF1A237E),
  EstadoPedido.RECIBIDO_EN_SEDE       => const Color(0xFF00695C),
  EstadoPedido.EN_CONSOLIDACION       => const Color(0xFF6A1B9A),
  EstadoPedido.EN_TRANSITO            => const Color(0xFFE65100),
  EstadoPedido.EN_ADUANA              => const Color(0xFF7B1FA2),
  EstadoPedido.RETENIDO_ADUANA        => const Color(0xFFC62828),
  EstadoPedido.LIBERADO_ADUANA        => const Color(0xFF2E7D32),
  EstadoPedido.RECIBIDO_EN_MATRIZ     => const Color(0xFF1565C0),
  EstadoPedido.EN_DISTRIBUCION        => const Color(0xFFAD6C00),
  EstadoPedido.DISPONIBLE_EN_SUCURSAL => const Color(0xFF00897B),
  EstadoPedido.ENTREGADO              => const Color(0xFF2E7D32),
  EstadoPedido.DEVUELTO               => const Color(0xFF546E7A),
  EstadoPedido.EXTRAVIADO             => const Color(0xFFB71C1C),
};

class _EstadoBadge extends StatelessWidget {
  final EstadoPedido estado;
  const _EstadoBadge({required this.estado});
  @override
  Widget build(BuildContext context) {
    final c = _estadoColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(estado.label, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _TrkChip extends StatelessWidget {
  final IconData icon; final String label;
  const _TrkChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: const Color(0xFF6B7280)),
      const SizedBox(width: 4),
      Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
    ]),
  );
}

class _TrkRow extends StatelessWidget {
  final IconData icon; final String label;
  const _TrkRow(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
    const SizedBox(width: 10),
    Flexible(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
  ]);
}

class _TrkRutaRow extends StatelessWidget {
  final IconData icon; final String etiqueta, nombre;
  const _TrkRutaRow(this.icon, this.etiqueta, this.nombre);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: const Color(0xFF6B7280)),
    const SizedBox(width: 10),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(etiqueta, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      Text(nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
    ]),
  ]);
}

class _SecTitle extends StatelessWidget {
  final String text;
  const _SecTitle(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
  ]);
}

class _TrkCard extends StatelessWidget {
  final Widget child;
  const _TrkCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))]),
    child: child,
  );
}

class _TrkSheet extends StatelessWidget {
  final String title; final Widget child;
  const _TrkSheet({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 12),
      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
      Flexible(child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 18),
          child,
        ]),
      )),
    ]),
  );
}

class _TrkLabel extends StatelessWidget {
  final String text;
  const _TrkLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)));
}

class _TrkEmptySearch extends StatelessWidget {
  final String mensaje;
  const _TrkEmptySearch({this.mensaje = 'Ingresa un número de pedido o tracking para rastrear tu envío'});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFE8EAF6), shape: BoxShape.circle),
            child: const Icon(Icons.local_shipping_outlined, size: 52, color: Color(0xFF1A237E))),
        const SizedBox(height: 20),
        const Text('Rastrea tu envío', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
      ]),
    ),
  );
}

class _TrkErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _TrkErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFC62828))),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
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

class _SucRef {
  final String id, nombre, pais;
  const _SucRef({required this.id, required this.nombre, required this.pais});
}

InputDecoration _trkDeco(String hint) => InputDecoration(
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