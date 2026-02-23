// lib/src/features/network/domain/models/sucursal_model.dart
// Mapea exactamente SucursalResponse del backend:
// { id, nombre, codigo, tipo, pais, ciudad, direccion,
//   telefono, email, responsable, prefijoCasillero, activa, creadoEn }

enum TipoSucursal { MATRIZ, NACIONAL, INTERNACIONAL }

extension TipoSucursalX on TipoSucursal {
  String get label => switch (this) {
    TipoSucursal.MATRIZ         => 'Matriz',
    TipoSucursal.NACIONAL       => 'Nacional',
    TipoSucursal.INTERNACIONAL  => 'Internacional',
  };
}

class SucursalModel {
  final String        id;
  final String        nombre;
  final String        codigo;
  final TipoSucursal  tipo;
  final String        pais;
  final String        ciudad;
  final String        direccion;
  final String?       telefono;
  final String?       email;
  final String?       responsable;
  final String        prefijoCasillero;
  final bool          activa;
  final DateTime?     creadoEn;

  const SucursalModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.tipo,
    required this.pais,
    required this.ciudad,
    required this.direccion,
    required this.prefijoCasillero,
    required this.activa,
    this.telefono,
    this.email,
    this.responsable,
    this.creadoEn,
  });

  factory SucursalModel.fromJson(Map<String, dynamic> j) => SucursalModel(
    id:               j['id']?.toString()               ?? '',
    nombre:           j['nombre']?.toString()           ?? '',
    codigo:           j['codigo']?.toString()           ?? '',
    tipo:             _parseTipo(j['tipo']?.toString()),
    pais:             j['pais']?.toString()             ?? '',
    ciudad:           j['ciudad']?.toString()           ?? '',
    direccion:        j['direccion']?.toString()        ?? '',
    prefijoCasillero: j['prefijoCasillero']?.toString() ?? '',
    activa:           j['activa'] as bool?              ?? true,
    telefono:         j['telefono']?.toString(),
    email:            j['email']?.toString(),
    responsable:      j['responsable']?.toString(),
    creadoEn:         j['creadoEn'] != null
        ? DateTime.tryParse(j['creadoEn'].toString())
        : null,
  );

  static TipoSucursal _parseTipo(String? s) => switch (s) {
    'MATRIZ'        => TipoSucursal.MATRIZ,
    'INTERNACIONAL' => TipoSucursal.INTERNACIONAL,
    _               => TipoSucursal.NACIONAL,
  };

  SucursalModel copyWith({
    String? id, String? nombre, String? codigo, TipoSucursal? tipo,
    String? pais, String? ciudad, String? direccion, String? telefono,
    String? email, String? responsable, String? prefijoCasillero,
    bool? activa, DateTime? creadoEn,
  }) =>
      SucursalModel(
        id:               id               ?? this.id,
        nombre:           nombre           ?? this.nombre,
        codigo:           codigo           ?? this.codigo,
        tipo:             tipo             ?? this.tipo,
        pais:             pais             ?? this.pais,
        ciudad:           ciudad           ?? this.ciudad,
        direccion:        direccion        ?? this.direccion,
        prefijoCasillero: prefijoCasillero ?? this.prefijoCasillero,
        activa:           activa           ?? this.activa,
        telefono:         telefono         ?? this.telefono,
        email:            email            ?? this.email,
        responsable:      responsable      ?? this.responsable,
        creadoEn:         creadoEn         ?? this.creadoEn,
      );

  /// Ubica dónde se mide: ciudad + país
  String get ubicacion => '$ciudad, $pais';
}