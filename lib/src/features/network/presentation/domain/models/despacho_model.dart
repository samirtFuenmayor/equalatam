// lib/src/features/despachos/domain/models/despacho_model.dart

enum EstadoDespacho { ABIERTO, CERRADO, EN_TRANSITO, RECIBIDO, PROCESADO, CANCELADO }

extension EstadoDespachoX on EstadoDespacho {
  String get label => switch (this) {
    EstadoDespacho.ABIERTO     => 'Abierto',
    EstadoDespacho.CERRADO     => 'Cerrado',
    EstadoDespacho.EN_TRANSITO => 'En tránsito',
    EstadoDespacho.RECIBIDO    => 'Recibido',
    EstadoDespacho.PROCESADO   => 'Procesado',
    EstadoDespacho.CANCELADO   => 'Cancelado',
  };

  List<EstadoDespacho> get transicionesValidas => switch (this) {
    EstadoDespacho.ABIERTO     => [EstadoDespacho.CERRADO, EstadoDespacho.CANCELADO],
    EstadoDespacho.CERRADO     => [EstadoDespacho.EN_TRANSITO, EstadoDespacho.CANCELADO],
    EstadoDespacho.EN_TRANSITO => [EstadoDespacho.RECIBIDO],
    EstadoDespacho.RECIBIDO    => [EstadoDespacho.PROCESADO],
    _                          => [],
  };
}

class DespachoModel {
  final String         id;
  final String         numeroDespacho;
  final EstadoDespacho estado;
  final String         sucursalOrigenId;
  final String         sucursalOrigenNombre;
  final String         sucursalOrigenPais;
  final String         sucursalDestinoId;
  final String         sucursalDestinoNombre;
  final String         sucursalDestinoPais;
  final String?        aerolinea;
  final String?        numeroVuelo;
  final String?        guiaAerea;
  final String?        numeroContenedor;
  final String?        tipoTransporte;
  final DateTime?      fechaCreacion;
  final DateTime?      fechaSalidaProgramada;
  final DateTime?      fechaSalidaReal;
  final DateTime?      fechaLlegadaProgramada;
  final DateTime?      fechaLlegadaReal;
  final int            totalPedidos;
  final double         pesoTotal;
  final double         valorTotalDeclarado;
  final List<DetallePedidoModel> pedidos;
  final String?        creadoPor;
  final String?        observaciones;

  const DespachoModel({
    required this.id,
    required this.numeroDespacho,
    required this.estado,
    required this.sucursalOrigenId,
    required this.sucursalOrigenNombre,
    required this.sucursalOrigenPais,
    required this.sucursalDestinoId,
    required this.sucursalDestinoNombre,
    required this.sucursalDestinoPais,
    this.aerolinea,
    this.numeroVuelo,
    this.guiaAerea,
    this.numeroContenedor,
    this.tipoTransporte,
    this.fechaCreacion,
    this.fechaSalidaProgramada,
    this.fechaSalidaReal,
    this.fechaLlegadaProgramada,
    this.fechaLlegadaReal,
    this.totalPedidos = 0,
    this.pesoTotal = 0.0,
    this.valorTotalDeclarado = 0.0,
    this.pedidos = const [],
    this.creadoPor,
    this.observaciones,
  });

  String get ruta => '$sucursalOrigenNombre → $sucursalDestinoNombre';

  factory DespachoModel.fromJson(Map<String, dynamic> j) => DespachoModel(
    id:                     j['id']?.toString()                    ?? '',
    numeroDespacho:         j['numeroDespacho']?.toString()        ?? '',
    estado:                 _parseEstado(j['estado']?.toString()),
    sucursalOrigenId:       j['sucursalOrigenId']?.toString()      ?? '',
    sucursalOrigenNombre:   j['sucursalOrigenNombre']?.toString()  ?? '',
    sucursalOrigenPais:     j['sucursalOrigenPais']?.toString()    ?? '',
    sucursalDestinoId:      j['sucursalDestinoId']?.toString()     ?? '',
    sucursalDestinoNombre:  j['sucursalDestinoNombre']?.toString() ?? '',
    sucursalDestinoPais:    j['sucursalDestinoPais']?.toString()   ?? '',
    aerolinea:              j['aerolinea']?.toString(),
    numeroVuelo:            j['numeroVuelo']?.toString(),
    guiaAerea:              j['guiaAerea']?.toString(),
    numeroContenedor:       j['numeroContenedor']?.toString(),
    tipoTransporte:         j['tipoTransporte']?.toString(),
    fechaCreacion:          _dt(j['fechaCreacion']),
    fechaSalidaProgramada:  _dt(j['fechaSalidaProgramada']),
    fechaSalidaReal:        _dt(j['fechaSalidaReal']),
    fechaLlegadaProgramada: _dt(j['fechaLlegadaProgramada']),
    fechaLlegadaReal:       _dt(j['fechaLlegadaReal']),
    totalPedidos:           (j['totalPedidos'] ?? 0) as int,
    pesoTotal:              ((j['pesoTotal'] ?? 0) as num).toDouble(),
    valorTotalDeclarado:    ((j['valorTotalDeclarado'] ?? 0) as num).toDouble(),
    pedidos:                _parsePedidos(j['pedidos']),
    creadoPor:              j['creadoPor']?.toString(),
    observaciones:          j['observaciones']?.toString(),
  );

