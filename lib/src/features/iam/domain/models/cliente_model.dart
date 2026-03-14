// lib/src/features/clientes/domain/models/cliente_model.dart

// ─── Enums ────────────────────────────────────────────────────────────────────
enum TipoIdentificacion {
  CEDULA,
  RUC,
  PASAPORTE;

  String get label => switch (this) {
    TipoIdentificacion.CEDULA    => 'Cédula',
    TipoIdentificacion.RUC       => 'RUC',
    TipoIdentificacion.PASAPORTE => 'Pasaporte',
  };

  static TipoIdentificacion fromString(String s) =>
      TipoIdentificacion.values.firstWhere(
            (e) => e.name == s,
        orElse: () => TipoIdentificacion.CEDULA,
      );
}

enum EstadoCliente {
  ACTIVO,
  SUSPENDIDO,
  INACTIVO;

  String get label => switch (this) {
    EstadoCliente.ACTIVO     => 'Activo',
    EstadoCliente.SUSPENDIDO => 'Suspendido',
    EstadoCliente.INACTIVO   => 'Inactivo',
  };

  static EstadoCliente fromString(String s) =>
      EstadoCliente.values.firstWhere(
            (e) => e.name == s,
        orElse: () => EstadoCliente.ACTIVO,
      );
}

// ─── ClienteModel ─────────────────────────────────────────────────────────────
class ClienteModel {
  final String             id;
  final TipoIdentificacion tipoIdentificacion;
  final String             numeroIdentificacion;
  final String             nombres;
  final String             apellidos;
  final String             email;
  final String?            telefono;
  final String?            fechaNacimiento;
  final String             pais;
  final String?            provincia;
  final String?            ciudad;
  final String?            direccion;
  final String?            casillero;
  final String?            sucursalId;
  final String?            sucursalNombre;
  final String?            sucursalPais;
  final EstadoCliente      estado;
  final String?            observaciones;
  final String?            creadoEn;

  const ClienteModel({
    required this.id,
    required this.tipoIdentificacion,
    required this.numeroIdentificacion,
    required this.nombres,
    required this.apellidos,
    required this.email,
    this.telefono,
    this.fechaNacimiento,
    required this.pais,
    this.provincia,
    this.ciudad,
    this.direccion,
    this.casillero,
    this.sucursalId,
    this.sucursalNombre,
    this.sucursalPais,
    required this.estado,
    this.observaciones,
    this.creadoEn,
  });

  String get nombreCompleto => '$nombres $apellidos';

  String get iniciales {
    final parts = nombreCompleto.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  factory ClienteModel.fromJson(Map<String, dynamic> j) => ClienteModel(
    id:                   j['id']?.toString()                   ?? '',
    tipoIdentificacion:   TipoIdentificacion.fromString(
        j['tipoIdentificacion']?.toString() ?? ''),
    numeroIdentificacion: j['numeroIdentificacion']?.toString() ?? '',
    nombres:              j['nombres']?.toString()              ?? '',
    apellidos:            j['apellidos']?.toString()            ?? '',
    email:                j['email']?.toString()                ?? '',
    telefono:             j['telefono']?.toString(),
    fechaNacimiento:      j['fechaNacimiento']?.toString(),
    pais:                 j['pais']?.toString()                 ?? '',
    provincia:            j['provincia']?.toString(),
    ciudad:               j['ciudad']?.toString(),
    direccion:            j['direccion']?.toString(),
    casillero:            j['casillero']?.toString(),
    sucursalId:           j['sucursalId']?.toString(),
    sucursalNombre:       j['sucursalNombre']?.toString(),
    sucursalPais:         j['sucursalPais']?.toString(),
    estado:               EstadoCliente.fromString(
        j['estado']?.toString() ?? ''),
    observaciones:        j['observaciones']?.toString(),
    creadoEn:             j['creadoEn']?.toString(),
  );
}

// ─── AfiliadoModel ────────────────────────────────────────────────────────────
// Respuesta de GET /api/clientes/{titularId}/afiliados
class AfiliadoModel {
  final String        id;
  final String        nombres;
  final String        apellidos;
  final String        numeroIdentificacion;
  final String        email;
  final String?       telefono;
  final String?       casillero;
  final String?       parentesco;
  final EstadoCliente estado;

  const AfiliadoModel({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.numeroIdentificacion,
    required this.email,
    this.telefono,
    this.casillero,
    this.parentesco,
    required this.estado,
  });

  String get nombreCompleto => '$nombres $apellidos';

  String get iniciales {
    final parts = nombreCompleto.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  factory AfiliadoModel.fromJson(Map<String, dynamic> j) => AfiliadoModel(
    id:                   j['id']?.toString()                   ?? '',
    nombres:              j['nombres']?.toString()              ?? '',
    apellidos:            j['apellidos']?.toString()            ?? '',
    numeroIdentificacion: j['numeroIdentificacion']?.toString() ?? '',
    email:                j['email']?.toString()                ?? '',
    telefono:             j['telefono']?.toString(),
    casillero:            j['casillero']?.toString(),
    parentesco:           j['parentesco']?.toString(),
    estado:               EstadoCliente.fromString(
        j['estado']?.toString() ?? ''),
  );
}