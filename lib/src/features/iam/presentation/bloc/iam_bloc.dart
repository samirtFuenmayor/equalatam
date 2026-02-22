// lib/src/features/iam/presentation/bloc/iam_bloc.dart
import 'package:bloc/bloc.dart';
import '../../domain/models/permission_model.dart';
import '../../domain/models/role_model.dart';
import '../../domain/models/sucursal_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/iam_repository.dart';

// ─── EVENTOS ──────────────────────────────────────────────────────────────────

// Usuarios
class IamUsersRequested      extends IamEvent {}
class IamUserCreateRequested extends IamEvent {
  final Map<String, dynamic> data; IamUserCreateRequested(this.data);
}
class IamUserUpdateRequested extends IamEvent {
  final String id; final Map<String, dynamic> data;
  IamUserUpdateRequested(this.id, this.data);
}
class IamUserToggleRequested extends IamEvent {
  final String id; final bool nuevoEstado;
  IamUserToggleRequested(this.id, this.nuevoEstado);
}
class IamUserDeleteRequested extends IamEvent {
  final String id; IamUserDeleteRequested(this.id);
}

// Roles
class IamRolesRequested      extends IamEvent {}
class IamRoleCreateRequested extends IamEvent {
  final String name; IamRoleCreateRequested(this.name);
}
class IamRoleAssignPermsRequested extends IamEvent {
  final String roleId; final List<String> permissionIds;
  IamRoleAssignPermsRequested(this.roleId, this.permissionIds);
}

// Permisos
class IamPermissionsRequested      extends IamEvent {}
class IamPermissionCreateRequested extends IamEvent {
  final String name; IamPermissionCreateRequested(this.name);
}

// Catálogos
class IamSucursalesRequested extends IamEvent {}

abstract class IamEvent {}

// ─── ESTADOS ──────────────────────────────────────────────────────────────────
abstract class IamState {}

class IamInitial extends IamState {}
class IamLoading extends IamState {}

class IamUsersLoaded extends IamState {
  final List<UserModel> users;
  final String?         message;
  IamUsersLoaded(this.users, {this.message});
}

class IamRolesLoaded extends IamState {
  final List<RoleModel> roles;
  final String?         message;
  IamRolesLoaded(this.roles, {this.message});
}

class IamPermissionsLoaded extends IamState {
  final List<PermissionModel> permissions;
  final String?               message;
  IamPermissionsLoaded(this.permissions, {this.message});
}

class IamSucursalesLoaded extends IamState {
  final List<SucursalModel> sucursales;
  IamSucursalesLoaded(this.sucursales);
}

class IamError extends IamState {
  final String              message;
  final List<UserModel>       users;
  final List<RoleModel>       roles;
  final List<PermissionModel> permissions;
  IamError(this.message, {
    this.users       = const [],
    this.roles       = const [],
    this.permissions = const [],
  });
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────
class IamBloc extends Bloc<IamEvent, IamState> {
  final IamRepository repo;

  List<UserModel>       _users       = [];
  List<RoleModel>       _roles       = [];
  List<PermissionModel> _permissions = [];

  IamBloc({required this.repo}) : super(IamInitial()) {
    on<IamUsersRequested>(_onUsers);
    on<IamUserCreateRequested>(_onUserCreate);
    on<IamUserUpdateRequested>(_onUserUpdate);
    on<IamUserToggleRequested>(_onUserToggle);
    on<IamUserDeleteRequested>(_onUserDelete);
    on<IamRolesRequested>(_onRoles);
    on<IamRoleCreateRequested>(_onRoleCreate);
    on<IamRoleAssignPermsRequested>(_onAssignPerms);
    on<IamPermissionsRequested>(_onPermissions);
    on<IamPermissionCreateRequested>(_onPermCreate);
    on<IamSucursalesRequested>(_onSucursales);
  }

  // ── Usuarios ───────────────────────────────────────────────────────────────
  Future<void> _onUsers(IamUsersRequested _, Emitter<IamState> emit) async {
    emit(IamLoading());
    try { _users = await repo.getUsers(); emit(IamUsersLoaded(_users)); }
    on Exception catch (e) { emit(IamError(_m(e))); }
  }

