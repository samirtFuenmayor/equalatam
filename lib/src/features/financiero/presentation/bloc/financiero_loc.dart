// lib/src/features/financiero/presentation/bloc/financiero_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/financiero_models.dart';
import '../../domain/repositories/fianciero_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EVENTOS
// ═══════════════════════════════════════════════════════════════════════════════

abstract class FinancieroEvent {}

// ── Tarifas ───────────────────────────────────────────────────────────────────
class TarifasLoadRequested       extends FinancieroEvent {}
class TarifaCreateRequested      extends FinancieroEvent {
  final Map<String, dynamic> data;
  TarifaCreateRequested(this.data);
}
class TarifaUpdateRequested      extends FinancieroEvent {
  final String id;
  final Map<String, dynamic> data;
  TarifaUpdateRequested(this.id, this.data);
}
class TarifaDesactivarRequested  extends FinancieroEvent {
  final String id;
  TarifaDesactivarRequested(this.id);
}
class TarifaCalcularRequested    extends FinancieroEvent {
  final Map<String, dynamic> data;
  TarifaCalcularRequested(this.data);
}

// ── Cotizaciones ──────────────────────────────────────────────────────────────
class CotizacionesLoadRequested      extends FinancieroEvent {}
class CotizacionCreateRequested      extends FinancieroEvent {
  final Map<String, dynamic> data;
  CotizacionCreateRequested(this.data);
}
class CotizacionAprobarRequested     extends FinancieroEvent {
  final String id;
  CotizacionAprobarRequested(this.id);
}
class CotizacionCancelarRequested    extends FinancieroEvent {
  final String id;
  CotizacionCancelarRequested(this.id);
}

// ── Facturas ──────────────────────────────────────────────────────────────────
class FacturasPendientesRequested    extends FinancieroEvent {}
class FacturasLoadRequested          extends FinancieroEvent {}
class FacturaCreateRequested         extends FinancieroEvent {
  final Map<String, dynamic> data;
  FacturaCreateRequested(this.data);
}
class FacturaEmitirRequested         extends FinancieroEvent {
  final String id;
  FacturaEmitirRequested(this.id);
}
class FacturaAnularRequested         extends FinancieroEvent {
  final String id;
  final String motivo;
  FacturaAnularRequested(this.id, this.motivo);
}
class FacturaDetailRequested         extends FinancieroEvent {
  final String id;
  FacturaDetailRequested(this.id);
}

// ── Pagos ─────────────────────────────────────────────────────────────────────
class PagosPendientesRequested       extends FinancieroEvent {}
class PagosPorFacturaRequested       extends FinancieroEvent {
  final String facturaId;
  PagosPorFacturaRequested(this.facturaId);
}
class PagoRegistrarRequested         extends FinancieroEvent {
  final Map<String, dynamic> data;
  PagoRegistrarRequested(this.data);
}
class PagoConfirmarRequested         extends FinancieroEvent {
  final String id;
  PagoConfirmarRequested(this.id);
}
class PagoRechazarRequested          extends FinancieroEvent {
  final String id;
  final String motivo;
  PagoRechazarRequested(this.id, this.motivo);
}

// ═══════════════════════════════════════════════════════════════════════════════
// ESTADOS
// ═══════════════════════════════════════════════════════════════════════════════

abstract class FinancieroState {}

class FinancieroInitial extends FinancieroState {}
class FinancieroLoading  extends FinancieroState {}

// ── Tarifas ───────────────────────────────────────────────────────────────────
class TarifasLoaded extends FinancieroState {
  final List<TarifaModel> tarifas;
  final String? message;
  TarifasLoaded(this.tarifas, {this.message});
}

class TarifaCalculada extends FinancieroState {
  final Map<String, dynamic> resultado;
  final List<TarifaModel>    tarifas;
  TarifaCalculada(this.resultado, this.tarifas);
}

// ── Cotizaciones ──────────────────────────────────────────────────────────────
class CotizacionesLoaded extends FinancieroState {
  final List<CotizacionModel> cotizaciones;
  final String? message;
  CotizacionesLoaded(this.cotizaciones, {this.message});
}

