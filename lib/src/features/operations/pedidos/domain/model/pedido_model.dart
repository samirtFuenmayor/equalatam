// lib/src/features/pedidos/domain/models/pedido_model.dart

enum EstadoPedido {
  REGISTRADO,
  RECIBIDO_EN_SEDE,
  EN_CONSOLIDACION,
  EN_TRANSITO,
  EN_ADUANA,
  RETENIDO_ADUANA,
  LIBERADO_ADUANA,
  RECIBIDO_EN_MATRIZ,
  EN_DISTRIBUCION,
  DISPONIBLE_EN_SUCURSAL,
  ENTREGADO,
  DEVUELTO,
  EXTRAVIADO,
}

extension EstadoPedidoX on EstadoPedido {
  String get label => switch (this) {
    EstadoPedido.REGISTRADO             => 'Registrado',
    EstadoPedido.RECIBIDO_EN_SEDE       => 'Recibido en sede',
    EstadoPedido.EN_CONSOLIDACION       => 'En consolidación',
    EstadoPedido.EN_TRANSITO            => 'En tránsito',
    EstadoPedido.EN_ADUANA              => 'En aduana',
    EstadoPedido.RETENIDO_ADUANA        => 'Retenido en aduana',
    EstadoPedido.LIBERADO_ADUANA        => 'Liberado de aduana',
    EstadoPedido.RECIBIDO_EN_MATRIZ     => 'Recibido en matriz',
    EstadoPedido.EN_DISTRIBUCION        => 'En distribución',
    EstadoPedido.DISPONIBLE_EN_SUCURSAL => 'Disponible en sucursal',
    EstadoPedido.ENTREGADO              => 'Entregado',
    EstadoPedido.DEVUELTO               => 'Devuelto',
    EstadoPedido.EXTRAVIADO             => 'Extraviado',
  };

  // Siguientes estados posibles (para cambio de estado)
  List<EstadoPedido> get siguientes => switch (this) {
    EstadoPedido.REGISTRADO             => [EstadoPedido.RECIBIDO_EN_SEDE],
    EstadoPedido.RECIBIDO_EN_SEDE       => [EstadoPedido.EN_CONSOLIDACION, EstadoPedido.EN_TRANSITO],
    EstadoPedido.EN_CONSOLIDACION       => [EstadoPedido.EN_TRANSITO],
    EstadoPedido.EN_TRANSITO            => [EstadoPedido.EN_ADUANA, EstadoPedido.RECIBIDO_EN_MATRIZ],
    EstadoPedido.EN_ADUANA              => [EstadoPedido.RETENIDO_ADUANA, EstadoPedido.LIBERADO_ADUANA],
    EstadoPedido.RETENIDO_ADUANA        => [EstadoPedido.LIBERADO_ADUANA, EstadoPedido.DEVUELTO],
    EstadoPedido.LIBERADO_ADUANA        => [EstadoPedido.RECIBIDO_EN_MATRIZ],
    EstadoPedido.RECIBIDO_EN_MATRIZ     => [EstadoPedido.EN_DISTRIBUCION, EstadoPedido.DISPONIBLE_EN_SUCURSAL],
    EstadoPedido.EN_DISTRIBUCION        => [EstadoPedido.DISPONIBLE_EN_SUCURSAL],
    EstadoPedido.DISPONIBLE_EN_SUCURSAL => [EstadoPedido.ENTREGADO],
    _                                   => [],
  };

  bool get esFinal =>
      this == EstadoPedido.ENTREGADO ||
          this == EstadoPedido.DEVUELTO  ||
          this == EstadoPedido.EXTRAVIADO;
}

enum TipoPedido { IMPORTACION, EXPORTACION }

extension TipoPedidoX on TipoPedido {
  String get label => this == TipoPedido.IMPORTACION
      ? 'Importación' : 'Exportación';
}

// ─── Modelo principal ─────────────────────────────────────────────────────────
class PedidoModel {
  final String       id;
  final String       numeroPedido;
  final TipoPedido   tipo;
  final EstadoPedido estado;

  // Cliente
  final String  clienteId;
  final String  clienteNombres;
  final String  clienteApellidos;
  final String  clienteCasillero;
  final String? clienteIdentificacion;

  // Tracking externo
  final String? trackingExterno;
  final String? proveedor;
  final String? urlTracking;

  // Contenido
  final String   descripcion;
  final double?  peso;
  final double?  largo;
  final double?  ancho;
  final double?  alto;
  final double?  valorDeclarado;
  final int?     cantidadItems;

  // Sucursales
  final String? sucursalOrigenId;
  final String? sucursalOrigenNombre;
  final String? sucursalOrigenPais;
  final String? sucursalDestinoId;
  final String? sucursalDestinoNombre;
  final String? sucursalDestinoCiudad;

  // Empleado
  final String? registradoPor;

  // Fechas
  final DateTime? fechaRegistro;
  final DateTime? fechaRecepcionSede;
  final DateTime? fechaSalidaExterior;
  final DateTime? fechaLlegadaEcuador;
  final DateTime? fechaDisponible;
  final DateTime? fechaEntrega;

  final String? observaciones;
  final String? notasInternas;
  final String? fotoUrl;

