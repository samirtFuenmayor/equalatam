// lib/src/features/financiero/domain/repositories/financiero_repository.dart

import '../models/financiero_models.dart';

abstract class FinancieroRepository {
  // ── Tarifas ────────────────────────────────────────────────────────────────
  Future<List<TarifaModel>> getTarifas();
  Future<List<TarifaModel>> getTarifasActivas();
  Future<TarifaModel>       getTarifa(String id);
  Future<TarifaModel>       createTarifa(Map<String, dynamic> data);
  Future<TarifaModel>       updateTarifa(String id, Map<String, dynamic> data);
  Future<void>              desactivarTarifa(String id);
  Future<Map<String, dynamic>> calcularTarifa(Map<String, dynamic> data);

  // ── Cotizaciones ───────────────────────────────────────────────────────────
  Future<List<CotizacionModel>> getCotizaciones();
  Future<List<CotizacionModel>> getCotizacionesByCliente(String clienteId);
  Future<List<CotizacionModel>> getCotizacionesByPedido(String pedidoId);
  Future<CotizacionModel>       getCotizacion(String id);
  Future<CotizacionModel>       createCotizacion(Map<String, dynamic> data);
  Future<CotizacionModel>       aprobarCotizacion(String id);
  Future<CotizacionModel>       cancelarCotizacion(String id);

  // ── Facturas ───────────────────────────────────────────────────────────────
  Future<List<FacturaModel>> getFacturasPendientes();
  Future<List<FacturaModel>> getFacturasByCliente(String clienteId);
  Future<List<FacturaModel>> getFacturasByPedido(String pedidoId);
  Future<List<FacturaModel>> getFacturasByRango(String desde, String hasta);
  Future<FacturaModel>       getFactura(String id);
  Future<FacturaModel>       createFactura(Map<String, dynamic> data);
  Future<FacturaModel>       emitirFactura(String id);
  Future<FacturaModel>       anularFactura(String id, String motivo);
  Future<double>             getDeudaCliente(String clienteId);

  // ── Pagos ──────────────────────────────────────────────────────────────────
  Future<List<PagoModel>> getPagosPendientes();
  Future<List<PagoModel>> getPagosByFactura(String facturaId);
  Future<List<PagoModel>> getPagosByCliente(String clienteId);
  Future<PagoModel>       getPago(String id);
  Future<PagoModel>       registrarPago(Map<String, dynamic> data);
  Future<PagoModel>       confirmarPago(String id);
  Future<PagoModel>       rechazarPago(String id, String motivo);
}