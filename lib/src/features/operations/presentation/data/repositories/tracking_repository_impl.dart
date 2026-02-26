// lib/src/features/tracking/data/repositories/tracking_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../domain/models/tracking_model.dart';
import '../../domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final http.Client _client = http.Client();
  static const _base = '${ApiConstants.baseUrl}/api/tracking';

  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('eq_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> get _publicHeaders => {'Content-Type': 'application/json'};

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
      case 404: throw Exception('Pedido no encontrado.');
      default:  throw Exception(msg);
    }
  }

  TrackingResumenModel _resumen(http.Response res) =>
      TrackingResumenModel.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);

  TrackingEventoModel _evento(http.Response res) =>
      TrackingEventoModel.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);

  List<TrackingEventoModel> _listEventos(http.Response res) =>
      (jsonDecode(utf8.decode(res.bodyBytes)) as List)
          .map((e) => TrackingEventoModel.fromJson(e as Map<String, dynamic>))
          .toList();

  List<TrackingResumenModel> _listResumen(http.Response res) =>
      (jsonDecode(utf8.decode(res.bodyBytes)) as List)
          .map((e) => TrackingResumenModel.fromJson(e as Map<String, dynamic>))
          .toList();

  @override
  Future<TrackingResumenModel> getHistorialCompleto(String pedidoId) async {
    final res = await _client.get(
        Uri.parse('$_base/pedido/$pedidoId'), headers: await _headers);
    _check(res, 'obtener historial');
    return _resumen(res);
  }

  @override
  Future<TrackingResumenModel> getHistorialPublico(String numeroPedido) async {
    final res = await _client.get(
        Uri.parse('$_base/public/pedido/$numeroPedido'), headers: _publicHeaders);
    _check(res, 'obtener tracking público');
    return _resumen(res);
  }

  @override
  Future<TrackingResumenModel> getHistorialPorTracking(String trackingExterno) async {
    final res = await _client.get(
        Uri.parse('$_base/public/tracking-externo/$trackingExterno'),
        headers: _publicHeaders);
    _check(res, 'buscar por tracking externo');
    return _resumen(res);
  }

  @override
  Future<List<TrackingEventoModel>> getEventosPorSucursal(String sucursalId) async {
    final res = await _client.get(
        Uri.parse('$_base/sucursal/$sucursalId'), headers: await _headers);
    _check(res, 'obtener eventos por sucursal');
    return _listEventos(res);
  }

  @override
  Future<List<TrackingEventoModel>> getEventosPorDespacho(String numeroDespacho) async {
    final res = await _client.get(
        Uri.parse('$_base/despacho/$numeroDespacho'), headers: await _headers);
    _check(res, 'obtener eventos por despacho');
    return _listEventos(res);
  }

  @override
  Future<List<TrackingResumenModel>> getTrackingPorCliente(String clienteId) async {
    final res = await _client.get(
        Uri.parse('$_base/cliente/$clienteId'), headers: await _headers);
    _check(res, 'obtener tracking por cliente');
    return _listResumen(res);
  }

  @override
  Future<TrackingEventoModel> registrarEventoManual(
      String pedidoId, Map<String, dynamic> data) async {
    final res = await _client.post(
        Uri.parse('$_base/pedido/$pedidoId/evento'),
        headers: await _headers,
        body: jsonEncode(data));
    _check(res, 'registrar evento');
    return _evento(res);
  }
}