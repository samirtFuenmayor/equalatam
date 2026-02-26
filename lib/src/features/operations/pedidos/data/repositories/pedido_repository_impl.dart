// lib/src/features/pedidos/data/repositories/pedido_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../domain/model/pedido_model.dart';
import '../../domain/repositories/pedido_repository.dart';

class PedidoRepositoryImpl implements PedidoRepository {
  final http.Client _client = http.Client();
  static const _base = '${ApiConstants.baseUrl}/api/pedidos';

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
      case 404: throw Exception('Pedido no encontrado.');
      default:  throw Exception(msg);
    }
  }

  List<PedidoModel> _list(http.Response res) =>
      (jsonDecode(utf8.decode(res.bodyBytes)) as List)
          .map((e) => PedidoModel.fromJson(e as Map<String, dynamic>))
          .toList();

  PedidoModel _one(http.Response res) =>
      PedidoModel.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);

  // GET /api/pedidos
  @override
  Future<List<PedidoModel>> findAll() async {
    final res = await _client.get(Uri.parse(_base), headers: await _h);
    _check(res, 'obtener pedidos');
    return _list(res);
  }

  // GET /api/pedidos/{id}
  @override
  Future<PedidoModel> findById(String id) async {
    final res = await _client.get(Uri.parse('$_base/$id'), headers: await _h);
    _check(res, 'obtener pedido');
    return _one(res);
  }

  // GET /api/pedidos/numero/{numeroPedido}
  @override
  Future<PedidoModel> findByNumero(String numero) async {
    final res = await _client.get(
        Uri.parse('$_base/numero/$numero'), headers: await _h);
    _check(res, 'buscar por número');
    return _one(res);
  }

  // GET /api/pedidos/cliente/{clienteId}
  @override
  Future<List<PedidoModel>> findByCliente(String clienteId) async {
    final res = await _client.get(
        Uri.parse('$_base/cliente/$clienteId'), headers: await _h);
    _check(res, 'buscar pedidos del cliente');
    return _list(res);
  }

  // GET /api/pedidos/estado/{estado}
  @override
  Future<List<PedidoModel>> findByEstado(EstadoPedido estado) async {
    final res = await _client.get(
        Uri.parse('$_base/estado/${estado.name}'), headers: await _h);
    _check(res, 'filtrar por estado');
    return _list(res);
  }

  // GET /api/pedidos/sucursal-origen/{sucursalId}
  @override
  Future<List<PedidoModel>> findBySucursalOrigen(String sucursalId) async {
    final res = await _client.get(
        Uri.parse('$_base/sucursal-origen/$sucursalId'), headers: await _h);
    _check(res, 'buscar por sucursal origen');
    return _list(res);
  }

  // GET /api/pedidos/sucursal-destino/{sucursalId}
  @override
  Future<List<PedidoModel>> findBySucursalDestino(String sucursalId) async {
    final res = await _client.get(
        Uri.parse('$_base/sucursal-destino/$sucursalId'), headers: await _h);
    _check(res, 'buscar por sucursal destino');
    return _list(res);
  }

  // GET /api/pedidos/listos-para-despachar/{sucursalOrigenId}
  @override
  Future<List<PedidoModel>> findListosParaDespachar(String sucursalOrigenId) async {
    final res = await _client.get(
        Uri.parse('$_base/listos-para-despachar/$sucursalOrigenId'),
        headers: await _h);
    _check(res, 'buscar listos para despachar');
    return _list(res);
  }

  // GET /api/pedidos/disponibles/{sucursalDestinoId}
  @override
  Future<List<PedidoModel>> findDisponibles(String sucursalDestinoId) async {
    final res = await _client.get(
        Uri.parse('$_base/disponibles/$sucursalDestinoId'), headers: await _h);
    _check(res, 'buscar disponibles');
    return _list(res);
  }

  // GET /api/pedidos/buscar?q=xxx
  @override
  Future<List<PedidoModel>> buscar(String q) async {
    final uri = Uri.parse(_base).replace(
        pathSegments: [...Uri.parse(_base).pathSegments, 'buscar'],
        queryParameters: {'q': q});
    final res = await _client.get(uri, headers: await _h);
    _check(res, 'buscar pedidos');
    return _list(res);
  }

  // GET /api/pedidos/dashboard/conteos
  @override
  Future<Map<String, int>> conteosPorEstado() async {
    final res = await _client.get(
        Uri.parse('$_base/dashboard/conteos'), headers: await _h);
    _check(res, 'obtener conteos');
    final Map<String, dynamic> raw =
    jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return raw.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // POST /api/pedidos
  // body: { tipo, clienteId, trackingExterno, proveedor, descripcion, peso,
  //         valorDeclarado, cantidadItems, sucursalOrigenId, sucursalDestinoId,
  //         observaciones, notasInternas, fotoUrl }
  @override
  Future<PedidoModel> create(Map<String, dynamic> data) async {
    final res = await _client.post(Uri.parse(_base),
        headers: await _h, body: jsonEncode(data));
    _check(res, 'crear pedido');
    return _one(res);
  }

  // PUT /api/pedidos/{id}
  @override
  Future<PedidoModel> update(String id, Map<String, dynamic> data) async {
    final res = await _client.put(Uri.parse('$_base/$id'),
        headers: await _h, body: jsonEncode(data));
    _check(res, 'actualizar pedido');
    return _one(res);
  }

  // PATCH /api/pedidos/{id}/estado
  // body: { "estado": "ENTREGADO", "observacion": "...", "sucursalId": "uuid" }
  @override
  Future<PedidoModel> cambiarEstado(String id, EstadoPedido estado,
      {String? observacion, String? sucursalId}) async {
    final body = <String, String>{'estado': estado.name};
    if (observacion != null && observacion.isNotEmpty) {
      body['observacion'] = observacion;
    }
    if (sucursalId != null && sucursalId.isNotEmpty) {
      body['sucursalId'] = sucursalId;
    }
    final res = await _client.patch(
        Uri.parse('$_base/$id/estado'),
        headers: await _h, body: jsonEncode(body));
    _check(res, 'cambiar estado del pedido');
    return _one(res);
  }
}