// lib/src/features/financiero/data/repositories/financiero_repository_impl.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/financiero_models.dart';
import '../../domain/repositories/fianciero_repository.dart';

class FinancieroRepositoryImpl implements FinancieroRepository {
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
  String get _fin  => '$_base/api/financiero';

  // ── Helpers ────────────────────────────────────────────────────────────────

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
      case 404: throw Exception('Recurso no encontrado.');
      default:  throw Exception(msg);
    }
  }

  Map<String, dynamic> _jsonMap(http.Response res) =>
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

  List<dynamic> _jsonList(http.Response res) =>
      jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;

  // ═══════════════════════════════════════════════════════════════════════════
  // TARIFAS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<TarifaModel>> getTarifas() async {
    final res = await _client.get(
      Uri.parse('$_fin/tarifas/todas'),
      headers: await _headers,
    );
    _check(res, 'obtener tarifas');
    return _jsonList(res)
        .map((e) => TarifaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TarifaModel>> getTarifasActivas() async {
    final res = await _client.get(
      Uri.parse('$_fin/tarifas'),
      headers: await _headers,
    );
    _check(res, 'obtener tarifas activas');
    return _jsonList(res)
        .map((e) => TarifaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TarifaModel> getTarifa(String id) async {
    final res = await _client.get(
      Uri.parse('$_fin/tarifas/$id'),
      headers: await _headers,
    );
    _check(res, 'obtener tarifa');
    return TarifaModel.fromJson(_jsonMap(res));
  }

  @override
  Future<TarifaModel> createTarifa(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('$_fin/tarifas'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'crear tarifa');
    return TarifaModel.fromJson(_jsonMap(res));
  }

  @override
  Future<TarifaModel> updateTarifa(String id, Map<String, dynamic> data) async {
    final res = await _client.put(
      Uri.parse('$_fin/tarifas/$id'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'actualizar tarifa');
    return TarifaModel.fromJson(_jsonMap(res));
  }

  @override
  Future<void> desactivarTarifa(String id) async {
    final res = await _client.delete(
      Uri.parse('$_fin/tarifas/$id'),
      headers: await _headers,
    );
    _check(res, 'desactivar tarifa');
  }

  @override
  Future<Map<String, dynamic>> calcularTarifa(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('$_fin/tarifas/calcular'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'calcular tarifa');
    return _jsonMap(res);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COTIZACIONES
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<CotizacionModel>> getCotizaciones() async {
    final res = await _client.get(
      Uri.parse('$_fin/cotizaciones'),
      headers: await _headers,
    );
    _check(res, 'obtener cotizaciones');
    return _jsonList(res)
        .map((e) => CotizacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CotizacionModel>> getCotizacionesByCliente(String clienteId) async {
    final res = await _client.get(
      Uri.parse('$_fin/cotizaciones/cliente/$clienteId'),
      headers: await _headers,
    );
    _check(res, 'obtener cotizaciones del cliente');
    return _jsonList(res)
        .map((e) => CotizacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CotizacionModel>> getCotizacionesByPedido(String pedidoId) async {
    final res = await _client.get(
      Uri.parse('$_fin/cotizaciones/pedido/$pedidoId'),
      headers: await _headers,
    );
    _check(res, 'obtener cotizaciones del pedido');
    return _jsonList(res)
        .map((e) => CotizacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CotizacionModel> getCotizacion(String id) async {
    final res = await _client.get(
      Uri.parse('$_fin/cotizaciones/$id'),
      headers: await _headers,
    );
    _check(res, 'obtener cotización');
    return CotizacionModel.fromJson(_jsonMap(res));
  }

  @override
  Future<CotizacionModel> createCotizacion(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('$_fin/cotizaciones'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'crear cotización');
    return CotizacionModel.fromJson(_jsonMap(res));
  }

  @override
  Future<CotizacionModel> aprobarCotizacion(String id) async {
    final res = await _client.post(
      Uri.parse('$_fin/cotizaciones/$id/aprobar'),
      headers: await _headers,
    );
    _check(res, 'aprobar cotización');
    return CotizacionModel.fromJson(_jsonMap(res));
  }

  @override
  Future<CotizacionModel> cancelarCotizacion(String id) async {
    final res = await _client.post(
      Uri.parse('$_fin/cotizaciones/$id/cancelar'),
      headers: await _headers,
    );
    _check(res, 'cancelar cotización');
    return CotizacionModel.fromJson(_jsonMap(res));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FACTURAS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<FacturaModel>> getFacturasPendientes() async {
    final res = await _client.get(
      Uri.parse('$_fin/facturas/pendientes'),
      headers: await _headers,
    );
    _check(res, 'obtener facturas pendientes');
    return _jsonList(res)
        .map((e) => FacturaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FacturaModel>> getFacturasByCliente(String clienteId) async {
    final res = await _client.get(
      Uri.parse('$_fin/facturas/cliente/$clienteId'),
      headers: await _headers,
    );
    _check(res, 'obtener facturas del cliente');
    return _jsonList(res)
        .map((e) => FacturaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FacturaModel>> getFacturasByPedido(String pedidoId) async {
    final res = await _client.get(
      Uri.parse('$_fin/facturas/pedido/$pedidoId'),
      headers: await _headers,
    );
    _check(res, 'obtener facturas del pedido');
    return _jsonList(res)
        .map((e) => FacturaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FacturaModel>> getFacturasByRango(String desde, String hasta) async {
    final res = await _client.get(
      Uri.parse('$_fin/facturas/rango?desde=$desde&hasta=$hasta'),
      headers: await _headers,
    );
    _check(res, 'obtener facturas por rango');
    return _jsonList(res)
        .map((e) => FacturaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FacturaModel> getFactura(String id) async {
    final res = await _client.get(
      Uri.parse('$_fin/facturas/$id'),
      headers: await _headers,
    );
    _check(res, 'obtener factura');
    return FacturaModel.fromJson(_jsonMap(res));
  }

  @override
  Future<FacturaModel> createFactura(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('$_fin/facturas'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'crear factura');
    return FacturaModel.fromJson(_jsonMap(res));
  }

  @override
  Future<FacturaModel> emitirFactura(String id) async {
    final res = await _client.post(
      Uri.parse('$_fin/facturas/$id/emitir'),
      headers: await _headers,
    );
    _check(res, 'emitir factura');
    return FacturaModel.fromJson(_jsonMap(res));
  }

  @override
  Future<FacturaModel> anularFactura(String id, String motivo) async {
    final res = await _client.post(
      Uri.parse('$_fin/facturas/$id/anular'),
      headers: await _headers,
      body: jsonEncode({'motivo': motivo}),
    );
    _check(res, 'anular factura');
    return FacturaModel.fromJson(_jsonMap(res));
  }

  @override
  Future<double> getDeudaCliente(String clienteId) async {
    final res = await _client.get(
      Uri.parse('$_fin/facturas/cliente/$clienteId/deuda'),
      headers: await _headers,
    );
    _check(res, 'obtener deuda del cliente');
    final body = _jsonMap(res);
    return (body['deuda'] as num?)?.toDouble() ?? 0.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGOS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<PagoModel>> getPagosPendientes() async {
    final res = await _client.get(
      Uri.parse('$_fin/pagos/pendientes'),
      headers: await _headers,
    );
    _check(res, 'obtener pagos pendientes');
    return _jsonList(res)
        .map((e) => PagoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PagoModel>> getPagosByFactura(String facturaId) async {
    final res = await _client.get(
      Uri.parse('$_fin/pagos/factura/$facturaId'),
      headers: await _headers,
    );
    _check(res, 'obtener pagos de la factura');
    return _jsonList(res)
        .map((e) => PagoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PagoModel>> getPagosByCliente(String clienteId) async {
    final res = await _client.get(
      Uri.parse('$_fin/pagos/cliente/$clienteId'),
      headers: await _headers,
    );
    _check(res, 'obtener pagos del cliente');
    return _jsonList(res)
        .map((e) => PagoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PagoModel> getPago(String id) async {
    final res = await _client.get(
      Uri.parse('$_fin/pagos/$id'),
      headers: await _headers,
    );
    _check(res, 'obtener pago');
    return PagoModel.fromJson(_jsonMap(res));
  }

  @override
  Future<PagoModel> registrarPago(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('$_fin/pagos'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    _check(res, 'registrar pago');
    return PagoModel.fromJson(_jsonMap(res));
  }

  @override
  Future<PagoModel> confirmarPago(String id) async {
    final res = await _client.post(
      Uri.parse('$_fin/pagos/$id/confirmar'),
      headers: await _headers,
    );
    _check(res, 'confirmar pago');
    return PagoModel.fromJson(_jsonMap(res));
  }

  @override
  Future<PagoModel> rechazarPago(String id, String motivo) async {
    final res = await _client.post(
      Uri.parse('$_fin/pagos/$id/rechazar'),
      headers: await _headers,
      body: jsonEncode({'motivo': motivo}),
    );
    _check(res, 'rechazar pago');
    return PagoModel.fromJson(_jsonMap(res));
  }
}