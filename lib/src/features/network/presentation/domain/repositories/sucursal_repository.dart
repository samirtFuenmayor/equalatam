// lib/src/features/network/domain/repositories/sucursal_repository.dart
import '../models/sucursal_model.dart';

abstract class SucursalRepository {
  // GET  /api/sucursales              → solo activas
  Future<List<SucursalModel>> findAllActivas();

  // GET  /api/sucursales/todas        → todas incluyendo inactivas
  Future<List<SucursalModel>> findAll();

  // GET  /api/sucursales/{id}
  Future<SucursalModel> findById(String id);

  // GET  /api/sucursales/tipo/{tipo}  → MATRIZ | NACIONAL | INTERNACIONAL
  Future<List<SucursalModel>> findByTipo(TipoSucursal tipo);

  // GET  /api/sucursales/internacionales
  Future<List<SucursalModel>> findInternacionales();

  // GET  /api/sucursales/nacionales
  Future<List<SucursalModel>> findNacionales();

  // POST /api/sucursales
  Future<SucursalModel> create(Map<String, dynamic> data);

  // PUT  /api/sucursales/{id}
  Future<SucursalModel> update(String id, Map<String, dynamic> data);

  // DELETE /api/sucursales/{id}       → soft delete (activa = false)
  Future<void> desactivar(String id);

  // PATCH  /api/sucursales/{id}/reactivar
  Future<SucursalModel> reactivar(String id);
}