// lib/src/features/despachos/domain/repositories/despacho_repository.dart
import '../models/despacho_model.dart';

abstract class DespachoRepository {
  Future<List<DespachoModel>> findAll();
  Future<DespachoModel>       findById(String id);
  Future<DespachoModel>       findByNumero(String numero);
  Future<List<DespachoModel>> findByEstado(EstadoDespacho estado);
  Future<List<DespachoModel>> findAbiertosEnSucursal(String sucursalId);
  Future<List<DespachoModel>> findEnTransitoHacia(String sucursalId);
  // POST /api/despachos
  Future<DespachoModel>       create(Map<String, dynamic> data);
  // PUT  /api/despachos/{id}/transporte
  Future<DespachoModel>       actualizarTransporte(String id, Map<String, dynamic> data);
  // PATCH /api/despachos/{id}/estado  body: {"estado":"CERRADO","observacion":"..."}
  Future<DespachoModel>       cambiarEstado(String id, EstadoDespacho estado, {String? observacion});
  // POST /api/despachos/{id}/pedidos  body: ["uuid1","uuid2"]
  Future<DespachoModel>       agregarPedidos(String id, List<String> pedidoIds);
  // DELETE /api/despachos/{id}/pedidos/{pedidoId}
  Future<DespachoModel>       quitarPedido(String id, String pedidoId);
}