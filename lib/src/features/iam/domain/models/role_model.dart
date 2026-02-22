// lib/src/features/iam/domain/models/role_model.dart
// Mapea exactamente la entidad Role devuelta por el backend:
// { "id": "uuid", "name": "ADMIN", "permissions": [{"id":"uuid","name":"CREATE_USER"}] }

class RoleModel {
  final String              id;
  final String              name;
  final List<PermissionRef> permissions;

  const RoleModel({
    required this.id,
    required this.name,
    required this.permissions,
  });

  String get displayName => name.replaceAll('ROLE_', '');

  List<String> get permissionIds => permissions.map((p) => p.id).toList();

  factory RoleModel.fromJson(Map<String, dynamic> j) => RoleModel(
    id:          j['id']?.toString()   ?? '',
    name:        j['name']?.toString() ?? '',
    permissions: _extractPerms(j),
  );

  static List<PermissionRef> _extractPerms(Map<String, dynamic> j) {
    final raw = j['permissions'];
    if (raw == null || raw is! List) return [];
    return raw
        .map((e) => PermissionRef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  RoleModel copyWith({
    String? id, String? name, List<PermissionRef>? permissions,
  }) =>
      RoleModel(
        id:          id          ?? this.id,
        name:        name        ?? this.name,
        permissions: permissions ?? this.permissions,
      );
}

class PermissionRef {
  final String id;
  final String name;
  const PermissionRef({required this.id, required this.name});

  String get displayName {
    final p = name.split('_');
    return p.length >= 2
        ? '${_cap(p.first)} ${p.skip(1).join(' ').toLowerCase()}'
        : name;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  factory PermissionRef.fromJson(Map<String, dynamic> j) =>
      PermissionRef(id: j['id']?.toString() ?? '', name: j['name']?.toString() ?? '');
}