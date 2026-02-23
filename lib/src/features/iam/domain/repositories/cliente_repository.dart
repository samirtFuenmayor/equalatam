// lib/src/features/clientes/domain/repositories/cliente_repository.dart

import '../models/cliente_model.dart';

abstract class ClienteRepository {
  Future<List<ClienteModel>> getAll();
  Future<List<ClienteModel>> getTodos();
  Future<ClienteModel>       getById(String id);
  Future<List<ClienteModel>> getBySucursal(String sucursalId);
  Future<List<ClienteModel>> buscar(String q);
  Future<ClienteModel>       create(Map<String, dynamic> data);
  Future<ClienteModel>       update(String id, Map<String, dynamic> data);
  Future<ClienteModel>       cambiarEstado(String id, EstadoCliente estado);
  Future<ClienteModel>       asignarSucursal(String id, String sucursalId);
}