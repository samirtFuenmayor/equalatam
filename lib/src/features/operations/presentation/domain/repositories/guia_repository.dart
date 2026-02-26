// lib/src/features/guias/domain/repositories/guia_repository.dart
import '../models/guia_model.dart';

abstract class GuiaRepository {
  Future<List<GuiaModel>> findAll();
  Future<GuiaModel>       findById(String id);
  Future<GuiaModel>       findByNumero(String numero);
  Future<GuiaModel>       findByPedido(String pedidoId);
  Future<List<GuiaModel>> findByEstado(EstadoGuia estado);
  Future<List<GuiaModel>> findByCliente(String clienteId);
  Future<List<GuiaModel>> findByDespacho(String numeroDespacho);
  Future<GuiaModel>       generar(Map<String, dynamic> data);
  Future<GuiaModel>       asignarDespacho(String id, Map<String, dynamic> data);
  Future<GuiaModel>       cambiarEstado(String id, EstadoGuia estado);
  Future<GuiaModel>       anular(String id, String motivo);
}