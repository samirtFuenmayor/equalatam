// lib/src/features/tracking/bloc/tracking_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/models/tracking_model.dart';
import '../domain/repositories/tracking_repository.dart';

// ─── EVENTS ───────────────────────────────────────────────────────────────────
abstract class TrackingEvent {}

class TrackingBuscarPorNumero    extends TrackingEvent { final String numeroPedido;   TrackingBuscarPorNumero(this.numeroPedido); }
class TrackingBuscarPorExterno   extends TrackingEvent { final String trackingExterno; TrackingBuscarPorExterno(this.trackingExterno); }
class TrackingLoadCompleto       extends TrackingEvent { final String pedidoId;        TrackingLoadCompleto(this.pedidoId); }
class TrackingLoadByCliente      extends TrackingEvent { final String clienteId;       TrackingLoadByCliente(this.clienteId); }
class TrackingLoadBySucursal     extends TrackingEvent { final String sucursalId;      TrackingLoadBySucursal(this.sucursalId); }
class TrackingLoadByDespacho     extends TrackingEvent { final String numeroDespacho;  TrackingLoadByDespacho(this.numeroDespacho); }
class TrackingLimpiar            extends TrackingEvent {}

class TrackingRegistrarEvento extends TrackingEvent {
  final String              pedidoId;
  final Map<String, dynamic> data;
  TrackingRegistrarEvento(this.pedidoId, this.data);
}

// ─── STATES ───────────────────────────────────────────────────────────────────
abstract class TrackingState {}

class TrackingInitial extends TrackingState {}
class TrackingLoading extends TrackingState {}

class TrackingResumenLoaded extends TrackingState {
  final TrackingResumenModel resumen;
  final String?              message;
  TrackingResumenLoaded(this.resumen, {this.message});
}

class TrackingListResumenLoaded extends TrackingState {
  final List<TrackingResumenModel> resumenes;
  TrackingListResumenLoaded(this.resumenes);
}

class TrackingEventosLoaded extends TrackingState {
  final List<TrackingEventoModel> eventos;
  final String                    titulo;
  TrackingEventosLoaded(this.eventos, {required this.titulo});
}

class TrackingError extends TrackingState {
  final String message;
  TrackingError(this.message);
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final TrackingRepository repo;

  TrackingBloc({required this.repo}) : super(TrackingInitial()) {
    on<TrackingBuscarPorNumero>  (_onBuscarPorNumero);
    on<TrackingBuscarPorExterno> (_onBuscarPorExterno);
    on<TrackingLoadCompleto>     (_onLoadCompleto);
    on<TrackingLoadByCliente>    (_onLoadByCliente);
    on<TrackingLoadBySucursal>   (_onLoadBySucursal);
    on<TrackingLoadByDespacho>   (_onLoadByDespacho);
    on<TrackingRegistrarEvento>  (_onRegistrarEvento);
    on<TrackingLimpiar>          ((_, emit) => emit(TrackingInitial()));
  }

  Future<void> _onBuscarPorNumero(TrackingBuscarPorNumero e, Emitter<TrackingState> emit) async {
    emit(TrackingLoading());
    try {
      final r = await repo.getHistorialPublico(e.numeroPedido);
      emit(TrackingResumenLoaded(r));
    } catch (ex) {
      emit(TrackingError(ex.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onBuscarPorExterno(TrackingBuscarPorExterno e, Emitter<TrackingState> emit) async {
    emit(TrackingLoading());
    try {
      final r = await repo.getHistorialPorTracking(e.trackingExterno);
      emit(TrackingResumenLoaded(r));
    } catch (ex) {
      emit(TrackingError(ex.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadCompleto(TrackingLoadCompleto e, Emitter<TrackingState> emit) async {
    emit(TrackingLoading());
    try {
      final r = await repo.getHistorialCompleto(e.pedidoId);
      emit(TrackingResumenLoaded(r));
    } catch (ex) {
      emit(TrackingError(ex.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadByCliente(TrackingLoadByCliente e, Emitter<TrackingState> emit) async {
    emit(TrackingLoading());
    try {
      final r = await repo.getTrackingPorCliente(e.clienteId);
      emit(TrackingListResumenLoaded(r));
    } catch (ex) {
      emit(TrackingError(ex.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadBySucursal(TrackingLoadBySucursal e, Emitter<TrackingState> emit) async {
    emit(TrackingLoading());
    try {
      final eventos = await repo.getEventosPorSucursal(e.sucursalId);
      emit(TrackingEventosLoaded(eventos, titulo: 'Eventos en sucursal'));
    } catch (ex) {
      emit(TrackingError(ex.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadByDespacho(TrackingLoadByDespacho e, Emitter<TrackingState> emit) async {
    emit(TrackingLoading());
    try {
      final eventos = await repo.getEventosPorDespacho(e.numeroDespacho);
      emit(TrackingEventosLoaded(eventos, titulo: 'Eventos del despacho ${e.numeroDespacho}'));
    } catch (ex) {
      emit(TrackingError(ex.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRegistrarEvento(TrackingRegistrarEvento e, Emitter<TrackingState> emit) async {
    final prev = state;
    try {
      await repo.registrarEventoManual(e.pedidoId, e.data);
      // Recargar historial completo tras registrar
      final r = await repo.getHistorialCompleto(e.pedidoId);
      emit(TrackingResumenLoaded(r, message: 'Evento registrado correctamente'));
    } catch (ex) {
      emit(TrackingError(ex.toString().replaceFirst('Exception: ', '')));
      if (prev is TrackingResumenLoaded) emit(prev);
    }
  }
}