// ── Facturas ──────────────────────────────────────────────────────────────────
class FacturasLoaded extends FinancieroState {
  final List<FacturaModel> facturas;
  final String? message;
  FacturasLoaded(this.facturas, {this.message});
}

class FacturaDetallada extends FinancieroState {
  final FacturaModel       factura;
  final List<PagoModel>    pagos;
  final List<FacturaModel> facturas;
  FacturaDetallada(this.factura, this.pagos, this.facturas);
}

// ── Pagos ─────────────────────────────────────────────────────────────────────
class PagosLoaded extends FinancieroState {
  final List<PagoModel> pagos;
  final String? message;
  PagosLoaded(this.pagos, {this.message});
}

// ── Error ─────────────────────────────────────────────────────────────────────
class FinancieroError extends FinancieroState {
  final String message;
  FinancieroError(this.message);
}

// ═══════════════════════════════════════════════════════════════════════════════
// BLOC
// ═══════════════════════════════════════════════════════════════════════════════

class FinancieroBloc extends Bloc<FinancieroEvent, FinancieroState> {
  final FinancieroRepository repo;

  List<TarifaModel>      _tarifas      = [];
  List<CotizacionModel>  _cotizaciones = [];
  List<FacturaModel>     _facturas     = [];
  List<PagoModel>        _pagos        = [];

  FinancieroBloc({required this.repo}) : super(FinancieroInitial()) {
    // Tarifas
    on<TarifasLoadRequested>      (_onTarifasLoad);
    on<TarifaCreateRequested>     (_onTarifaCreate);
    on<TarifaUpdateRequested>     (_onTarifaUpdate);
    on<TarifaDesactivarRequested> (_onTarifaDesactivar);
    on<TarifaCalcularRequested>   (_onTarifaCalcular);
    // Cotizaciones
    on<CotizacionesLoadRequested> (_onCotizacionesLoad);
    on<CotizacionCreateRequested> (_onCotizacionCreate);
    on<CotizacionAprobarRequested>(_onCotizacionAprobar);
    on<CotizacionCancelarRequested>(_onCotizacionCancelar);
    // Facturas
    on<FacturasPendientesRequested>(_onFacturasPendientes);
    on<FacturasLoadRequested>      (_onFacturasLoad);
    on<FacturaCreateRequested>     (_onFacturaCreate);
    on<FacturaEmitirRequested>     (_onFacturaEmitir);
    on<FacturaAnularRequested>     (_onFacturaAnular);
    on<FacturaDetailRequested>     (_onFacturaDetail);
    // Pagos
    on<PagosPendientesRequested>  (_onPagosPendientes);
    on<PagosPorFacturaRequested>  (_onPagosPorFactura);
    on<PagoRegistrarRequested>    (_onPagoRegistrar);
    on<PagoConfirmarRequested>    (_onPagoConfirmar);
    on<PagoRechazarRequested>     (_onPagoRechazar);
  }

  // ── Tarifas ───────────────────────────────────────────────────────────────