  const PedidoModel({
    required this.id,
    required this.numeroPedido,
    required this.tipo,
    required this.estado,
    required this.clienteId,
    required this.clienteNombres,
    required this.clienteApellidos,
    required this.clienteCasillero,
    required this.descripcion,
    this.clienteIdentificacion,
    this.trackingExterno,
    this.proveedor,
    this.urlTracking,
    this.peso,
    this.largo,
    this.ancho,
    this.alto,
    this.valorDeclarado,
    this.cantidadItems,
    this.sucursalOrigenId,
    this.sucursalOrigenNombre,
    this.sucursalOrigenPais,
    this.sucursalDestinoId,
    this.sucursalDestinoNombre,
    this.sucursalDestinoCiudad,
    this.registradoPor,
    this.fechaRegistro,
    this.fechaRecepcionSede,
    this.fechaSalidaExterior,
    this.fechaLlegadaEcuador,
    this.fechaDisponible,
    this.fechaEntrega,
    this.observaciones,
    this.notasInternas,
    this.fotoUrl,
  });

  String get clienteNombreCompleto => '$clienteNombres $clienteApellidos';

  factory PedidoModel.fromJson(Map<String, dynamic> j) => PedidoModel(
    id:                   j['id']?.toString()                   ?? '',
    numeroPedido:         j['numeroPedido']?.toString()         ?? '',
    tipo:                 _parseTipo(j['tipo']?.toString()),
    estado:               _parseEstado(j['estado']?.toString()),
    clienteId:            j['clienteId']?.toString()            ?? '',
    clienteNombres:       j['clienteNombres']?.toString()       ?? '',
    clienteApellidos:     j['clienteApellidos']?.toString()     ?? '',
    clienteCasillero:     j['clienteCasillero']?.toString()     ?? '',
    clienteIdentificacion:j['clienteIdentificacion']?.toString(),
    trackingExterno:      j['trackingExterno']?.toString(),
    proveedor:            j['proveedor']?.toString(),
    urlTracking:          j['urlTracking']?.toString(),
    descripcion:          j['descripcion']?.toString()          ?? '',
    peso:          j['peso']           != null ? (j['peso'] as num).toDouble()           : null,
    largo:         j['largo']          != null ? (j['largo'] as num).toDouble()          : null,
    ancho:         j['ancho']          != null ? (j['ancho'] as num).toDouble()          : null,
    alto:          j['alto']           != null ? (j['alto'] as num).toDouble()           : null,
    valorDeclarado:j['valorDeclarado'] != null ? (j['valorDeclarado'] as num).toDouble() : null,
    cantidadItems: j['cantidadItems']  as int?,
    sucursalOrigenId:      j['sucursalOrigenId']?.toString(),
    sucursalOrigenNombre:  j['sucursalOrigenNombre']?.toString(),
    sucursalOrigenPais:    j['sucursalOrigenPais']?.toString(),
    sucursalDestinoId:     j['sucursalDestinoId']?.toString(),
    sucursalDestinoNombre: j['sucursalDestinoNombre']?.toString(),
    sucursalDestinoCiudad: j['sucursalDestinoCiudad']?.toString(),
    registradoPor:         j['registradoPor']?.toString(),
    fechaRegistro:         _dt(j['fechaRegistro']),
    fechaRecepcionSede:    _dt(j['fechaRecepcionSede']),
    fechaSalidaExterior:   _dt(j['fechaSalidaExterior']),
    fechaLlegadaEcuador:   _dt(j['fechaLlegadaEcuador']),
    fechaDisponible:       _dt(j['fechaDisponible']),
    fechaEntrega:          _dt(j['fechaEntrega']),
    observaciones:         j['observaciones']?.toString(),
    notasInternas:         j['notasInternas']?.toString(),
    fotoUrl:               j['fotoUrl']?.toString(),
  );

  static EstadoPedido _parseEstado(String? s) => EstadoPedido.values
      .firstWhere((e) => e.name == s, orElse: () => EstadoPedido.REGISTRADO);

  static TipoPedido _parseTipo(String? s) =>
      s == 'EXPORTACION' ? TipoPedido.EXPORTACION : TipoPedido.IMPORTACION;

  static DateTime? _dt(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  PedidoModel copyWith({EstadoPedido? estado}) => PedidoModel(
    id: id, numeroPedido: numeroPedido,
    tipo: tipo, estado: estado ?? this.estado,
    clienteId: clienteId, clienteNombres: clienteNombres,
    clienteApellidos: clienteApellidos, clienteCasillero: clienteCasillero,
    clienteIdentificacion: clienteIdentificacion,
    trackingExterno: trackingExterno, proveedor: proveedor,
    urlTracking: urlTracking, descripcion: descripcion,
    peso: peso, largo: largo, ancho: ancho, alto: alto,
    valorDeclarado: valorDeclarado, cantidadItems: cantidadItems,
    sucursalOrigenId: sucursalOrigenId, sucursalOrigenNombre: sucursalOrigenNombre,
    sucursalOrigenPais: sucursalOrigenPais, sucursalDestinoId: sucursalDestinoId,
    sucursalDestinoNombre: sucursalDestinoNombre, sucursalDestinoCiudad: sucursalDestinoCiudad,
    registradoPor: registradoPor, fechaRegistro: fechaRegistro,
    fechaRecepcionSede: fechaRecepcionSede, fechaSalidaExterior: fechaSalidaExterior,
    fechaLlegadaEcuador: fechaLlegadaEcuador, fechaDisponible: fechaDisponible,
    fechaEntrega: fechaEntrega, observaciones: observaciones,
    notasInternas: notasInternas, fotoUrl: fotoUrl,
  );
}