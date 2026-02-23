// lib/src/features/despachos/data/repositories/despacho_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../domain/models/despacho_model.dart';
import '../../domain/repositories/despacho_repository.dart';

class DespachoRepositoryImpl implements DespachoRepository {
  final http.Client _client = http.Client();
  static const _base = '${ApiConstants.baseUrl}/api/despachos';

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
        if (b is Map) {
          msg = b['message']?.toString() ?? b['error']?.toString() ?? msg;
        }
      }
    } catch (_) {}
    switch (res.statusCode) {
      case 401: throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
      case 403: throw Exception('Sin permisos para $op.');
      case 404: throw Exception('Despacho no encontrado.');
      default:  throw Exception(msg);
    }
  }

  List<DespachoModel> _list(http.Response res) =>
      (jsonDecode(utf8.decode(res.bodyBytes)) as List)
          .map((e) => DespachoModel.fromJson(e as Map<String, dynamic>))
          .toList();

  DespachoModel _one(http.Response res) =>
      DespachoModel.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);

  // GET /api/despachos
  @override
  Future<List<DespachoModel>> findAll() async {
    final res = await _client.get(Uri.parse(_base), headers: await _h);
    _check(res, 'obtener despachos');
    return _list(res);
  }

  // GET /api/despachos/{id}
  @override
  Future<DespachoModel> findById(String id) async {
    final res = await _client.get(Uri.parse('$_base/$id'), headers: await _h);
    _check(res, 'obtener despacho');
    return _one(res);
  }

  // GET /api/despachos/numero/{numero}
  @override
  Future<DespachoModel> findByNumero(String numero) async {
    final res = await _client.get(
        Uri.parse('$_base/numero/$numero'), headers: await _h);
    _check(res, 'buscar despacho por número');
    return _one(res);
  }

  // GET /api/despachos/estado/{estado}
  @override
  Future<List<DespachoModel>> findByEstado(EstadoDespacho estado) async {
    final res = await _client.get(
        Uri.parse('$_base/estado/${estado.name}'), headers: await _h);
    _check(res, 'filtrar por estado');
    return _list(res);
  }

  // GET /api/despachos/abiertos/sucursal/{sucursalId}
  @override
  Future<List<DespachoModel>> findAbiertosEnSucursal(String sucursalId) async {
    final res = await _client.get(
        Uri.parse('$_base/abiertos/sucursal/$sucursalId'), headers: await _h);
    _check(res, 'obtener abiertos en sucursal');
    return _list(res);
  }

  // GET /api/despachos/en-transito/hacia/{sucursalId}
  @override
  Future<List<DespachoModel>> findEnTransitoHacia(String sucursalId) async {
    final res = await _client.get(
        Uri.parse('$_base/en-transito/hacia/$sucursalId'), headers: await _h);
    _check(res, 'obtener en tránsito');
    return _list(res);
  }

  // POST /api/despachos
  // body exacto: { sucursalOrigenId, sucursalDestinoId, aerolinea,
  //   numeroVuelo, guiaAerea, tipoTransporte,
  //   fechaSalidaProgramada, fechaLlegadaProgramada, observaciones }
  @override
  Future<DespachoModel> create(Map<String, dynamic> data) async {
    final res = await _client.post(Uri.parse(_base),
        headers: await _h, body: jsonEncode(data));
    _check(res, 'crear despacho');
    return _one(res);
  }

  // PUT /api/despachos/{id}/transporte
  // body: mismo formato que create
  @override
  Future<DespachoModel> actualizarTransporte(
      String id, Map<String, dynamic> data) async {
    final res = await _client.put(
        Uri.parse('$_base/$id/transporte'),
        headers: await _h, body: jsonEncode(data));
    _check(res, 'actualizar transporte');
    return _one(res);
  }

  // PATCH /api/despachos/{id}/estado
  // body: { "estado": "CERRADO", "observacion": "..." }
  @override
  Future<DespachoModel> cambiarEstado(
      String id, EstadoDespacho estado, {String? observacion}) async {
    final body = <String, String>{'estado': estado.name};
    if (observacion != null && observacion.isNotEmpty) {
      body['observacion'] = observacion;
    }
    final res = await _client.patch(
        Uri.parse('$_base/$id/estado'),
        headers: await _h, body: jsonEncode(body));
    _check(res, 'cambiar estado del despacho');
    return _one(res);
  }

  // POST /api/despachos/{id}/pedidos
  // body: ["uuid1","uuid2"]  ← array directo de UUIDs (Set<UUID> en Java)
  @override
  Future<DespachoModel> agregarPedidos(
      String id, List<String> pedidoIds) async {
    final res = await _client.post(
        Uri.parse('$_base/$id/pedidos'),
        headers: await _h, body: jsonEncode(pedidoIds));
    _check(res, 'agregar pedidos al despacho');
    return _one(res);
  }

  // DELETE /api/despachos/{id}/pedidos/{pedidoId}
  @override
  Future<DespachoModel> quitarPedido(String id, String pedidoId) async {
    final res = await _client.delete(
        Uri.parse('$_base/$id/pedidos/$pedidoId'), headers: await _h);
    _check(res, 'quitar pedido del despacho');
    return _one(res);
  }
}