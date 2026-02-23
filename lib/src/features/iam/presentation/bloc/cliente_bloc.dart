// lib/src/features/clientes/presentation/bloc/cliente_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/cliente_model.dart';
import '../../domain/repositories/cliente_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EVENTOS
// ═══════════════════════════════════════════════════════════════════════════════

abstract class ClienteEvent {}

class ClientesLoadRequested     extends ClienteEvent {}
class ClientesTodosRequested    extends ClienteEvent {}

class ClientesBuscarRequested extends ClienteEvent {
  final String q;
  ClientesBuscarRequested(this.q);
}

class ClienteCreateRequested extends ClienteEvent {
  final Map<String, dynamic> data;
  ClienteCreateRequested(this.data);
}

class ClienteUpdateRequested extends ClienteEvent {
  final String id;
  final Map<String, dynamic> data;
  ClienteUpdateRequested(this.id, this.data);
}

class ClienteEstadoRequested extends ClienteEvent {
  final String id;
  final EstadoCliente estado;
  ClienteEstadoRequested(this.id, this.estado);
}

class ClienteSucursalRequested extends ClienteEvent {
  final String clienteId;
  final String sucursalId;
  ClienteSucursalRequested(this.clienteId, this.sucursalId);
}

// ═══════════════════════════════════════════════════════════════════════════════
// ESTADOS
// ═══════════════════════════════════════════════════════════════════════════════

abstract class ClienteState {}

class ClienteInitial extends ClienteState {}
class ClienteLoading  extends ClienteState {}

class ClientesLoaded extends ClienteState {
  final List<ClienteModel> clientes;
  final String? message;
  ClientesLoaded(this.clientes, {this.message});
}

class ClienteError extends ClienteState {
  final String message;
  final List<ClienteModel> clientes;
  ClienteError(this.message, {this.clientes = const []});
}

// ═══════════════════════════════════════════════════════════════════════════════
// BLOC
// ═══════════════════════════════════════════════════════════════════════════════

class ClienteBloc extends Bloc<ClienteEvent, ClienteState> {
  final ClienteRepository repo;
  List<ClienteModel> _clientes = [];

  ClienteBloc({required this.repo}) : super(ClienteInitial()) {
    on<ClientesLoadRequested>    (_onLoad);
    on<ClientesTodosRequested>   (_onTodos);
    on<ClientesBuscarRequested>  (_onBuscar);
    on<ClienteCreateRequested>   (_onCreate);
    on<ClienteUpdateRequested>   (_onUpdate);
    on<ClienteEstadoRequested>   (_onEstado);
    on<ClienteSucursalRequested> (_onSucursal);
  }

  Future<void> _onLoad(
      ClientesLoadRequested _, Emitter<ClienteState> emit) async {
    emit(ClienteLoading());
    try {
      _clientes = await repo.getTodos();
      emit(ClientesLoaded(_clientes));
    } on Exception catch (e) {
      emit(ClienteError(_msg(e)));
    }
  }

  Future<void> _onTodos(
      ClientesTodosRequested _, Emitter<ClienteState> emit) async {
    emit(ClienteLoading());
    try {
      _clientes = await repo.getTodos();
      emit(ClientesLoaded(_clientes));
    } on Exception catch (e) {
      emit(ClienteError(_msg(e)));
    }
  }

  Future<void> _onBuscar(
      ClientesBuscarRequested e, Emitter<ClienteState> emit) async {
    emit(ClienteLoading());
    try {
      _clientes = await repo.buscar(e.q);
      emit(ClientesLoaded(_clientes));
    } on Exception catch (e) {
      emit(ClienteError(_msg(e), clientes: _clientes));
    }
  }

  Future<void> _onCreate(
      ClienteCreateRequested e, Emitter<ClienteState> emit) async {
    emit(ClienteLoading());
    try {
      final nuevo = await repo.create(e.data);
      _clientes = [nuevo, ..._clientes];
      emit(ClientesLoaded(_clientes,
          message: 'Cliente ${nuevo.nombreCompleto} creado exitosamente'));
    } on Exception catch (e) {
      emit(ClienteError(_msg(e), clientes: _clientes));
    }
  }

  Future<void> _onUpdate(
      ClienteUpdateRequested e, Emitter<ClienteState> emit) async {
    emit(ClienteLoading());
    try {
      final updated = await repo.update(e.id, e.data);
      _clientes = _clientes.map((c) => c.id == e.id ? updated : c).toList();
      emit(ClientesLoaded(_clientes,
          message: 'Cliente actualizado correctamente'));
    } on Exception catch (e) {
      emit(ClienteError(_msg(e), clientes: _clientes));
    }
  }

  Future<void> _onEstado(
      ClienteEstadoRequested e, Emitter<ClienteState> emit) async {
    emit(ClienteLoading());
    try {
      final updated = await repo.cambiarEstado(e.id, e.estado);
      _clientes = _clientes.map((c) => c.id == e.id ? updated : c).toList();
      emit(ClientesLoaded(_clientes,
          message: 'Estado cambiado a ${e.estado.label}'));
    } on Exception catch (e) {
      emit(ClienteError(_msg(e), clientes: _clientes));
    }
  }

  Future<void> _onSucursal(
      ClienteSucursalRequested e, Emitter<ClienteState> emit) async {
    emit(ClienteLoading());
    try {
      final updated = await repo.asignarSucursal(e.clienteId, e.sucursalId);
      _clientes = _clientes.map((c) => c.id == e.clienteId ? updated : c).toList();
      emit(ClientesLoaded(_clientes,
          message: 'Sucursal asignada. Casillero: ${updated.casillero ?? "generado"}'));
    } on Exception catch (e) {
      emit(ClienteError(_msg(e), clientes: _clientes));
    }
  }

  String _msg(Exception e) => e.toString().replaceAll('Exception: ', '');
}