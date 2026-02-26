// lib/src/features/guias/bloc/guia_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/models/guia_model.dart';
import '../domain/repositories/guia_repository.dart';

// ─── EVENTS ───────────────────────────────────────────────────────────────────
abstract class GuiaEvent {}

class GuiaLoadAll           extends GuiaEvent {}
class GuiaLoadByCliente     extends GuiaEvent { final String clienteId;       GuiaLoadByCliente(this.clienteId); }
class GuiaLoadByDespacho    extends GuiaEvent { final String numeroDespacho;  GuiaLoadByDespacho(this.numeroDespacho); }

class GuiaGenerarRequested  extends GuiaEvent {
  final Map<String, dynamic> data;
  GuiaGenerarRequested(this.data);
}

class GuiaAsignarDespacho   extends GuiaEvent {
  final String              id;
  final Map<String, dynamic> data;
  GuiaAsignarDespacho(this.id, this.data);
}

class GuiaCambiarEstado     extends GuiaEvent {
  final String     id;
  final EstadoGuia estado;
  GuiaCambiarEstado(this.id, this.estado);
}

class GuiaAnular            extends GuiaEvent {
  final String id;
  final String motivo;
  GuiaAnular(this.id, this.motivo);
}

// ─── STATES ───────────────────────────────────────────────────────────────────
abstract class GuiaState {}

class GuiaInitial extends GuiaState {}
class GuiaLoading extends GuiaState {}

class GuiaLoaded extends GuiaState {
  final List<GuiaModel> guias;
  final String?         message;
  GuiaLoaded({required this.guias, this.message});

  GuiaLoaded copyWith({List<GuiaModel>? guias, String? message}) =>
      GuiaLoaded(guias: guias ?? this.guias, message: message);
}

class GuiaError extends GuiaState {
  final String          message;
  final List<GuiaModel> guias;
  GuiaError(this.message, {this.guias = const []});
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────
class GuiaBloc extends Bloc<GuiaEvent, GuiaState> {
  final GuiaRepository repo;

  GuiaBloc({required this.repo}) : super(GuiaInitial()) {
    on<GuiaLoadAll>          (_onLoadAll);
    on<GuiaLoadByCliente>    (_onLoadByCliente);
    on<GuiaLoadByDespacho>   (_onLoadByDespacho);
    on<GuiaGenerarRequested> (_onGenerar);
    on<GuiaAsignarDespacho>  (_onAsignarDespacho);
    on<GuiaCambiarEstado>    (_onCambiarEstado);
    on<GuiaAnular>           (_onAnular);
  }

  List<GuiaModel> get _current =>
      state is GuiaLoaded ? (state as GuiaLoaded).guias :
      state is GuiaError  ? (state as GuiaError).guias  : [];

  Future<void> _onLoadAll(GuiaLoadAll e, Emitter<GuiaState> emit) async {
    emit(GuiaLoading());
    try {
      emit(GuiaLoaded(guias: await repo.findAll()));
    } catch (ex) {
      emit(GuiaError(ex.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadByCliente(GuiaLoadByCliente e, Emitter<GuiaState> emit) async {
    emit(GuiaLoading());
    try {
      emit(GuiaLoaded(guias: await repo.findByCliente(e.clienteId)));
    } catch (ex) {
      emit(GuiaError(ex.toString().replaceFirst('Exception: ', ''), guias: _current));
    }
  }

  Future<void> _onLoadByDespacho(GuiaLoadByDespacho e, Emitter<GuiaState> emit) async {
    emit(GuiaLoading());
    try {
      emit(GuiaLoaded(guias: await repo.findByDespacho(e.numeroDespacho)));
    } catch (ex) {
      emit(GuiaError(ex.toString().replaceFirst('Exception: ', ''), guias: _current));
    }
  }

  Future<void> _onGenerar(GuiaGenerarRequested e, Emitter<GuiaState> emit) async {
    final prev = _current;
    try {
      final nueva = await repo.generar(e.data);
      emit(GuiaLoaded(
          guias: [nueva, ...prev],
          message: 'Guía ${nueva.numeroGuia} generada exitosamente'));
    } catch (ex) {
      emit(GuiaError(ex.toString().replaceFirst('Exception: ', ''), guias: prev));
    }
  }

  Future<void> _onAsignarDespacho(GuiaAsignarDespacho e, Emitter<GuiaState> emit) async {
    final prev = _current;
    try {
      final updated = await repo.asignarDespacho(e.id, e.data);
      final list = prev.map((g) => g.id == e.id ? updated : g).toList();
      emit(GuiaLoaded(guias: list, message: 'Despacho asignado: ${updated.numeroDespacho}'));
    } catch (ex) {
      emit(GuiaError(ex.toString().replaceFirst('Exception: ', ''), guias: prev));
    }
  }

  Future<void> _onCambiarEstado(GuiaCambiarEstado e, Emitter<GuiaState> emit) async {
    final prev = _current;
    try {
      final updated = await repo.cambiarEstado(e.id, e.estado);
      final list = prev.map((g) => g.id == e.id ? updated : g).toList();
      emit(GuiaLoaded(guias: list, message: 'Estado cambiado a ${e.estado.label}'));
    } catch (ex) {
      emit(GuiaError(ex.toString().replaceFirst('Exception: ', ''), guias: prev));
    }
  }

  Future<void> _onAnular(GuiaAnular e, Emitter<GuiaState> emit) async {
    final prev = _current;
    try {
      final updated = await repo.anular(e.id, e.motivo);
      final list = prev.map((g) => g.id == e.id ? updated : g).toList();
      emit(GuiaLoaded(guias: list, message: 'Guía anulada correctamente'));
    } catch (ex) {
      emit(GuiaError(ex.toString().replaceFirst('Exception: ', ''), guias: prev));
    }
  }
}