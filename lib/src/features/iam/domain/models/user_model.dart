// lib/src/features/iam/domain/models/user_model.dart

class UserModel {
  final String  id;
  final String  username;
  final String  nombre;
  final String  apellido;
  final String  correo;
  final String  telefono;
  final String  nacionalidad;
  final String  provincia;
  final String  ciudad;
  final String  direccion;
  final String  fechaNacimiento; // formato: "1990-03-15"
  final String  rol;
  final bool    activo;
  final String? sucursalId;
  final String? sucursalNombre;

  const UserModel({
    required this.id,
    required this.username,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    required this.nacionalidad,
    required this.provincia,
    required this.ciudad,
    required this.direccion,
    required this.fechaNacimiento,
    required this.rol,
    required this.activo,
    this.sucursalId,
    this.sucursalNombre,
  });

  String get fullName => '$nombre $apellido'.trim();

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:              j['id']?.toString()              ?? '',
    username:        j['username']?.toString()        ?? '',
    nombre:          j['nombre']?.toString()          ?? '',
    apellido:        j['apellido']?.toString()        ?? '',
    // backend puede devolver "correo" o "email"
    correo:          j['correo']?.toString()
        ?? j['email']?.toString()           ?? '',
    telefono:        j['telefono']?.toString()        ?? '',
    nacionalidad:    j['nacionalidad']?.toString()    ?? '',
    provincia:       j['provincia']?.toString()       ?? '',
    ciudad:          j['ciudad']?.toString()          ?? '',
    direccion:       j['direccion']?.toString()       ?? '',
    fechaNacimiento: j['fechaNacimiento']?.toString() ?? '',
    rol:             _extractRol(j),
    // backend puede devolver "activo" o "enabled"
    activo:          j['activo'] as bool?
        ?? j['enabled'] as bool?            ?? true,
    sucursalId:      j['sucursalId']?.toString(),
    sucursalNombre:  j['sucursalNombre']?.toString(),
  );

  /// Compatible con los tres formatos que puede devolver Spring Security:
  ///   ["ROLE_ADMIN"]  |  [{"name": "ROLE_ADMIN"}]  |  "ADMIN"
  static String _extractRol(Map<String, dynamic> j) {
    final roles = j['roles'];
    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;
      final raw = first is String
          ? first
          : (first['name'] ?? first['roleName'] ?? '').toString();
      return raw.replaceAll('ROLE_', '');
    }
    return (j['rol'] ?? j['role'] ?? 'EMPLEADO')
        .toString()
        .replaceAll('ROLE_', '');
  }

  UserModel copyWith({
    String? id,         String? username,    String? nombre,
    String? apellido,   String? correo,      String? telefono,
    String? nacionalidad, String? provincia, String? ciudad,
    String? direccion,  String? fechaNacimiento, String? rol,
    bool?   activo,     String? sucursalId,  String? sucursalNombre,
  }) =>
      UserModel(
        id:              id              ?? this.id,
        username:        username        ?? this.username,
        nombre:          nombre          ?? this.nombre,
        apellido:        apellido        ?? this.apellido,
        correo:          correo          ?? this.correo,
        telefono:        telefono        ?? this.telefono,
        nacionalidad:    nacionalidad    ?? this.nacionalidad,
        provincia:       provincia       ?? this.provincia,
        ciudad:          ciudad          ?? this.ciudad,
        direccion:       direccion       ?? this.direccion,
        fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
        rol:             rol             ?? this.rol,
        activo:          activo          ?? this.activo,
        sucursalId:      sucursalId      ?? this.sucursalId,
        sucursalNombre:  sucursalNombre  ?? this.sucursalNombre,
      );
}