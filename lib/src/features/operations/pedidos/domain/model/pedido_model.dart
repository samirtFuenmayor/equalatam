// lib/src/features/pedidos/domain/models/pedido_model.dart

import 'DatosFacturacionModel.dart';

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
  RECEPCION_PARCIAL,
  ESPERANDO_ITEMS,
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
    EstadoPedido.RECEPCION_PARCIAL      => 'Recepción parcial',
    EstadoPedido.ESPERANDO_ITEMS        => 'Esperando items',
  };

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
    EstadoPedido.RECEPCION_PARCIAL      => [],
    EstadoPedido.ESPERANDO_ITEMS        => [EstadoPedido.RECIBIDO_EN_SEDE],
    _                                   => [],
  };

  bool get esFinal =>
      this == EstadoPedido.ENTREGADO ||
          this == EstadoPedido.DEVUELTO  ||
          this == EstadoPedido.EXTRAVIADO;
}

enum TipoPedido { IMPORTACION, EXPORTACION }

enum FormaPago { EFECTIVO, TRANSFERENCIA }

extension FormaPagoX on FormaPago {
  String get label => switch (this) {
    FormaPago.EFECTIVO      => 'Efectivo',
    FormaPago.TRANSFERENCIA => 'Transferencia',
  };
}

enum EstadoPago {
  PENDIENTE_COMPROBANTE,
  COMPROBANTE_ENVIADO,
  PAGO_VERIFICADO,
  PAGO_RECHAZADO,
}

extension TipoPedidoX on TipoPedido {
  String get label =>
      this == TipoPedido.IMPORTACION ? 'Importación' : 'Exportación';
}

extension EstadoPagoX on EstadoPago {
  String get label => switch (this) {
    EstadoPago.PENDIENTE_COMPROBANTE => 'Pendiente comprobante',
    EstadoPago.COMPROBANTE_ENVIADO   => 'Comprobante enviado',
    EstadoPago.PAGO_VERIFICADO       => 'Pago verificado',
    EstadoPago.PAGO_RECHAZADO        => 'Pago rechazado',
  };

  bool get estaVerificado => this == EstadoPago.PAGO_VERIFICADO;
  bool get estaRechazado  => this == EstadoPago.PAGO_RECHAZADO;
  bool get pendienteComprobante => this == EstadoPago.PENDIENTE_COMPROBANTE;
}

enum TipoProducto {
  ELECTRONICO, ROPA, COSMETICO, ALIMENTO,
  HERRAMIENTA, JUGUETE, LIBRO, DOCUMENTO, OTRO
}

extension TipoProductoX on TipoProducto {
  String get label => switch (this) {
    TipoProducto.ELECTRONICO => 'Electrónico',
    TipoProducto.ROPA        => 'Ropa',
    TipoProducto.COSMETICO   => 'Cosmético',
    TipoProducto.ALIMENTO    => 'Alimento',
    TipoProducto.HERRAMIENTA => 'Herramienta',
    TipoProducto.JUGUETE     => 'Juguete',
    TipoProducto.LIBRO       => 'Libro',
    TipoProducto.DOCUMENTO   => 'Documento',
    TipoProducto.OTRO        => 'Otro',
  };

  // Subcategorías por tipo — igual al backend
  List<String> get subcategorias => switch (this) {
    TipoProducto.ELECTRONICO => [
      'LAPTOP', 'CELULAR', 'TABLET', 'SMARTWATCH', 'AURICULARES',
      'CAMARA', 'CONSOLA_VIDEOJUEGOS', 'COMPONENTE_PC', 'OTRO_ELECTRONICO'
    ],
    TipoProducto.ROPA => [
      'ROPA_HOMBRE', 'ROPA_MUJER', 'ROPA_NINO', 'CALZADO',
      'ACCESORIO_MODA', 'BOLSO_CARTERA', 'OTRO_TEXTIL'
    ],
    TipoProducto.COSMETICO => [
      'PERFUME', 'CREMA_LOCION', 'MAQUILLAJE',
      'SUPLEMENTO_BELLEZA', 'OTRO_COSMETICO'
    ],
    TipoProducto.ALIMENTO => [
      'SUPLEMENTO_DEPORTIVO', 'SNACK_GOLOSINA',
      'VITAMINA_MEDICAMENTO_OTC', 'OTRO_ALIMENTO'
    ],
    TipoProducto.HERRAMIENTA => [
      'HERRAMIENTA_ELECTRICA', 'HERRAMIENTA_MANUAL',
      'REPUESTO_AUTOMOTRIZ', 'REPUESTO_INDUSTRIAL', 'OTRO_REPUESTO'
    ],
    TipoProducto.JUGUETE => [
      'JUGUETE_INFANTIL', 'ARTICULO_BEBE', 'JUEGO_MESA',
      'FIGURA_COLECCIONABLE', 'OTRO_JUGUETE'
    ],
    TipoProducto.LIBRO => [
      'LIBRO_TECNICO', 'LIBRO_TEXTO', 'NOVELA_LITERATURA',
      'REVISTA', 'OTRO_LIBRO'
    ],
    TipoProducto.DOCUMENTO => [
      'DOCUMENTO_LEGAL', 'DOCUMENTO_ACADEMICO',
      'DOCUMENTO_COMERCIAL', 'OTRO_DOCUMENTO'
    ],
    TipoProducto.OTRO => [
      'ARTICULO_HOGAR', 'DEPORTE_FITNESS',
      'MASCOTA_VETERINARIA', 'SIN_CLASIFICAR'
    ],
  };

