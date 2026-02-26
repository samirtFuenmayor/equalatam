// lib/src/features/tracking/domain/repositories/tracking_repository.dart
import '../models/tracking_model.dart';

abstract class TrackingRepository {
  // Empleados
  Future<TrackingResumenModel>        getHistorialCompleto(String pedidoId);
  Future<List<TrackingEventoModel>>   getEventosPorSucursal(String sucursalId);
  Future<List<TrackingEventoModel>>   getEventosPorDespacho(String numeroDespacho);
  Future<List<TrackingResumenModel>>  getTrackingPorCliente(String clienteId);
  Future<TrackingEventoModel>         registrarEventoManual(String pedidoId, Map<String, dynamic> data);

  // Públicos
  Future<TrackingResumenModel> getHistorialPublico(String numeroPedido);
  Future<TrackingResumenModel> getHistorialPorTracking(String trackingExterno);
}