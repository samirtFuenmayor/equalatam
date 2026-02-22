// lib/src/features/iam/domain/models/user_model.dart

class UserModel {
  final String id;
  final String username;
  final String nombre;
  final String apellido;
  final String correo;
  final String rol;
  final bool activo;
  final String? sucursalId;
  final String? sucursalNombre;

  const UserModel({
    required this.id,
    required this.username,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.rol,
    required this.activo,
    this.sucursalId,
    this.sucursalNombre,
  });

  String get fullName => '$nombre $apellido';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:             j['id']?.toString()       ?? '',
    username:       j['username']?.toString() ?? '',
    nombre:         j['nombre']?.toString()   ?? j['nombres']?.toString() ?? '',
    apellido:       j['apellido']?.toString() ?? j['apellidos']?.toString() ?? '',
    correo:          j['correo']?.toString()    ?? '',
    rol:            _extractRol(j),
    activo:         j['activo'] as bool?      ?? j['enabled'] as bool? ?? true,
    sucursalId:     j['sucursalId']?.toString(),
    sucursalNombre: j['sucursalNombre']?.toString(),
  );

  /// El backend puede devolver el rol de distintas formas
  static String _extractRol(Map<String, dynamic> j) {
    // roles: ["ROLE_ADMIN"] o roles: [{"name":"ROLE_ADMIN"}]
    final roles = j['roles'];
    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;
      final raw = first is String ? first : (first['name'] ?? first['roleName'] ?? '');
      return raw.toString().replaceAll('ROLE_', '');
    }
    // rol: "ADMIN"
    return (j['rol'] ?? j['role'] ?? 'EMPLEADO').toString().replaceAll('ROLE_', '');
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'nombre':   nombre,
    'apellido': apellido,
    'correo':    correo,
    'rol':      rol,
    'activo':   activo,
  };

  UserModel copyWith({
    String? id, String? username, String? nombre, String? apellido,
    String? correo, String? rol, bool? activo,
    String? sucursalId, String? sucursalNombre,
  }) =>
      UserModel(
        id:             id             ?? this.id,
        username:       username       ?? this.username,
        nombre:         nombre         ?? this.nombre,
        apellido:       apellido       ?? this.apellido,
        correo:          correo          ?? this.correo,
        rol:            rol            ?? this.rol,
        activo:         activo         ?? this.activo,
        sucursalId:     sucursalId     ?? this.sucursalId,
        sucursalNombre: sucursalNombre ?? this.sucursalNombre,
      );
}