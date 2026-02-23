// lib/src/features/network/data/repositories/sucursal_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../domain/models/sucursal_model.dart';
import '../../domain/repositories/sucursal_repository.dart';

class SucursalRepositoryImpl implements SucursalRepository {
  final http.Client _client = http.Client();

  static const _base = '${ApiConstants.baseUrl}/api/sucursales';

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
      case 404: throw Exception('Sucursal no encontrada.');
      default:  throw Exception(msg);
    }
  }

  List<SucursalModel> _parseList(http.Response res) =>
      (jsonDecode(utf8.decode(res.bodyBytes)) as List)
          .map((e) => SucursalModel.fromJson(e as Map<String, dynamic>))
          .toList();

  SucursalModel _parseOne(http.Response res) =>
      SucursalModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));

  // ── GET /api/sucursales ────────────────────────────────────────────────────
  @override
  Future<List<SucursalModel>> findAllActivas() async {
    final res = await _client.get(Uri.parse(_base), headers: await _h);
    _check(res, 'obtener sucursales activas');
    return _parseList(res);
  }

  // ── GET /api/sucursales/todas ──────────────────────────────────────────────
  @override
  Future<List<SucursalModel>> findAll() async {
    final res = await _client.get(Uri.parse('$_base/todas'), headers: await _h);
    _check(res, 'obtener todas las sucursales');
    return _parseList(res);
  }

  // ── GET /api/sucursales/{id} ───────────────────────────────────────────────
  @override
  Future<SucursalModel> findById(String id) async {
    final res = await _client.get(Uri.parse('$_base/$id'), headers: await _h);
    _check(res, 'obtener sucursal');
    return _parseOne(res);
  }

  // ── GET /api/sucursales/tipo/{tipo} ───────────────────────────────────────
  @override
  Future<List<SucursalModel>> findByTipo(TipoSucursal tipo) async {
    final res = await _client.get(
        Uri.parse('$_base/tipo/${tipo.name}'), headers: await _h);
    _check(res, 'filtrar por tipo');
    return _parseList(res);
  }

  // ── GET /api/sucursales/internacionales ───────────────────────────────────
  @override
  Future<List<SucursalModel>> findInternacionales() async {
    final res = await _client.get(
        Uri.parse('$_base/internacionales'), headers: await _h);
    _check(res, 'obtener internacionales');
    return _parseList(res);
  }

  // ── GET /api/sucursales/nacionales ────────────────────────────────────────
  @override
  Future<List<SucursalModel>> findNacionales() async {
    final res = await _client.get(
        Uri.parse('$_base/nacionales'), headers: await _h);
    _check(res, 'obtener nacionales');
    return _parseList(res);
  }

  // ── POST /api/sucursales ──────────────────────────────────────────────────
  // Body exacto: { nombre, codigo, tipo, pais, ciudad, direccion,
  //               telefono, email, responsable, prefijoCasillero }
  @override
  Future<SucursalModel> create(Map<String, dynamic> data) async {
    final res = await _client.post(Uri.parse(_base),
        headers: await _h, body: jsonEncode(data));
    _check(res, 'crear sucursal');
    return _parseOne(res);
  }

  // ── PUT /api/sucursales/{id} ──────────────────────────────────────────────
  @override
  Future<SucursalModel> update(String id, Map<String, dynamic> data) async {
    final res = await _client.put(Uri.parse('$_base/$id'),
        headers: await _h, body: jsonEncode(data));
    _check(res, 'actualizar sucursal');
    return _parseOne(res);
  }

  // ── DELETE /api/sucursales/{id} → soft delete ─────────────────────────────
  @override
  Future<void> desactivar(String id) async {
    final res = await _client.delete(
        Uri.parse('$_base/$id'), headers: await _h);
    _check(res, 'desactivar sucursal');
  }

  // ── PATCH /api/sucursales/{id}/reactivar ──────────────────────────────────
  @override
  Future<SucursalModel> reactivar(String id) async {
    final res = await _client.patch(
        Uri.parse('$_base/$id/reactivar'), headers: await _h);
    _check(res, 'reactivar sucursal');
    return _parseOne(res);
  }
}