  Future<void> _onTarifasLoad(
      TarifasLoadRequested _, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      _tarifas = await repo.getTarifas();
      emit(TarifasLoaded(_tarifas));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onTarifaCreate(
      TarifaCreateRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final nueva = await repo.createTarifa(e.data);
      _tarifas = [nueva, ..._tarifas];
      emit(TarifasLoaded(_tarifas, message: 'Tarifa "${nueva.nombre}" creada'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onTarifaUpdate(
      TarifaUpdateRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final upd = await repo.updateTarifa(e.id, e.data);
      _tarifas = _tarifas.map((t) => t.id == e.id ? upd : t).toList();
      emit(TarifasLoaded(_tarifas, message: 'Tarifa actualizada'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onTarifaDesactivar(
      TarifaDesactivarRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      await repo.desactivarTarifa(e.id);
      _tarifas = await repo.getTarifas();
      emit(TarifasLoaded(_tarifas, message: 'Tarifa desactivada'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onTarifaCalcular(
      TarifaCalcularRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final resultado = await repo.calcularTarifa(e.data);
      emit(TarifaCalculada(resultado, _tarifas));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  // ── Cotizaciones ──────────────────────────────────────────────────────────

  Future<void> _onCotizacionesLoad(
      CotizacionesLoadRequested _, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      _cotizaciones = await repo.getCotizaciones();
      emit(CotizacionesLoaded(_cotizaciones));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onCotizacionCreate(
      CotizacionCreateRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final nueva = await repo.createCotizacion(e.data);
      _cotizaciones = [nueva, ..._cotizaciones];
      emit(CotizacionesLoaded(_cotizaciones,
          message: 'Cotización ${nueva.numeroCotizacion} creada'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onCotizacionAprobar(
      CotizacionAprobarRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final upd = await repo.aprobarCotizacion(e.id);
      _cotizaciones = _cotizaciones.map((c) => c.id == e.id ? upd : c).toList();
      emit(CotizacionesLoaded(_cotizaciones, message: 'Cotización aprobada'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onCotizacionCancelar(
      CotizacionCancelarRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final upd = await repo.cancelarCotizacion(e.id);
      _cotizaciones = _cotizaciones.map((c) => c.id == e.id ? upd : c).toList();
      emit(CotizacionesLoaded(_cotizaciones, message: 'Cotización cancelada'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  // ── Facturas ──────────────────────────────────────────────────────────────

  Future<void> _onFacturasPendientes(
      FacturasPendientesRequested _, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      _facturas = await repo.getFacturasPendientes();
      emit(FacturasLoaded(_facturas));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onFacturasLoad(
      FacturasLoadRequested _, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      _facturas = await repo.getFacturasPendientes();
      emit(FacturasLoaded(_facturas));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onFacturaCreate(
      FacturaCreateRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final nueva = await repo.createFactura(e.data);
      _facturas = [nueva, ..._facturas];
      emit(FacturasLoaded(_facturas, message: 'Factura creada en borrador'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onFacturaEmitir(
      FacturaEmitirRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final upd = await repo.emitirFactura(e.id);
      _facturas = _facturas.map((f) => f.id == e.id ? upd : f).toList();
      emit(FacturasLoaded(_facturas,
          message: 'Factura ${upd.numeroFactura ?? ""} emitida'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onFacturaAnular(
      FacturaAnularRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final upd = await repo.anularFactura(e.id, e.motivo);
      _facturas = _facturas.map((f) => f.id == e.id ? upd : f).toList();
      emit(FacturasLoaded(_facturas, message: 'Factura anulada'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onFacturaDetail(
      FacturaDetailRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final factura = await repo.getFactura(e.id);
      final pagos   = await repo.getPagosByFactura(e.id);
      emit(FacturaDetallada(factura, pagos, _facturas));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  // ── Pagos ─────────────────────────────────────────────────────────────────

  Future<void> _onPagosPendientes(
      PagosPendientesRequested _, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      _pagos = await repo.getPagosPendientes();
      emit(PagosLoaded(_pagos));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onPagosPorFactura(
      PagosPorFacturaRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      _pagos = await repo.getPagosByFactura(e.facturaId);
      emit(PagosLoaded(_pagos));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onPagoRegistrar(
      PagoRegistrarRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final nuevo = await repo.registrarPago(e.data);
      _pagos = [nuevo, ..._pagos];
      emit(PagosLoaded(_pagos,
          message: 'Pago ${nuevo.numeroPago} registrado. Pendiente de confirmación'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onPagoConfirmar(
      PagoConfirmarRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final upd = await repo.confirmarPago(e.id);
      _pagos = _pagos.map((p) => p.id == e.id ? upd : p).toList();
      emit(PagosLoaded(_pagos, message: 'Pago confirmado correctamente'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  Future<void> _onPagoRechazar(
      PagoRechazarRequested e, Emitter<FinancieroState> emit) async {
    emit(FinancieroLoading());
    try {
      final upd = await repo.rechazarPago(e.id, e.motivo);
      _pagos = _pagos.map((p) => p.id == e.id ? upd : p).toList();
      emit(PagosLoaded(_pagos, message: 'Pago rechazado'));
    } on Exception catch (e) { emit(FinancieroError(_msg(e))); }
  }

  String _msg(Exception e) => e.toString().replaceAll('Exception: ', '');
}