// lib/src/features/iam/domain/repositories/iam_repository.dart
import '../models/permission_model.dart';
import '../models/role_model.dart';
import '../models/sucursal_model.dart';
import '../models/user_model.dart';

abstract class IamRepository {
  // ── Usuarios — /api/users ─────────────────────────────────────────────────
  Future<List<UserModel>> getUsers();
  Future<UserModel>       getUserById(String id);
  Future<UserModel>       createUser(Map<String, dynamic> data);
  Future<UserModel>       updateUser(String id, Map<String, dynamic> data);
  Future<void>            toggleUserStatus(String id, bool nuevoEstado);
  Future<void>            deleteUser(String id);

  // ── Roles — /api/roles ────────────────────────────────────────────────────
  // POST /api/roles           body: {"name": "ADMIN"}
  // GET  /api/roles
  // PUT  /api/roles/{id}/permissions  body: ["uuid1","uuid2"]
  Future<List<RoleModel>> getRoles();
  Future<RoleModel>       createRole(String name);
  Future<RoleModel>       assignPermissions(String roleId, List<String> permissionIds);

  // ── Permisos — /api/permissions ───────────────────────────────────────────
  // POST /api/permissions     body: {"name": "CREATE_USER"}
  // GET  /api/permissions
  Future<List<PermissionModel>> getPermissions();
  Future<PermissionModel>       createPermission(String name);

  // ── Catálogo ──────────────────────────────────────────────────────────────
  Future<List<SucursalModel>> getSucursales();
}