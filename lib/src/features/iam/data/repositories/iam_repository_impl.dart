// lib/src/features/iam/data/repositories/iam_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/sucursal_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/iam_repository.dart';

class IamRepositoryImpl implements IamRepository {
  final http.Client _client = http.Client();

  // ── JWT desde SharedPreferences ────────────────────────────────────────────
  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('eq_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Verificar código HTTP y lanzar mensaje legible ──────────────────────────
  void _check(http.Response res, String op) {
    // 2xx son todos éxito (incluye 200, 201, 204)
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    String msg = 'Error al $op (código ${res.statusCode})';
    try {
      if (res.body.isNotEmpty) {
        final b = jsonDecode(utf8.decode(res.bodyBytes));
        if (b is Map) {
          msg = b['message']?.toString()
              ?? b['error']?.toString()
              ?? msg;
        }
      }
    } catch (_) {}

    switch (res.statusCode) {
      case 400: throw Exception(msg);
      case 401: throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
      case 403: throw Exception('Sin permisos para $op.');
      case 404: throw Exception('Recurso no encontrado.');
      case 409: throw Exception(msg); // conflicto: usuario/correo duplicado
      default:  throw Exception(msg);
    }
  }

  // ==========================================================================
  // USUARIOS
  // ==========================================================================

  /// GET /api/users
  @override
  Future<List<UserModel>> getUsers() async {
    final res = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/api/users'),
      headers: await _headers,
    );
    _check(res, 'obtener usuarios');
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/users/{id}
  @override
  Future<UserModel> getUserById(String id) async {
    final res = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/api/users/$id'),
      headers: await _headers,
    );
    _check(res, 'obtener usuario');
    return UserModel.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
  }

  /// POST /api/users
  /// Body exacto que espera el backend:
  /// { nombre, apellido, username, correo, telefono, nacionalidad,
  ///   provincia, ciudad, direccion, fechaNacimiento, password,
  ///   rol, sucursalId? }
  @override
  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/api/users'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'crear usuario');
    return UserModel.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
  }

  /// PUT /api/users/{id}
  @override
  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _client.put(
      Uri.parse('${ApiConstants.baseUrl}/api/users/$id'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'actualizar usuario');
    return UserModel.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
  }

  /// PATCH /api/users/{id}/estado
  /// Body: { "activo": true }  o  { "activo": false }
  ///
  /// Sigue el mismo patrón que ClienteController.cambiarEstado() en tu backend.
  /// Si tu UserController usa un campo distinto (p.ej. "enabled" o "estado"),
  /// ajusta la key del body aquí.
  @override
  Future<void> toggleUserStatus(String id, bool nuevoEstado) async {
    final res = await _client.patch(
      Uri.parse('${ApiConstants.baseUrl}/api/users/$id/estado'),
      headers: await _headers,
      body: jsonEncode({'activo': nuevoEstado}),
    );
    _check(res, 'cambiar estado del usuario');
  }

  /// DELETE /api/users/{id}
  /// Spring devuelve 204 No Content → _check() lo acepta como éxito.
  @override
  Future<void> deleteUser(String id) async {
    final res = await _client.delete(
      Uri.parse('${ApiConstants.baseUrl}/api/users/$id'),
      headers: await _headers,
    );
    _check(res, 'eliminar usuario');
  }

  // ==========================================================================
  // ROLES — GET /api/roles
  // Fallback a lista fija si el endpoint no existe todavía.
  // ==========================================================================
  @override
  Future<List<String>> getRoles() async {
    try {
      final res = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/api/roles'),
        headers: await _headers,
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return list.map((e) {
          final raw = e is String
              ? e
              : (e['name'] ?? e['roleName'] ?? e.toString()).toString();
          return raw.replaceAll('ROLE_', '');
        }).toList();
      }
    } catch (_) {}
    return ['ADMIN', 'SUPERVISOR', 'EMPLEADO', 'REPARTIDOR', 'CLIENTE'];
  }

  // ==========================================================================
  // SUCURSALES — GET /api/sucursales  (solo devuelve las ACTIVAS)
  // Endpoint confirmado en SucursalController.findAll()
  // ==========================================================================
  @override
  Future<List<SucursalModel>> getSucursales() async {
    try {
      final res = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/api/sucursales'),
        headers: await _headers,
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return list
            .map((e) => SucursalModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}