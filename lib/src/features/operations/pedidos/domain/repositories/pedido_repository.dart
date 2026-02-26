// lib/src/features/pedidos/domain/repositories/pedido_repository.dart
import '../model/pedido_model.dart';

abstract class PedidoRepository {
  // GET  /api/pedidos
  Future<List<PedidoModel>> findAll();
  // GET  /api/pedidos/{id}
  Future<PedidoModel> findById(String id);
  // GET  /api/pedidos/numero/{numeroPedido}
  Future<PedidoModel> findByNumero(String numero);
  // GET  /api/pedidos/cliente/{clienteId}
  Future<List<PedidoModel>> findByCliente(String clienteId);
  // GET  /api/pedidos/estado/{estado}
  Future<List<PedidoModel>> findByEstado(EstadoPedido estado);
  // GET  /api/pedidos/sucursal-origen/{sucursalId}
  Future<List<PedidoModel>> findBySucursalOrigen(String sucursalId);
  // GET  /api/pedidos/sucursal-destino/{sucursalId}
  Future<List<PedidoModel>> findBySucursalDestino(String sucursalId);
  // GET  /api/pedidos/listos-para-despachar/{sucursalOrigenId}
  Future<List<PedidoModel>> findListosParaDespachar(String sucursalOrigenId);
  // GET  /api/pedidos/disponibles/{sucursalDestinoId}
  Future<List<PedidoModel>> findDisponibles(String sucursalDestinoId);
  // GET  /api/pedidos/buscar?q=xxx
  Future<List<PedidoModel>> buscar(String q);
  // GET  /api/pedidos/dashboard/conteos
  Future<Map<String, int>> conteosPorEstado();
  // POST /api/pedidos
  Future<PedidoModel> create(Map<String, dynamic> data);
  // PUT  /api/pedidos/{id}
  Future<PedidoModel> update(String id, Map<String, dynamic> data);
  // PATCH /api/pedidos/{id}/estado
  // body: { "estado": "ENTREGADO", "observacion": "...", "sucursalId": "uuid" }
  Future<PedidoModel> cambiarEstado(String id, EstadoPedido estado,
      {String? observacion, String? sucursalId});
}