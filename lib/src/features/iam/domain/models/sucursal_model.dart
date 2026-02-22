// lib/src/features/iam/domain/models/sucursal_model.dart
// Mapea exactamente el SucursalResponse del backend Equalatam

class SucursalModel {
  final String  id;
  final String  nombre;
  final String  pais;
  final String? ciudad;
  final String? prefijoCasillero;
  final String? tipo;   // NACIONAL / INTERNACIONAL
  final bool    activa;

  const SucursalModel({
    required this.id,
    required this.nombre,
    required this.pais,
    this.ciudad,
    this.prefijoCasillero,
    this.tipo,
    this.activa = true,
  });

  /// Etiqueta legible para dropdown: "Miami (MIA) · EE.UU"
  String get label {
    final pre = prefijoCasillero != null ? ' ($prefijoCasillero)' : '';
    final loc = ciudad != null ? '$ciudad, $pais' : pais;
    return '$nombre$pre · $loc';
  }

  factory SucursalModel.fromJson(Map<String, dynamic> j) => SucursalModel(
    id:               j['id']?.toString()               ?? '',
    nombre:           j['nombre']?.toString()           ?? '',
    pais:             j['pais']?.toString()             ?? '',
    ciudad:           j['ciudad']?.toString(),
    prefijoCasillero: j['prefijoCasillero']?.toString(),
    tipo:             j['tipo']?.toString(),
    activa:           j['activa'] as bool?              ?? true,
  );
}