  Future<void> _onUserCreate(IamUserCreateRequested e, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      final u = await repo.createUser(e.data);
      _users = [..._users, u];
      emit(IamUsersLoaded(_users, message: 'Usuario "${u.fullName}" creado exitosamente'));
    } on Exception catch (e) { emit(IamError(_m(e), users: _users)); }
  }

  Future<void> _onUserUpdate(IamUserUpdateRequested e, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      final u = await repo.updateUser(e.id, e.data);
      _users = _users.map((x) => x.id == e.id ? u : x).toList();
      emit(IamUsersLoaded(_users, message: 'Usuario actualizado correctamente'));
    } on Exception catch (e) { emit(IamError(_m(e), users: _users)); }
  }

  Future<void> _onUserToggle(IamUserToggleRequested e, Emitter<IamState> emit) async {
    // Optimistic update
    _users = _users.map((u) =>
    u.id == e.id ? u.copyWith(activo: e.nuevoEstado) : u).toList();
    emit(IamUsersLoaded(_users));
    try {
      await repo.toggleUserStatus(e.id, e.nuevoEstado);
      _users = await repo.getUsers();
      emit(IamUsersLoaded(_users));
    } on Exception catch (ex) {
      // Revertir
      _users = _users.map((u) =>
      u.id == e.id ? u.copyWith(activo: !e.nuevoEstado) : u).toList();
      emit(IamError(_m(ex), users: _users));
    }
  }

  Future<void> _onUserDelete(IamUserDeleteRequested e, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      await repo.deleteUser(e.id);
      _users = _users.where((u) => u.id != e.id).toList();
      emit(IamUsersLoaded(_users, message: 'Usuario eliminado correctamente'));
    } on Exception catch (e) { emit(IamError(_m(e), users: _users)); }
  }

  // ── Roles ──────────────────────────────────────────────────────────────────
  Future<void> _onRoles(IamRolesRequested _, Emitter<IamState> emit) async {
    emit(IamLoading());
    try { _roles = await repo.getRoles(); emit(IamRolesLoaded(_roles)); }
    on Exception catch (e) { emit(IamError(_m(e), roles: _roles)); }
  }

  Future<void> _onRoleCreate(IamRoleCreateRequested e, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      final r = await repo.createRole(e.name);
      _roles = [..._roles, r];
      emit(IamRolesLoaded(_roles, message: 'Rol "${r.displayName}" creado exitosamente'));
    } on Exception catch (e) { emit(IamError(_m(e), roles: _roles)); }
  }

  Future<void> _onAssignPerms(IamRoleAssignPermsRequested e, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      final r = await repo.assignPermissions(e.roleId, e.permissionIds);
      _roles = _roles.map((x) => x.id == e.roleId ? r : x).toList();
      emit(IamRolesLoaded(_roles, message: 'Permisos asignados correctamente'));
    } on Exception catch (e) { emit(IamError(_m(e), roles: _roles)); }
  }

  // ── Permisos ───────────────────────────────────────────────────────────────
  Future<void> _onPermissions(IamPermissionsRequested _, Emitter<IamState> emit) async {
    emit(IamLoading());
    try { _permissions = await repo.getPermissions(); emit(IamPermissionsLoaded(_permissions)); }
    on Exception catch (e) { emit(IamError(_m(e), permissions: _permissions)); }
  }

  Future<void> _onPermCreate(IamPermissionCreateRequested e, Emitter<IamState> emit) async {
    emit(IamLoading());
    try {
      final p = await repo.createPermission(e.name);
      _permissions = [..._permissions, p];
      emit(IamPermissionsLoaded(_permissions,
          message: 'Permiso "${p.displayName}" creado exitosamente'));
    } on Exception catch (e) { emit(IamError(_m(e), permissions: _permissions)); }
  }

  // ── Catálogos ──────────────────────────────────────────────────────────────
  Future<void> _onSucursales(IamSucursalesRequested _, Emitter<IamState> emit) async {
    try { emit(IamSucursalesLoaded(await repo.getSucursales())); }
    catch (_) { emit(IamSucursalesLoaded([])); }
  }

  String _m(Exception e) => e.toString().replaceAll('Exception: ', '');
}