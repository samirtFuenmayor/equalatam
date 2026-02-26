// lib/src/features/guias/domain/models/guia_model.dart

enum EstadoGuia {
  GENERADA,
  ASIGNADA,
  EN_TRANSITO,
  ENTREGADA,
  ANULADA;

  String get label => switch (this) {
    EstadoGuia.GENERADA    => 'Generada',
    EstadoGuia.ASIGNADA    => 'Asignada',
    EstadoGuia.EN_TRANSITO => 'En tránsito',
    EstadoGuia.ENTREGADA   => 'Entregada',
    EstadoGuia.ANULADA     => 'Anulada',
  };

  List<EstadoGuia> get transicionesValidas => switch (this) {
    EstadoGuia.GENERADA    => [EstadoGuia.ASIGNADA, EstadoGuia.ANULADA],
    EstadoGuia.ASIGNADA    => [EstadoGuia.EN_TRANSITO, EstadoGuia.ANULADA],
    EstadoGuia.EN_TRANSITO => [EstadoGuia.ENTREGADA],
    EstadoGuia.ENTREGADA   => [],
    EstadoGuia.ANULADA     => [],
  };

  bool get esFinal => this == EstadoGuia.ENTREGADA || this == EstadoGuia.ANULADA;
}

class GuiaModel {
  final String     id;
  final String     numeroGuia;
  final EstadoGuia estado;

  // Pedido
  final String  pedidoId;
  final String  numeroPedido;
  final String? trackingExterno;

  // Remitente
  final String  remitenteNombre;
  final String? remitenteDireccion;
  final String? remitenteTelefono;
  final String? remitenteEmail;
  final String? remitentePais;

  // Destinatario
  final String  destinatarioId;
  final String  destinatarioNombre;
  final String  destinatarioCasillero;
  final String? destinatarioTelefono;

  // Ruta
  final String? sucursalOrigenNombre;
  final String? sucursalOrigenPais;
  final String? sucursalDestinoNombre;
  final String? sucursalDestinoCiudad;

  // Contenido
  final String   descripcionContenido;
  final double?  pesoDeclarado;
  final double?  pesoVolumetrico;
  final double?  pesoCobrable;
  final double?  valorDeclarado;
  final int?     cantidadPiezas;
  final double?  largo;
  final double?  ancho;
  final double?  alto;

  // Transporte
  final String? numeroDespacho;
  final String? aerolinea;
  final String? numeroVuelo;
  final String? guiaAerea;

  // Costos
  final double? tarifaPorLibra;
  final double? costoFlete;
  final double? costoManejo;
  final double? costoSeguro;
  final double? costoTotal;

  // Auditoría
  final String?   generadaPor;
  final DateTime  fechaGeneracion;
  final DateTime? fechaEntrega;
  final String?   observaciones;

  const GuiaModel({
    required this.id,
    required this.numeroGuia,
    required this.estado,
    required this.pedidoId,
    required this.numeroPedido,
    this.trackingExterno,
    required this.remitenteNombre,
    this.remitenteDireccion,
    this.remitenteTelefono,
    this.remitenteEmail,
    this.remitentePais,
    required this.destinatarioId,
    required this.destinatarioNombre,
    required this.destinatarioCasillero,
    this.destinatarioTelefono,
    this.sucursalOrigenNombre,
    this.sucursalOrigenPais,
    this.sucursalDestinoNombre,
    this.sucursalDestinoCiudad,
    required this.descripcionContenido,
    this.pesoDeclarado,
    this.pesoVolumetrico,
    this.pesoCobrable,
    this.valorDeclarado,
    this.cantidadPiezas,
    this.largo,
    this.ancho,
    this.alto,
    this.numeroDespacho,
    this.aerolinea,
    this.numeroVuelo,
    this.guiaAerea,
    this.tarifaPorLibra,
    this.costoFlete,
    this.costoManejo,
    this.costoSeguro,
    this.costoTotal,
    this.generadaPor,
    required this.fechaGeneracion,
    this.fechaEntrega,
    this.observaciones,
  });

  factory GuiaModel.fromJson(Map<String, dynamic> j) => GuiaModel(
    id:                    j['id'].toString(),
    numeroGuia:            j['numeroGuia'].toString(),
    estado:                EstadoGuia.values.byName(j['estado'].toString()),
    pedidoId:              j['pedidoId'].toString(),
    numeroPedido:          j['numeroPedido'].toString(),
    trackingExterno:       j['trackingExterno']?.toString(),
    remitenteNombre:       j['remitenteNombre']?.toString() ?? '',
    remitenteDireccion:    j['remitenteDireccion']?.toString(),
    remitenteTelefono:     j['remitenteTelefono']?.toString(),
    remitenteEmail:        j['remitenteEmail']?.toString(),
    remitentePais:         j['remitentePais']?.toString(),
    destinatarioId:        j['destinatarioId'].toString(),
    destinatarioNombre:    j['destinatarioNombre']?.toString() ?? '',
    destinatarioCasillero: j['destinatarioCasillero']?.toString() ?? '',
    destinatarioTelefono:  j['destinatarioTelefono']?.toString(),
    sucursalOrigenNombre:  j['sucursalOrigenNombre']?.toString(),
    sucursalOrigenPais:    j['sucursalOrigenPais']?.toString(),
    sucursalDestinoNombre: j['sucursalDestinoNombre']?.toString(),
    sucursalDestinoCiudad: j['sucursalDestinoCiudad']?.toString(),
    descripcionContenido:  j['descripcionContenido']?.toString() ?? '',
    pesoDeclarado:         (j['pesoDeclarado']  as num?)?.toDouble(),
    pesoVolumetrico:       (j['pesoVolumetrico'] as num?)?.toDouble(),
    pesoCobrable:          (j['pesoCobrable']    as num?)?.toDouble(),
    valorDeclarado:        (j['valorDeclarado']  as num?)?.toDouble(),
    cantidadPiezas:        j['cantidadPiezas']   as int?,
    largo:                 (j['largo']  as num?)?.toDouble(),
    ancho:                 (j['ancho']  as num?)?.toDouble(),
    alto:                  (j['alto']   as num?)?.toDouble(),
    numeroDespacho:        j['numeroDespacho']?.toString(),
    aerolinea:             j['aerolinea']?.toString(),
    numeroVuelo:           j['numeroVuelo']?.toString(),
    guiaAerea:             j['guiaAerea']?.toString(),
    tarifaPorLibra:        (j['tarifaPorLibra'] as num?)?.toDouble(),
    costoFlete:            (j['costoFlete']     as num?)?.toDouble(),
    costoManejo:           (j['costoManejo']    as num?)?.toDouble(),
    costoSeguro:           (j['costoSeguro']    as num?)?.toDouble(),
    costoTotal:            (j['costoTotal']     as num?)?.toDouble(),
    generadaPor:           j['generadaPor']?.toString(),
    fechaGeneracion:       DateTime.parse(j['fechaGeneracion'].toString()),
    fechaEntrega:          j['fechaEntrega'] != null ? DateTime.parse(j['fechaEntrega'].toString()) : null,
    observaciones:         j['observaciones']?.toString(),
  );
}