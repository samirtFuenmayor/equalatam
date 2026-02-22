// lib/src/features/iam/presentation/bloc/iam_bloc.dart
import 'package:bloc/bloc.dart';
import '../../domain/models/sucursal_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/iam_repository.dart';

// ─── EVENTOS ──────────────────────────────────────────────────────────────────
abstract class IamEvent {}

class IamUsersRequested      extends IamEvent {}
class IamRolesRequested      extends IamEvent {}
class IamSucursalesRequested extends IamEvent {}

class IamUserCreateRequested extends IamEvent {
  final Map<String, dynamic> data;
  IamUserCreateRequested(this.data);
}

class IamUserUpdateRequested extends IamEvent {
  final String id;
  final Map<String, dynamic> data;
  IamUserUpdateRequested(this.id, this.data);
}

/// [nuevoEstado] = estado AL QUE queremos cambiar (ya invertido antes de enviar)
class IamUserToggleRequested extends IamEvent {
  final String id;
  final bool   nuevoEstado;
  IamUserToggleRequested(this.id, this.nuevoEstado);
}

class IamUserDeleteRequested extends IamEvent {
  final String id;
  IamUserDeleteRequested(this.id);
}

// ─── ESTADOS ──────────────────────────────────────────────────────────────────
abstract class IamState {}

class IamInitial extends IamState {}
class IamLoading extends IamState {}

class IamUsersLoaded extends IamState {
  final List<UserModel> users;
  final String?         message; // null = sin toast
  IamUsersLoaded(this.users, {this.message});
}

class IamRolesLoaded extends IamState {
  final List<String> roles;
  IamRolesLoaded(this.roles);
}

class IamSucursalesLoaded extends IamState {
  final List<SucursalModel> sucursales;
  IamSucursalesLoaded(this.sucursales);
}

/// Error preserva la lista de usuarios para no vaciar la pantalla al fallar
class IamError extends IamState {
  final String          message;
  final List<UserModel> users;
  IamError(this.message, {this.users = const []});
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────
class IamBloc extends Bloc<IamEvent, IamState> {
  final IamRepository repo;

  /// Caché local — se actualiza con cada operación exitosa
  List<UserModel> _cached = [];

  IamBloc({required this.repo}) : super(IamInitial()) {
    on<IamUsersRequested>(_onUsers);
    on<IamRolesRequested>(_onRoles);
    on<IamSucursalesRequested>(_onSucursales);
    on<IamUserCreateRequested>(_onCreate);
    on<IamUserUpdateRequested>(_onUpdate);
    on<IamUserToggleRequested>(_onToggle);
    on<IamUserDeleteRequested>(_onDelete);
  }

  // ── Cargar lista ────────────────────────────────────────────────────────────
  Future<void> _onUsers(IamUsersRequested _, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      _cached = await repo.getUsers();
      emit(IamUsersLoaded(_cached));
    } on Exception catch (e) {
      emit(IamError(_clean(e)));
    }
  }

  // ── Roles (para dropdown) ───────────────────────────────────────────────────
  Future<void> _onRoles(IamRolesRequested _, Emitter<IamState> emit) async {
    try {
      emit(IamRolesLoaded(await repo.getRoles()));
    } catch (_) {
      emit(IamRolesLoaded(
          ['ADMIN', 'SUPERVISOR', 'EMPLEADO', 'REPARTIDOR', 'CLIENTE']));
    }
  }

  // ── Sucursales (para dropdown) ──────────────────────────────────────────────
  Future<void> _onSucursales(
      IamSucursalesRequested _, Emitter<IamState> emit) async {
    try {
      emit(IamSucursalesLoaded(await repo.getSucursales()));
    } catch (_) {
      emit(IamSucursalesLoaded([]));
    }
  }

  // ── Crear ───────────────────────────────────────────────────────────────────
  Future<void> _onCreate(
      IamUserCreateRequested e, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      final user = await repo.createUser(e.data);
      _cached = [..._cached, user];
      emit(IamUsersLoaded(_cached,
          message: 'Usuario "${user.fullName}" creado exitosamente'));
    } on Exception catch (e) {
      emit(IamError(_clean(e), users: _cached));
    }
  }

  // ── Actualizar ──────────────────────────────────────────────────────────────
  Future<void> _onUpdate(
      IamUserUpdateRequested e, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      final updated = await repo.updateUser(e.id, e.data);
      _cached = _cached.map((u) => u.id == e.id ? updated : u).toList();
      emit(IamUsersLoaded(_cached, message: 'Usuario actualizado correctamente'));
    } on Exception catch (e) {
      emit(IamError(_clean(e), users: _cached));
    }
  }

  // ── Toggle activo/inactivo ──────────────────────────────────────────────────
  // Estrategia: Optimistic Update
  //   1. Cambia la UI de inmediato sin esperar al servidor (se siente rápido)
  //   2. Llama al backend con el nuevo estado
  //   3. Recarga la lista para confirmar el estado real del servidor
  //   4. Si falla → revierte el cambio y muestra error
  Future<void> _onToggle(
      IamUserToggleRequested e, Emitter<IamState> emit) async {
    // 1. Optimistic: actualiza localmente
    _cached = _cached
        .map((u) => u.id == e.id ? u.copyWith(activo: e.nuevoEstado) : u)
        .toList();
    emit(IamUsersLoaded(_cached));

    try {
      // 2. Llama al backend: PATCH /api/users/{id}/estado  body: {activo: bool}
      await repo.toggleUserStatus(e.id, e.nuevoEstado);

      // 3. Recarga para confirmar estado real (por si el servidor normaliza algo)
      _cached = await repo.getUsers();
      emit(IamUsersLoaded(_cached));
    } on Exception catch (ex) {
      // 4. Revertir si el servidor falla
      _cached = _cached
          .map((u) => u.id == e.id ? u.copyWith(activo: !e.nuevoEstado) : u)
          .toList();
      emit(IamError(_clean(ex), users: _cached));
    }
  }

  // ── Eliminar ────────────────────────────────────────────────────────────────
  Future<void> _onDelete(
      IamUserDeleteRequested e, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      await repo.deleteUser(e.id);
      _cached = _cached.where((u) => u.id != e.id).toList();
      emit(IamUsersLoaded(_cached, message: 'Usuario eliminado correctamente'));
    } on Exception catch (e) {
      emit(IamError(_clean(e), users: _cached));
    }
  }

  String _clean(Exception e) =>
      e.toString().replaceAll('Exception: ', '');
}