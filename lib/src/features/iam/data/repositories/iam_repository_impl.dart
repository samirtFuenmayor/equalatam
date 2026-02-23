// lib/src/features/iam/data/repositories/iam_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/permission_model.dart';
import '../../domain/models/role_model.dart';
import '../../domain/models/sucursal_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/iam_repository.dart';

class IamRepositoryImpl implements IamRepository {
  final http.Client _client = http.Client();

  Future<Map<String, String>> get _h async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('eq_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _check(http.Response res, String op) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String msg = 'Error al $op (${res.statusCode})';
    try {
      if (res.body.isNotEmpty) {
        final b = jsonDecode(utf8.decode(res.bodyBytes));
        if (b is Map) msg = b['message']?.toString() ?? b['error']?.toString() ?? msg;
      }
    } catch (_) {}
    switch (res.statusCode) {
      case 401: throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
      case 403: throw Exception('Sin permisos para $op.');
      case 404: throw Exception('Recurso no encontrado.');
      default:  throw Exception(msg);
    }
  }

  // ── Usuarios ───────────────────────────────────────────────────────────────
  @override Future<List<UserModel>> getUsers() async {
    final res = await _client.get(Uri.parse('${ApiConstants.baseUrl}/api/users'), headers: await _h);
    _check(res, 'obtener usuarios');
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List).map((e) => UserModel.fromJson(e)).toList();
  }

  @override Future<UserModel> getUserById(String id) async {
    final res = await _client.get(Uri.parse('${ApiConstants.baseUrl}/api/users/$id'), headers: await _h);
    _check(res, 'obtener usuario');
    return UserModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  @override Future<UserModel> createUser(Map<String, dynamic> data) async {
    final res = await _client.post(Uri.parse('${ApiConstants.baseUrl}/api/users'),
        headers: await _h, body: jsonEncode(data));
    _check(res, 'crear usuario');
    return UserModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  @override Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _client.put(Uri.parse('${ApiConstants.baseUrl}/api/users/$id'),
        headers: await _h, body: jsonEncode(data));
    _check(res, 'actualizar usuario');
    return UserModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  @override Future<void> toggleUserStatus(String id, bool nuevoEstado) async {
    final res = await _client.patch(Uri.parse('${ApiConstants.baseUrl}/api/users/$id/estado'),
        headers: await _h, body: jsonEncode({'activo': nuevoEstado}));
    _check(res, 'cambiar estado');
  }

  @override Future<void> deleteUser(String id) async {
    final res = await _client.delete(Uri.parse('${ApiConstants.baseUrl}/api/users/$id'), headers: await _h);
    _check(res, 'eliminar usuario');
  }

  // ── Roles ──────────────────────────────────────────────────────────────────
  // GET /api/roles
  @override Future<List<RoleModel>> getRoles() async {
    final res = await _client.get(Uri.parse('${ApiConstants.baseUrl}/api/roles'), headers: await _h);
    _check(res, 'obtener roles');
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List).map((e) => RoleModel.fromJson(e)).toList();
  }

  // POST /api/roles   body: {"name": "ADMIN"}
  @override Future<RoleModel> createRole(String name) async {
    final res = await _client.post(Uri.parse('${ApiConstants.baseUrl}/api/roles'),
        headers: await _h, body: jsonEncode({'name': name}));
    _check(res, 'crear rol');
    return RoleModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  // PUT /api/roles/{roleId}/permissions   body: ["uuid1","uuid2"]
  @override Future<RoleModel> assignPermissions(String roleId, List<String> permissionIds) async {
    final res = await _client.put(
        Uri.parse('${ApiConstants.baseUrl}/api/roles/$roleId/permissions'),
        headers: await _h,
        body: jsonEncode(permissionIds)); // Array directo, no objeto
    _check(res, 'asignar permisos');
    return RoleModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  // ── Permisos ───────────────────────────────────────────────────────────────
  // GET /api/permissions
  @override Future<List<PermissionModel>> getPermissions() async {
    final res = await _client.get(Uri.parse('${ApiConstants.baseUrl}/api/permissions'), headers: await _h);
    _check(res, 'obtener permisos');
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List).map((e) => PermissionModel.fromJson(e)).toList();
  }

  // POST /api/permissions   body: {"name": "CREATE_USER"}
  @override Future<PermissionModel> createPermission(String name) async {
    final res = await _client.post(Uri.parse('${ApiConstants.baseUrl}/api/permissions'),
        headers: await _h, body: jsonEncode({'name': name}));
    _check(res, 'crear permiso');
    return PermissionModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  // ── Sucursales ─────────────────────────────────────────────────────────────
  @override Future<List<SucursalModel>> getSucursales() async {
    try {
      final res = await _client.get(Uri.parse('${ApiConstants.baseUrl}/api/sucursales'), headers: await _h);
      if (res.statusCode == 200) {
        return (jsonDecode(utf8.decode(res.bodyBytes)) as List).map((e) => SucursalModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> assignRolesToUser(String userId, List<String> roleIds) async {
    final res = await _client.put(
      Uri.parse('${ApiConstants.baseUrl}/api/users/$userId/roles'),
      headers: await _h,
      body: jsonEncode(roleIds),
    );
    _check(res, 'asignar rol');
  }
}