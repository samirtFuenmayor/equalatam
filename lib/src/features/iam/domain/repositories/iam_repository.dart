// lib/src/features/iam/domain/repositories/iam_repository.dart
import '../models/sucursal_model.dart';
import '../models/user_model.dart';

abstract class IamRepository {
  Future<List<UserModel>>     getUsers();
  Future<UserModel>           getUserById(String id);
  Future<UserModel>           createUser(Map<String, dynamic> data);
  Future<UserModel>           updateUser(String id, Map<String, dynamic> data);
  /// [nuevoEstado] = el estado destino (true=activo, false=inactivo)
  Future<void>                toggleUserStatus(String id, bool nuevoEstado);
  Future<void>                deleteUser(String id);
  Future<List<String>>        getRoles();
  Future<List<SucursalModel>> getSucursales();
}