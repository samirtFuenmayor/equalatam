// lib/src/features/despachos/presentation/bloc/despacho_bloc.dart
import 'package:bloc/bloc.dart';
import '../domain/models/despacho_model.dart';
import '../domain/repositories/despacho_repository.dart';

// ─── EVENTOS ──────────────────────────────────────────────────────────────────
abstract class DespachoEvent {}

class DespachoLoadAll           extends DespachoEvent {}
class DespachoFilterEstado      extends DespachoEvent {
  final EstadoDespacho? estado;
  DespachoFilterEstado(this.estado);
}
class DespachoCreateRequested   extends DespachoEvent {
  final Map<String, dynamic> data;
  DespachoCreateRequested(this.data);
}
class DespachoTransporteUpdate  extends DespachoEvent {
  final String id;
  final Map<String, dynamic> data;
  DespachoTransporteUpdate(this.id, this.data);
}
class DespachoEstadoCambiar     extends DespachoEvent {
  final String id;
  final EstadoDespacho estado;
  final String? observacion;
  DespachoEstadoCambiar(this.id, this.estado, {this.observacion});
}
class DespachoAgregarPedidos    extends DespachoEvent {
  final String id;
  final List<String> pedidoIds;
  DespachoAgregarPedidos(this.id, this.pedidoIds);
}
class DespachoQuitarPedido      extends DespachoEvent {
  final String id;
  final String pedidoId;
  DespachoQuitarPedido(this.id, this.pedidoId);
}

// ─── ESTADOS ──────────────────────────────────────────────────────────────────
abstract class DespachoState {}

class DespachoInitial extends DespachoState {}
class DespachoLoading  extends DespachoState {}

class DespachoLoaded extends DespachoState {
  final List<DespachoModel> despachos;
  final String?             message;
  DespachoLoaded(this.despachos, {this.message});
}

class DespachoError extends DespachoState {
  final String              message;
  final List<DespachoModel> despachos;
  DespachoError(this.message, {this.despachos = const []});
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────
class DespachoBloc extends Bloc<DespachoEvent, DespachoState> {
  final DespachoRepository repo;

  List<DespachoModel> _all          = [];
  EstadoDespacho?     _filtroEstado;

  DespachoBloc({required this.repo}) : super(DespachoInitial()) {
    on<DespachoLoadAll>(_onLoadAll);
    on<DespachoFilterEstado>(_onFilter);
    on<DespachoCreateRequested>(_onCreate);
    on<DespachoTransporteUpdate>(_onTransporte);
    on<DespachoEstadoCambiar>(_onEstado);
    on<DespachoAgregarPedidos>(_onAgregar);
    on<DespachoQuitarPedido>(_onQuitar);
  }

  List<DespachoModel> get _filtered => _filtroEstado == null
      ? _all
      : _all.where((d) => d.estado == _filtroEstado).toList();

  Future<void> _onLoadAll(DespachoLoadAll _, Emitter<DespachoState> emit) async {
    emit(DespachoLoading());
    try {
      _all = await repo.findAll();
      _filtroEstado = null;
      emit(DespachoLoaded(_all));
    } on Exception catch (e) {
      emit(DespachoError(_m(e)));
    }
  }

  Future<void> _onFilter(
      DespachoFilterEstado e, Emitter<DespachoState> emit) async {
    _filtroEstado = e.estado;
    if (_all.isEmpty) {
      emit(DespachoLoading());
      try {
        _all = await repo.findAll();
      } on Exception catch (ex) {
        emit(DespachoError(_m(ex)));
        return;
      }
    }
    emit(DespachoLoaded(_filtered));
  }

  Future<void> _onCreate(
      DespachoCreateRequested e, Emitter<DespachoState> emit) async {
    emit(DespachoLoading());
    try {
      final nuevo = await repo.create(e.data);
      _all = [nuevo, ..._all];
      emit(DespachoLoaded(_filtered,
          message: 'Despacho ${nuevo.numeroDespacho} creado exitosamente'));
    } on Exception catch (e) {
      emit(DespachoError(_m(e), despachos: _filtered));
    }
  }

  Future<void> _onTransporte(
      DespachoTransporteUpdate e, Emitter<DespachoState> emit) async {
    emit(DespachoLoading());
    try {
      final updated = await repo.actualizarTransporte(e.id, e.data);
      _all = _all.map((d) => d.id == e.id ? updated : d).toList();
      emit(DespachoLoaded(_filtered,
          message: 'Transporte actualizado correctamente'));
    } on Exception catch (e) {
      emit(DespachoError(_m(e), despachos: _filtered));
    }
  }

  Future<void> _onEstado(
      DespachoEstadoCambiar e, Emitter<DespachoState> emit) async {
    emit(DespachoLoading());
    try {
      final updated = await repo.cambiarEstado(e.id, e.estado,
          observacion: e.observacion);
      _all = _all.map((d) => d.id == e.id ? updated : d).toList();
      emit(DespachoLoaded(_filtered,
          message: 'Estado cambiado a ${e.estado.label}'));
    } on Exception catch (e) {
      emit(DespachoError(_m(e), despachos: _filtered));
    }
  }

  Future<void> _onAgregar(
      DespachoAgregarPedidos e, Emitter<DespachoState> emit) async {
    emit(DespachoLoading());
    try {
      final updated = await repo.agregarPedidos(e.id, e.pedidoIds);
      _all = _all.map((d) => d.id == e.id ? updated : d).toList();
      final n = e.pedidoIds.length;
      emit(DespachoLoaded(_filtered,
          message: '$n pedido${n == 1 ? '' : 's'} agregado${n == 1 ? '' : 's'} al despacho'));
    } on Exception catch (e) {
      emit(DespachoError(_m(e), despachos: _filtered));
    }
  }

  Future<void> _onQuitar(
      DespachoQuitarPedido e, Emitter<DespachoState> emit) async {
    emit(DespachoLoading());
    try {
      final updated = await repo.quitarPedido(e.id, e.pedidoId);
      _all = _all.map((d) => d.id == e.id ? updated : d).toList();
      emit(DespachoLoaded(_filtered, message: 'Pedido retirado del despacho'));
    } on Exception catch (e) {
      emit(DespachoError(_m(e), despachos: _filtered));
    }
  }

  String _m(Exception e) => e.toString().replaceAll('Exception: ', '');
}