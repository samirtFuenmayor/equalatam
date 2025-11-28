import '../../domain/models/user_model.dart';
import '../models/role_model.dart';

class IamMockService {
  // Mock roles
  final List<RoleModel> _roles = [
    RoleModel(id: 'r_admin', name: 'Administrador', permissions: ['users.manage','roles.manage','reports.view','settings.manage']),
    RoleModel(id: 'r_operator', name: 'Operador', permissions: ['shipments.view','scan.create']),
    RoleModel(id: 'r_viewer', name: 'Viewer', permissions: ['reports.view']),
  ];

  // Mock users
  final List<UserModel> _users = List.generate(
    8,
        (i) => UserModel(
      id: 'u${i+1}',
      name: 'Usuario ${i+1}',
      email: 'user${i+1}@demo.com',
      roleId: i.isEven ? 'r_admin' : 'r_operator',
    ),
  );

  Future<List<RoleModel>> getRoles() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _roles;
  }

  Future<List<UserModel>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _users;
  }

  Future<RoleModel?> getRoleById(String id) async {
    return _roles.firstWhere((r) => r.id == id, orElse: () => _roles.first);
  }

  Future<void> createUser(UserModel user) async {
    _users.add(user);
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> updateUser(UserModel user) async {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx >= 0) _users[idx] = user;
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<List<String>> getAuditLogs() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      '2025-11-20 10:12 - admin creó usuario u7',
      '2025-11-21 08:55 - operador editó perfil u3',
    ];
  }
}
