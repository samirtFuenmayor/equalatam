// lib/src/features/pedidos/presentation/bloc/pedido_bloc.dart
import 'package:bloc/bloc.dart';
import '../domain/model/pedido_model.dart';
import '../domain/repositories/pedido_repository.dart';

// ─── EVENTOS ──────────────────────────────────────────────────────────────────
abstract class PedidoEvent {}

class PedidoLoadAll          extends PedidoEvent {}
class PedidoFilterEstado     extends PedidoEvent {
  final EstadoPedido? estado;
  PedidoFilterEstado(this.estado);
}
class PedidoBuscar           extends PedidoEvent {
  final String q;
  PedidoBuscar(this.q);
}
class PedidoLoadConteos      extends PedidoEvent {}
class PedidoCreateRequested  extends PedidoEvent {
  final Map<String, dynamic> data;
  PedidoCreateRequested(this.data);
}
class PedidoUpdateRequested  extends PedidoEvent {
  final String id;
  final Map<String, dynamic> data;
  PedidoUpdateRequested(this.id, this.data);
}
class PedidoEstadoCambiar    extends PedidoEvent {
  final String       id;
  final EstadoPedido estado;
  final String?      observacion;
  final String?      sucursalId;
  PedidoEstadoCambiar(this.id, this.estado,
      {this.observacion, this.sucursalId});
}

// ─── ESTADOS ──────────────────────────────────────────────────────────────────
abstract class PedidoState {}

class PedidoInitial extends PedidoState {}
class PedidoLoading  extends PedidoState {}

class PedidoLoaded extends PedidoState {
  final List<PedidoModel>  pedidos;
  final Map<String, int>   conteos;
  final String?            message;
  PedidoLoaded(this.pedidos, {this.conteos = const {}, this.message});
}

class PedidoError extends PedidoState {
  final String             message;
  final List<PedidoModel>  pedidos;
  final Map<String, int>   conteos;
  PedidoError(this.message,
      {this.pedidos = const [], this.conteos = const {}});
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────
class PedidoBloc extends Bloc<PedidoEvent, PedidoState> {
  final PedidoRepository repo;

  List<PedidoModel> _all     = [];
  Map<String, int>  _conteos = {};
  EstadoPedido?     _filtroEstado;

  PedidoBloc({required this.repo}) : super(PedidoInitial()) {
    on<PedidoLoadAll>(_onLoadAll);
    on<PedidoFilterEstado>(_onFilter);
    on<PedidoBuscar>(_onBuscar);
    on<PedidoLoadConteos>(_onConteos);
    on<PedidoCreateRequested>(_onCreate);
    on<PedidoUpdateRequested>(_onUpdate);
    on<PedidoEstadoCambiar>(_onEstado);
  }

  List<PedidoModel> get _filtered => _filtroEstado == null
      ? _all
      : _all.where((p) => p.estado == _filtroEstado).toList();

  // ── Cargar todos ──────────────────────────────────────────────────────────
  Future<void> _onLoadAll(
      PedidoLoadAll _, Emitter<PedidoState> emit) async {
    emit(PedidoLoading());
    try {
      _all = await repo.findAll();
      _filtroEstado = null;
      try { _conteos = await repo.conteosPorEstado(); } catch (_) {}
      emit(PedidoLoaded(_all, conteos: _conteos));
    } on Exception catch (e) {
      emit(PedidoError(_m(e)));
    }
  }

  // ── Filtrar por estado (client-side) ─────────────────────────────────────
  Future<void> _onFilter(
      PedidoFilterEstado e, Emitter<PedidoState> emit) async {
    _filtroEstado = e.estado;
    if (_all.isEmpty) {
      emit(PedidoLoading());
      try {
        _all = await repo.findAll();
      } on Exception catch (ex) {
        emit(PedidoError(_m(ex)));
        return;
      }
    }
    emit(PedidoLoaded(_filtered, conteos: _conteos));
  }

  // ── Buscar ────────────────────────────────────────────────────────────────
  Future<void> _onBuscar(
      PedidoBuscar e, Emitter<PedidoState> emit) async {
    if (e.q.trim().isEmpty) {
      _filtroEstado = null;
      emit(PedidoLoaded(_all, conteos: _conteos));
      return;
    }
    emit(PedidoLoading());
    try {
      final result = await repo.buscar(e.q.trim());
      emit(PedidoLoaded(result, conteos: _conteos));
    } on Exception catch (ex) {
      emit(PedidoError(_m(ex), pedidos: _filtered, conteos: _conteos));
    }
  }

  // ── Conteos dashboard ─────────────────────────────────────────────────────
  Future<void> _onConteos(
      PedidoLoadConteos _, Emitter<PedidoState> emit) async {
    try {
      _conteos = await repo.conteosPorEstado();
      emit(PedidoLoaded(_filtered, conteos: _conteos));
    } on Exception catch (_) {}
  }

  // ── Crear ─────────────────────────────────────────────────────────────────
  Future<void> _onCreate(
      PedidoCreateRequested e, Emitter<PedidoState> emit) async {
    emit(PedidoLoading());
    try {
      final nuevo = await repo.create(e.data);
      _all = [nuevo, ..._all];
      try { _conteos = await repo.conteosPorEstado(); } catch (_) {}
      emit(PedidoLoaded(_filtered, conteos: _conteos,
          message: 'Pedido ${nuevo.numeroPedido} creado exitosamente'));
    } on Exception catch (e) {
      emit(PedidoError(_m(e), pedidos: _filtered, conteos: _conteos));
    }
  }

  // ── Actualizar ────────────────────────────────────────────────────────────
  Future<void> _onUpdate(
      PedidoUpdateRequested e, Emitter<PedidoState> emit) async {
    emit(PedidoLoading());
    try {
      final updated = await repo.update(e.id, e.data);
      _all = _all.map((p) => p.id == e.id ? updated : p).toList();
      emit(PedidoLoaded(_filtered, conteos: _conteos,
          message: 'Pedido actualizado correctamente'));
    } on Exception catch (e) {
      emit(PedidoError(_m(e), pedidos: _filtered, conteos: _conteos));
    }
  }

  // ── Cambiar estado ────────────────────────────────────────────────────────
  Future<void> _onEstado(
      PedidoEstadoCambiar e, Emitter<PedidoState> emit) async {
    emit(PedidoLoading());
    try {
      final updated = await repo.cambiarEstado(e.id, e.estado,
          observacion: e.observacion, sucursalId: e.sucursalId);
      _all = _all.map((p) => p.id == e.id ? updated : p).toList();
      try { _conteos = await repo.conteosPorEstado(); } catch (_) {}
      emit(PedidoLoaded(_filtered, conteos: _conteos,
          message: 'Estado cambiado a ${e.estado.label}'));
    } on Exception catch (e) {
      emit(PedidoError(_m(e), pedidos: _filtered, conteos: _conteos));
    }
  }

  String _m(Exception e) => e.toString().replaceAll('Exception: ', '');
}