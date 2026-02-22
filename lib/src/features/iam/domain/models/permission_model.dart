// lib/src/features/iam/domain/models/permission_model.dart
// Mapea exactamente la entidad Permission devuelta por el backend:
// { "id": "uuid", "name": "CREATE_USER" }

class PermissionModel {
  final String id;
  final String name;

  const PermissionModel({required this.id, required this.name});

  // "CREATE_USER" → "Crear user"
  String get displayName {
    final parts = name.split('_');
    return parts.length >= 2
        ? '${_cap(parts.first)} ${parts.skip(1).join(' ').toLowerCase()}'
        : name;
  }

  // Módulo inferido del sufijo: "CREATE_USER" → "USER", "DELETE_ROLE" → "ROLE"
  String get modulo {
    final parts = name.split('_');
    return parts.length >= 2 ? parts.last : 'GENERAL';
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  factory PermissionModel.fromJson(Map<String, dynamic> j) => PermissionModel(
    id:   j['id']?.toString()   ?? '',
    name: j['name']?.toString() ?? '',
  );
}