  String subcategoriaLabel(String key) =>
      key.replaceAll('_', ' ').toLowerCase().split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
}
// ─── Item del pedido ──────────────────────────────────────────────────────────
class PedidoItemModel {
  final String  id;
  final String  tipoProducto;
  final String? subcategoria;   // ← NUEVO
  final String  descripcion;
  final String? trackingExterno;
  final String? proveedor;
  final double? peso;
  final double? valorDeclarado;
  final bool    llego;
  final bool    despachado;
  final String? observaciones;

  const PedidoItemModel({
    required this.id,
    required this.tipoProducto,
    this.subcategoria,            // ← NUEVO
    required this.descripcion,
    this.trackingExterno,
    this.proveedor,
    this.peso,
    this.valorDeclarado,
    required this.llego,
    required this.despachado,
    this.observaciones,
  });

  factory PedidoItemModel.fromJson(Map<String, dynamic> j) => PedidoItemModel(
    id:             j['id']?.toString() ?? '',
    tipoProducto:   j['tipoProducto']?.toString() ?? '',
    subcategoria:   j['subcategoria']?.toString(),   // ← NUEVO
    descripcion:    j['descripcion']?.toString() ?? '',
    trackingExterno:j['trackingExterno']?.toString(),
    proveedor:      j['proveedor']?.toString(),
    peso:           (j['peso'] as num?)?.toDouble(),
    valorDeclarado: (j['valorDeclarado'] as num?)?.toDouble(),
    llego:          j['llego'] as bool? ?? false,
    despachado:     j['despachado'] as bool? ?? false,
    observaciones:  j['observaciones']?.toString(),
  );
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
  final String  descripcion;
  final double? peso;
  final double? largo;
  final double? ancho;
  final double? alto;
  final double? valorDeclarado;
  final int?    cantidadItems;

  // Categoría y tarifa
  final String? categoriaPedido;
  final String? tipoTarifa;
  final double? pesoTotal;

  // Items del pedido
  final List<PedidoItemModel> items;

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

