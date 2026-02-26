// lib/src/features/guias/data/repositories/guia_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../domain/models/guia_model.dart';
import '../../domain/repositories/guia_repository.dart';

class GuiaRepositoryImpl implements GuiaRepository {
  final http.Client _client = http.Client();
  static const _base = '${ApiConstants.baseUrl}/api/guias';

  Future<Map<String, String>> get _headers async {
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
      case 404: throw Exception('Guía no encontrada.');
      default:  throw Exception(msg);
    }
  }

  GuiaModel _one(http.Response res) =>
      GuiaModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);

  List<GuiaModel> _list(http.Response res) =>
      (jsonDecode(utf8.decode(res.bodyBytes)) as List)
          .map((e) => GuiaModel.fromJson(e as Map<String, dynamic>))
          .toList();

  @override
  Future<List<GuiaModel>> findAll() async {
    final res = await _client.get(Uri.parse(_base), headers: await _headers);
    _check(res, 'obtener guías');
    return _list(res);
  }

  @override
  Future<GuiaModel> findById(String id) async {
    final res = await _client.get(Uri.parse('$_base/$id'), headers: await _headers);
    _check(res, 'obtener guía');
    return _one(res);
  }

  @override
  Future<GuiaModel> findByNumero(String numero) async {
    final res = await _client.get(Uri.parse('$_base/numero/$numero'), headers: await _headers);
    _check(res, 'buscar guía por número');
    return _one(res);
  }

  @override
  Future<GuiaModel> findByPedido(String pedidoId) async {
    final res = await _client.get(Uri.parse('$_base/pedido/$pedidoId'), headers: await _headers);
    _check(res, 'buscar guía por pedido');
    return _one(res);
  }

  @override
  Future<List<GuiaModel>> findByEstado(EstadoGuia estado) async {
    final res = await _client.get(Uri.parse('$_base/estado/${estado.name}'), headers: await _headers);
    _check(res, 'filtrar guías por estado');
    return _list(res);
  }

  @override
  Future<List<GuiaModel>> findByCliente(String clienteId) async {
    final res = await _client.get(Uri.parse('$_base/cliente/$clienteId'), headers: await _headers);
    _check(res, 'obtener guías del cliente');
    return _list(res);
  }

  @override
  Future<List<GuiaModel>> findByDespacho(String numeroDespacho) async {
    final res = await _client.get(Uri.parse('$_base/despacho/$numeroDespacho'), headers: await _headers);
    _check(res, 'obtener guías del despacho');
    return _list(res);
  }

  @override
  Future<GuiaModel> generar(Map<String, dynamic> data) async {
    final res = await _client.post(Uri.parse(_base),
        headers: await _headers, body: jsonEncode(data));
    _check(res, 'generar guía');
    return _one(res);
  }

  @override
  Future<GuiaModel> asignarDespacho(String id, Map<String, dynamic> data) async {
    final res = await _client.patch(Uri.parse('$_base/$id/despacho'),
        headers: await _headers, body: jsonEncode(data));
    _check(res, 'asignar despacho');
    return _one(res);
  }

  @override
  Future<GuiaModel> cambiarEstado(String id, EstadoGuia estado) async {
    final res = await _client.patch(Uri.parse('$_base/$id/estado'),
        headers: await _headers,
        body: jsonEncode({'estado': estado.name}));
    _check(res, 'cambiar estado de guía');
    return _one(res);
  }

  @override
  Future<GuiaModel> anular(String id, String motivo) async {
    final res = await _client.patch(Uri.parse('$_base/$id/anular'),
        headers: await _headers,
        body: jsonEncode({'motivo': motivo}));
    _check(res, 'anular guía');
    return _one(res);
  }
}