  static EstadoDespacho _parseEstado(String? s) => switch (s) {
    'CERRADO'     => EstadoDespacho.CERRADO,
    'EN_TRANSITO' => EstadoDespacho.EN_TRANSITO,
    'RECIBIDO'    => EstadoDespacho.RECIBIDO,
    'PROCESADO'   => EstadoDespacho.PROCESADO,
    'CANCELADO'   => EstadoDespacho.CANCELADO,
    _             => EstadoDespacho.ABIERTO,
  };

  static DateTime? _dt(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  static List<DetallePedidoModel> _parsePedidos(dynamic raw) {
    if (raw == null || raw is! List) return [];
    return raw.map((e) => DetallePedidoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  DespachoModel copyWith({
    EstadoDespacho? estado,
    List<DetallePedidoModel>? pedidos,
    int? totalPedidos,
    double? pesoTotal,
  }) =>
      DespachoModel(
        id: id, numeroDespacho: numeroDespacho,
        estado: estado ?? this.estado,
        sucursalOrigenId: sucursalOrigenId,
        sucursalOrigenNombre: sucursalOrigenNombre,
        sucursalOrigenPais: sucursalOrigenPais,
        sucursalDestinoId: sucursalDestinoId,
        sucursalDestinoNombre: sucursalDestinoNombre,
        sucursalDestinoPais: sucursalDestinoPais,
        aerolinea: aerolinea, numeroVuelo: numeroVuelo,
        guiaAerea: guiaAerea, numeroContenedor: numeroContenedor,
        tipoTransporte: tipoTransporte,
        fechaCreacion: fechaCreacion,
        fechaSalidaProgramada: fechaSalidaProgramada,
        fechaSalidaReal: fechaSalidaReal,
        fechaLlegadaProgramada: fechaLlegadaProgramada,
        fechaLlegadaReal: fechaLlegadaReal,
        totalPedidos: totalPedidos ?? this.totalPedidos,
        pesoTotal: pesoTotal ?? this.pesoTotal,
        valorTotalDeclarado: valorTotalDeclarado,
        pedidos: pedidos ?? this.pedidos,
        creadoPor: creadoPor, observaciones: observaciones,
      );
}

class DetallePedidoModel {
  final String    detalleId;
  final String    pedidoId;
  final String    numeroPedido;
  final String    clienteNombre;
  final String    clienteCasillero;
  final String?   trackingExterno;
  final String?   descripcion;
  final double?   peso;
  final double?   valorDeclarado;
  final String?   sucursalDestinoPedido;
  final String    estadoPedido;
  final DateTime? agregadoEn;

  const DetallePedidoModel({
    required this.detalleId,
    required this.pedidoId,
    required this.numeroPedido,
    required this.clienteNombre,
    required this.clienteCasillero,
    required this.estadoPedido,
    this.trackingExterno,
    this.descripcion,
    this.peso,
    this.valorDeclarado,
    this.sucursalDestinoPedido,
    this.agregadoEn,
  });

  factory DetallePedidoModel.fromJson(Map<String, dynamic> j) =>
      DetallePedidoModel(
        detalleId:             j['detalleId']?.toString()        ?? '',
        pedidoId:              j['pedidoId']?.toString()         ?? '',
        numeroPedido:          j['numeroPedido']?.toString()     ?? '',
        clienteNombre:         j['clienteNombre']?.toString()    ?? '',
        clienteCasillero:      j['clienteCasillero']?.toString() ?? '',
        estadoPedido:          j['estadoPedido']?.toString()     ?? '',
        trackingExterno:       j['trackingExterno']?.toString(),
        descripcion:           j['descripcion']?.toString(),
        peso:           j['peso'] != null ? (j['peso'] as num).toDouble() : null,
        valorDeclarado: j['valorDeclarado'] != null
            ? (j['valorDeclarado'] as num).toDouble() : null,
        sucursalDestinoPedido: j['sucursalDestinoPedido']?.toString(),
        agregadoEn: j['agregadoEn'] != null
            ? DateTime.tryParse(j['agregadoEn'].toString()) : null,
      );
}