// lib/src/features/clientes/data/repositories/cliente_repository_impl.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/cliente_model.dart';
import '../../domain/repositories/cliente_repository.dart';

class ClienteRepositoryImpl implements ClienteRepository {
  final _client = http.Client();

  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('eq_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String get _base => ApiConstants.baseUrl;

  List<ClienteModel> _parseList(http.Response res) =>
      (jsonDecode(utf8.decode(res.bodyBytes)) as List)
          .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
          .toList();

  ClienteModel _parseOne(http.Response res) =>
      ClienteModel.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);

  void _check(http.Response res, String op) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String msg = 'Error al $op (${res.statusCode})';
    try {
      if (res.body.isNotEmpty) {
        final b = jsonDecode(utf8.decode(res.bodyBytes));
        if (b is Map) {
          msg = b['message']?.toString() ?? b['error']?.toString() ?? msg;
        }
      }
    } catch (_) {}
    switch (res.statusCode) {
      case 401: throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
      case 403: throw Exception('Sin permisos para $op.');
      case 404: throw Exception('Cliente no encontrado.');
      default:  throw Exception(msg);
    }
  }

  // GET /api/clientes — solo activos
  @override
  Future<List<ClienteModel>> getAll() async {
    final res = await _client.get(
      Uri.parse('$_base/api/clientes'),
      headers: await _headers,
    );
    _check(res, 'obtener clientes');
    return _parseList(res);
  }

  // GET /api/clientes/todos — todos incluyendo inactivos
  @override
  Future<List<ClienteModel>> getTodos() async {
    final res = await _client.get(
      Uri.parse('$_base/api/clientes/todos'),
      headers: await _headers,
    );
    _check(res, 'obtener todos los clientes');
    return _parseList(res);
  }

  // GET /api/clientes/{id}
  @override
  Future<ClienteModel> getById(String id) async {
    final res = await _client.get(
      Uri.parse('$_base/api/clientes/$id'),
      headers: await _headers,
    );
    _check(res, 'obtener cliente');
    return _parseOne(res);
  }

  // GET /api/clientes/sucursal/{sucursalId}
  @override
  Future<List<ClienteModel>> getBySucursal(String sucursalId) async {
    final res = await _client.get(
      Uri.parse('$_base/api/clientes/sucursal/$sucursalId'),
      headers: await _headers,
    );
    _check(res, 'obtener clientes por sucursal');
    return _parseList(res);
  }

  // GET /api/clientes/buscar?q=
  @override
  Future<List<ClienteModel>> buscar(String q) async {
    final res = await _client.get(
      Uri.parse('$_base/api/clientes/buscar?q=${Uri.encodeComponent(q)}'),
      headers: await _headers,
    );
    _check(res, 'buscar clientes');
    return _parseList(res);
  }

  // POST /api/clientes
  @override
  Future<ClienteModel> create(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('$_base/api/clientes'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'crear cliente');
    return _parseOne(res);
  }

  // PUT /api/clientes/{id}
  @override
  Future<ClienteModel> update(String id, Map<String, dynamic> data) async {
    final res = await _client.put(
      Uri.parse('$_base/api/clientes/$id'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'actualizar cliente');
    return _parseOne(res);
  }

  // PATCH /api/clientes/{id}/estado
  @override
  Future<ClienteModel> cambiarEstado(String id, EstadoCliente estado) async {
    final res = await _client.patch(
      Uri.parse('$_base/api/clientes/$id/estado'),
      headers: await _headers,
      body: jsonEncode({'estado': estado.name}),
    );
    _check(res, 'cambiar estado del cliente');
    return _parseOne(res);
  }

  // PATCH /api/clientes/{id}/sucursal
  @override
  Future<ClienteModel> asignarSucursal(String id, String sucursalId) async {
    final res = await _client.patch(
      Uri.parse('$_base/api/clientes/$id/sucursal'),
      headers: await _headers,
      body: jsonEncode({'sucursalId': sucursalId}),
    );
    _check(res, 'asignar sucursal');
    return _parseOne(res);
  }

  // ── Afiliados ──────────────────────────────────────────────────────────────

  // GET /api/clientes/identificacion/{numero}
  @override
  Future<Map<String, dynamic>> buscarPorIdentificacion(String numero) async {
    final res = await _client.get(
      Uri.parse('$_base/api/clientes/identificacion/$numero'),
      headers: await _headers,
    );
    _check(res, 'buscar cliente por identificación');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  // GET /api/clientes/{titularId}/afiliados
  @override
  Future<List<AfiliadoModel>> getAfiliados(String titularId) async {
    final res = await _client.get(
      Uri.parse('$_base/api/clientes/$titularId/afiliados'),
      headers: await _headers,
    );
    _check(res, 'obtener afiliados');
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List)
        .map((e) => AfiliadoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /api/clientes/{titularId}/afiliados
  @override
  Future<void> vincularAfiliado({
    required String titularId,
    required String afiliadoId,
    required String parentesco,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/api/clientes/$titularId/afiliados'),
      headers: await _headers,
      body: jsonEncode({'afiliadoId': afiliadoId, 'parentesco': parentesco}),
    );
    _check(res, 'vincular afiliado');
  }

  // DELETE /api/clientes/{titularId}/afiliados/{afiliadoId}
  @override
  Future<void> desvincularAfiliado({
    required String titularId,
    required String afiliadoId,
  }) async {
    final res = await _client.delete(
      Uri.parse('$_base/api/clientes/$titularId/afiliados/$afiliadoId'),
      headers: await _headers,
    );
    _check(res, 'desvincular afiliado');
  }
}