  // ─── Pago ─────────────────────────────────────────────────────────────────────
  final FormaPago?  formaPago;
  final EstadoPago? estadoPago;
  final String?     bancoOrigen;
  final String?     numeroReferencia;
  final bool        tieneComprobante;
  final DateTime?   fechaSubidaComprobante;
  final DateTime?   fechaVerificacionPago;
  final String?     motivoRechazo;

// ─── Facturación ──────────────────────────────────────────────────────────────
  final DatosFacturacionModel? datosFacturacion;

// ─── Registro presencial ──────────────────────────────────────────────────────
  final bool    registradoEnSucursal;
  final String? sucursalAtencionNombre;
  final String? registradoPorNombre;


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
    this.categoriaPedido,
    this.tipoTarifa,
    this.pesoTotal,
    this.items = const [],
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
    // ─── En el constructor, agregar después de fotoUrl: ───────────────────────────
    this.formaPago,
    this.estadoPago,
    this.bancoOrigen,
    this.numeroReferencia,
    this.tieneComprobante = false,
    this.fechaSubidaComprobante,
    this.fechaVerificacionPago,
    this.motivoRechazo,
    this.datosFacturacion,
    this.registradoEnSucursal = false,
    this.sucursalAtencionNombre,
    this.registradoPorNombre,

  });

  String get clienteNombreCompleto => '$clienteNombres $clienteApellidos';

  bool get tieneRecepcionParcial =>
      estado == EstadoPedido.RECEPCION_PARCIAL;

  bool get tieneItems => items.isNotEmpty;

  int get itemsLlegaron => items.where((i) => i.llego).length;
  int get itemsFaltantes => items.where((i) => !i.llego).length;

  factory PedidoModel.fromJson(Map<String, dynamic> j) => PedidoModel(
    id:                   j['id']?.toString()               ?? '',
    numeroPedido:         j['numeroPedido']?.toString()     ?? '',
    tipo:                 _parseTipo(j['tipo']?.toString()),
    estado:               _parseEstado(j['estado']?.toString()),
    clienteId:            j['clienteId']?.toString()        ?? '',
    clienteNombres:       j['clienteNombres']?.toString()   ?? '',
    clienteApellidos:     j['clienteApellidos']?.toString() ?? '',
    clienteCasillero:     j['clienteCasillero']?.toString() ?? '',
    clienteIdentificacion:j['clienteIdentificacion']?.toString(),
    trackingExterno:      j['trackingExterno']?.toString(),
    proveedor:            j['proveedor']?.toString(),
    urlTracking:          j['urlTracking']?.toString(),
    descripcion:          j['descripcion']?.toString()      ?? '',
    peso:           (j['peso']           as num?)?.toDouble(),
    largo:          (j['largo']          as num?)?.toDouble(),
    ancho:          (j['ancho']          as num?)?.toDouble(),
    alto:           (j['alto']           as num?)?.toDouble(),
    valorDeclarado: (j['valorDeclarado'] as num?)?.toDouble(),
    cantidadItems:  j['cantidadItems'] as int?,
    categoriaPedido:j['categoriaPedido']?.toString(),
    tipoTarifa:     j['tipoTarifa']?.toString(),
    pesoTotal:      (j['pesoTotal'] as num?)?.toDouble(),
    items: (j['items'] as List<dynamic>?)
        ?.map((i) => PedidoItemModel.fromJson(i as Map<String, dynamic>))
        .toList() ?? [],
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
    // ─── En fromJson, agregar: ────────────────────────────────────────────────────
    formaPago: _parseFormaPago(j['formaPago']?.toString()),
    estadoPago: _parseEstadoPago(j['estadoPago']?.toString()),
    bancoOrigen:            j['bancoOrigen']?.toString(),
    numeroReferencia:       j['numeroReferencia']?.toString(),
    tieneComprobante:       j['tieneComprobante'] as bool? ?? false,
    fechaSubidaComprobante: _dt(j['fechaSubidaComprobante']),
    fechaVerificacionPago:  _dt(j['fechaVerificacionPago']),
    motivoRechazo:          j['motivoRechazo']?.toString(),
    datosFacturacion: j['factRucCedula'] != null
        ? DatosFacturacionModel.fromJson(j) : null,
    registradoEnSucursal:   j['registradoEnSucursal'] as bool? ?? false,
    sucursalAtencionNombre: j['sucursalAtencionNombre']?.toString(),
    registradoPorNombre:    j['registradoPorNombre']?.toString(),

  );

// ─── Parsers estáticos nuevos: ────────────────────────────────────────────────
  static FormaPago? _parseFormaPago(String? s) => s == null ? null :
  FormaPago.values.firstWhere((e) => e.name == s,
      orElse: () => FormaPago.EFECTIVO);

  static EstadoPago? _parseEstadoPago(String? s) => s == null ? null :
  EstadoPago.values.firstWhere((e) => e.name == s,
      orElse: () => EstadoPago.PENDIENTE_COMPROBANTE);
  static EstadoPedido _parseEstado(String? s) => EstadoPedido.values
      .firstWhere((e) => e.name == s, orElse: () => EstadoPedido.REGISTRADO);

  static TipoPedido _parseTipo(String? s) =>
      s == 'EXPORTACION' ? TipoPedido.EXPORTACION : TipoPedido.IMPORTACION;

  static DateTime? _dt(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  PedidoModel copyWith({EstadoPedido? estado, List<PedidoItemModel>? items}) =>
      PedidoModel(
        id: id, numeroPedido: numeroPedido,
        tipo: tipo, estado: estado ?? this.estado,
        clienteId: clienteId, clienteNombres: clienteNombres,
        clienteApellidos: clienteApellidos, clienteCasillero: clienteCasillero,
        clienteIdentificacion: clienteIdentificacion,
        trackingExterno: trackingExterno, proveedor: proveedor,
        urlTracking: urlTracking, descripcion: descripcion,
        peso: peso, largo: largo, ancho: ancho, alto: alto,
        valorDeclarado: valorDeclarado, cantidadItems: cantidadItems,
        categoriaPedido: categoriaPedido, tipoTarifa: tipoTarifa,
        pesoTotal: pesoTotal, items: items ?? this.items,
        sucursalOrigenId: sucursalOrigenId,
        sucursalOrigenNombre: sucursalOrigenNombre,
        sucursalOrigenPais: sucursalOrigenPais,
        sucursalDestinoId: sucursalDestinoId,
        sucursalDestinoNombre: sucursalDestinoNombre,
        sucursalDestinoCiudad: sucursalDestinoCiudad,
        registradoPor: registradoPor, fechaRegistro: fechaRegistro,
        fechaRecepcionSede: fechaRecepcionSede,
        fechaSalidaExterior: fechaSalidaExterior,
        fechaLlegadaEcuador: fechaLlegadaEcuador,
        fechaDisponible: fechaDisponible, fechaEntrega: fechaEntrega,
        observaciones: observaciones, notasInternas: notasInternas,
        fotoUrl: fotoUrl,
      );
}