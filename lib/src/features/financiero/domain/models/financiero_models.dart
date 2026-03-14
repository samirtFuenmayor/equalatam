// lib/src/features/financiero/domain/models/financiero_models.dart

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum CategoriaPaquete {
  SOBRE, PEQUENO, MEDIANO, GRANDE, EXTRA_GRANDE, ELECTRONICO, ESPECIAL;

  String get label => switch (this) {
    CategoriaPaquete.SOBRE        => 'Sobre',
    CategoriaPaquete.PEQUENO      => 'Pequeño',
    CategoriaPaquete.MEDIANO      => 'Mediano',
    CategoriaPaquete.GRANDE       => 'Grande',
    CategoriaPaquete.EXTRA_GRANDE => 'Extra Grande',
    CategoriaPaquete.ELECTRONICO  => 'Electrónico',
    CategoriaPaquete.ESPECIAL     => 'Especial',
  };

  static CategoriaPaquete fromString(String s) =>
      CategoriaPaquete.values.firstWhere((e) => e.name == s,
          orElse: () => CategoriaPaquete.PEQUENO);
}

enum TipoPedidoFinanciero {
  IMPORTACION, EXPORTACION, AMBOS;

  String get label => switch (this) {
    TipoPedidoFinanciero.IMPORTACION => 'Importación',
    TipoPedidoFinanciero.EXPORTACION => 'Exportación',
    TipoPedidoFinanciero.AMBOS       => 'Ambos',
  };

  static TipoPedidoFinanciero fromString(String s) =>
      TipoPedidoFinanciero.values.firstWhere((e) => e.name == s,
          orElse: () => TipoPedidoFinanciero.IMPORTACION);
}

enum EstadoCotizacion {
  PENDIENTE, APROBADA, FACTURADA, VENCIDA, CANCELADA;

  String get label => switch (this) {
    EstadoCotizacion.PENDIENTE  => 'Pendiente',
    EstadoCotizacion.APROBADA   => 'Aprobada',
    EstadoCotizacion.FACTURADA  => 'Facturada',
    EstadoCotizacion.VENCIDA    => 'Vencida',
    EstadoCotizacion.CANCELADA  => 'Cancelada',
  };

  static EstadoCotizacion fromString(String s) =>
      EstadoCotizacion.values.firstWhere((e) => e.name == s,
          orElse: () => EstadoCotizacion.PENDIENTE);
}

enum EstadoFactura {
  BORRADOR, EMITIDA, PAGADA, ANULADA, VENCIDA;

  String get label => switch (this) {
    EstadoFactura.BORRADOR => 'Borrador',
    EstadoFactura.EMITIDA  => 'Emitida',
    EstadoFactura.PAGADA   => 'Pagada',
    EstadoFactura.ANULADA  => 'Anulada',
    EstadoFactura.VENCIDA  => 'Vencida',
  };

  static EstadoFactura fromString(String s) =>
      EstadoFactura.values.firstWhere((e) => e.name == s,
          orElse: () => EstadoFactura.BORRADOR);
}

enum EstadoPago {
  PENDIENTE, CONFIRMADO, RECHAZADO, DEVUELTO;

  String get label => switch (this) {
    EstadoPago.PENDIENTE  => 'Pendiente',
    EstadoPago.CONFIRMADO => 'Confirmado',
    EstadoPago.RECHAZADO  => 'Rechazado',
    EstadoPago.DEVUELTO   => 'Devuelto',
  };

  static EstadoPago fromString(String s) =>
      EstadoPago.values.firstWhere((e) => e.name == s,
          orElse: () => EstadoPago.PENDIENTE);
}

enum FormaPago {
  EFECTIVO, TRANSFERENCIA, TARJETA_CREDITO, TARJETA_DEBITO, DEPOSITO, CREDITO_CLIENTE;

  String get label => switch (this) {
    FormaPago.EFECTIVO         => 'Efectivo',
    FormaPago.TRANSFERENCIA    => 'Transferencia',
    FormaPago.TARJETA_CREDITO  => 'Tarjeta Crédito',
    FormaPago.TARJETA_DEBITO   => 'Tarjeta Débito',
    FormaPago.DEPOSITO         => 'Depósito',
    FormaPago.CREDITO_CLIENTE  => 'Crédito Cliente',
  };

  static FormaPago fromString(String s) =>
      FormaPago.values.firstWhere((e) => e.name == s,
          orElse: () => FormaPago.EFECTIVO);
}

// ═══════════════════════════════════════════════════════════════════════════════
// TARIFA MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class TarifaModel {
  final String              id;
  final String              nombre;
  final String?             descripcion;
  final CategoriaPaquete    categoria;
  final TipoPedidoFinanciero tipoPedido;
  final double              precioBase;
  final double?             precioPorLibra;
  final double?             pesoMinimo;
  final double?             precioPorCm3;
  final double?             factorDivisorVolumetrico;
  final double?             porcentajeSobreValorDeclarado;
  final double?             pesoDesde;
  final double?             pesoHasta;
  final double              porcentajeIva;
  final String?             vigenciaDesde;
  final String?             vigenciaHasta;
  final bool                activo;

  const TarifaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.categoria,
    required this.tipoPedido,
    required this.precioBase,
    this.precioPorLibra,
    this.pesoMinimo,
    this.precioPorCm3,
    this.factorDivisorVolumetrico,
    this.porcentajeSobreValorDeclarado,
    this.pesoDesde,
    this.pesoHasta,
    this.porcentajeIva = 15.0,
    this.vigenciaDesde,
    this.vigenciaHasta,
    this.activo = true,
  });

  factory TarifaModel.fromJson(Map<String, dynamic> j) => TarifaModel(
    id:           j['id']?.toString() ?? '',
    nombre:       j['nombre']?.toString() ?? '',
    descripcion:  j['descripcion']?.toString(),
    categoria:    CategoriaPaquete.fromString(j['categoria']?.toString() ?? ''),
    tipoPedido:   TipoPedidoFinanciero.fromString(j['tipoPedido']?.toString() ?? ''),
    precioBase:   (j['precioBase'] as num?)?.toDouble() ?? 0.0,
    precioPorLibra:               (j['precioPorLibra'] as num?)?.toDouble(),
    pesoMinimo:                   (j['pesoMinimo'] as num?)?.toDouble(),
    precioPorCm3:                 (j['precioPorCm3'] as num?)?.toDouble(),
    factorDivisorVolumetrico:     (j['factorDivisorVolumetrico'] as num?)?.toDouble(),
    porcentajeSobreValorDeclarado:(j['porcentajeSobreValorDeclarado'] as num?)?.toDouble(),
    pesoDesde:    (j['pesoDesde'] as num?)?.toDouble(),
    pesoHasta:    (j['pesoHasta'] as num?)?.toDouble(),
    porcentajeIva:(j['porcentajeIva'] as num?)?.toDouble() ?? 15.0,
    vigenciaDesde:j['vigenciaDesde']?.toString(),
    vigenciaHasta:j['vigenciaHasta']?.toString(),
    activo:       j['activo'] as bool? ?? true,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// COTIZACION MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class CotizacionModel {
  final String           id;
  final String           numeroCotizacion;
  final String           clienteId;
  final String?          clienteNombre;
  final String?          pedidoId;
  final String?          pedidoNumero;
  final String?          tarifaId;
  final String?          tarifaNombre;
  final CategoriaPaquete? categoria;
  final double?          pesoReal;
  final double?          largo;
  final double?          ancho;
  final double?          alto;
  final double?          valorDeclarado;
  final double?          pesoVolumetrico;
  final double?          pesoFacturable;
  final double           subtotal;
  final double           porcentajeIva;
  final double           montoIva;
  final double           total;
  final String?          detalleCalculo;
  final EstadoCotizacion estado;
  final String?          validaHasta;
  final String?          observaciones;
  final String?          creadoEn;

  const CotizacionModel({
    required this.id,
    required this.numeroCotizacion,
    required this.clienteId,
    this.clienteNombre,
    this.pedidoId,
    this.pedidoNumero,
    this.tarifaId,
    this.tarifaNombre,
    this.categoria,
    this.pesoReal,
    this.largo,
    this.ancho,
    this.alto,
    this.valorDeclarado,
    this.pesoVolumetrico,
    this.pesoFacturable,
    required this.subtotal,
    this.porcentajeIva = 15.0,
    required this.montoIva,
    required this.total,
    this.detalleCalculo,
    required this.estado,
    this.validaHasta,
    this.observaciones,
    this.creadoEn,
  });

  factory CotizacionModel.fromJson(Map<String, dynamic> j) => CotizacionModel(
    id:               j['id']?.toString() ?? '',
    numeroCotizacion: j['numeroCotizacion']?.toString() ?? '',
    clienteId:        j['clienteId']?.toString() ?? '',
    clienteNombre:    j['clienteNombre']?.toString(),
    pedidoId:         j['pedidoId']?.toString(),
    pedidoNumero:     j['pedidoNumero']?.toString(),
    tarifaId:         j['tarifaId']?.toString(),
    tarifaNombre:     j['tarifaNombre']?.toString(),
    categoria:        j['categoria'] != null
        ? CategoriaPaquete.fromString(j['categoria'].toString()) : null,
    pesoReal:         (j['pesoReal'] as num?)?.toDouble(),
    largo:            (j['largo'] as num?)?.toDouble(),
    ancho:            (j['ancho'] as num?)?.toDouble(),
    alto:             (j['alto'] as num?)?.toDouble(),
    valorDeclarado:   (j['valorDeclarado'] as num?)?.toDouble(),
    pesoVolumetrico:  (j['pesoVolumetrico'] as num?)?.toDouble(),
    pesoFacturable:   (j['pesoFacturable'] as num?)?.toDouble(),
    subtotal:         (j['subtotal'] as num?)?.toDouble() ?? 0.0,
    porcentajeIva:    (j['porcentajeIva'] as num?)?.toDouble() ?? 15.0,
    montoIva:         (j['montoIva'] as num?)?.toDouble() ?? 0.0,
    total:            (j['total'] as num?)?.toDouble() ?? 0.0,
    detalleCalculo:   j['detalleCalculo']?.toString(),
    estado:           EstadoCotizacion.fromString(j['estado']?.toString() ?? ''),
    validaHasta:      j['validaHasta']?.toString(),
    observaciones:    j['observaciones']?.toString(),
    creadoEn:         j['creadoEn']?.toString(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FACTURA MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class FacturaDetalleModel {
  final String  id;
  final String  descripcion;
  final double  cantidad;
  final double  precioUnitario;
  final double  descuento;
  final double  subtotal;
  final bool    gravaIva;
  final int     orden;

  const FacturaDetalleModel({
    required this.id,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuento,
    required this.subtotal,
    required this.gravaIva,
    required this.orden,
  });

  factory FacturaDetalleModel.fromJson(Map<String, dynamic> j) =>
      FacturaDetalleModel(
        id:             j['id']?.toString() ?? '',
        descripcion:    j['descripcion']?.toString() ?? '',
        cantidad:       (j['cantidad'] as num?)?.toDouble() ?? 1.0,
        precioUnitario: (j['precioUnitario'] as num?)?.toDouble() ?? 0.0,
        descuento:      (j['descuento'] as num?)?.toDouble() ?? 0.0,
        subtotal:       (j['subtotal'] as num?)?.toDouble() ?? 0.0,
        gravaIva:       j['gravaIva'] as bool? ?? true,
        orden:          j['orden'] as int? ?? 1,
      );
}

class FacturaModel {
  final String              id;
  final String?             numeroFactura;
  final String              clienteId;
  final String?             clienteNombre;
  final String?             clienteIdentificacion;
  final String?             pedidoId;
  final String?             pedidoNumero;
  final String?             cotizacionId;
  final double              subtotal0;
  final double              subtotal15;
  final double              descuento;
  final double              iva;
  final double              total;
  final FormaPago           formaPago;
  final EstadoFactura       estado;
  final String?             fechaEmision;
  final String?             fechaVencimiento;
  final String?             observaciones;
  final String?             emisorRuc;
  final String?             emisorRazonSocial;
  final List<FacturaDetalleModel> detalles;
  final String?             creadoEn;

  const FacturaModel({
    required this.id,
    this.numeroFactura,
    required this.clienteId,
    this.clienteNombre,
    this.clienteIdentificacion,
    this.pedidoId,
    this.pedidoNumero,
    this.cotizacionId,
    required this.subtotal0,
    required this.subtotal15,
    required this.descuento,
    required this.iva,
    required this.total,
    required this.formaPago,
    required this.estado,
    this.fechaEmision,
    this.fechaVencimiento,
    this.observaciones,
    this.emisorRuc,
    this.emisorRazonSocial,
    this.detalles = const [],
    this.creadoEn,
  });

  factory FacturaModel.fromJson(Map<String, dynamic> j) => FacturaModel(
    id:                   j['id']?.toString() ?? '',
    numeroFactura:        j['numeroFactura']?.toString(),
    clienteId:            j['clienteId']?.toString() ?? '',
    clienteNombre:        j['clienteNombre']?.toString(),
    clienteIdentificacion:j['clienteIdentificacion']?.toString(),
    pedidoId:             j['pedidoId']?.toString(),
    pedidoNumero:         j['pedidoNumero']?.toString(),
    cotizacionId:         j['cotizacionId']?.toString(),
    subtotal0:            (j['subtotal0'] as num?)?.toDouble() ?? 0.0,
    subtotal15:           (j['subtotal15'] as num?)?.toDouble() ?? 0.0,
    descuento:            (j['descuento'] as num?)?.toDouble() ?? 0.0,
    iva:                  (j['iva'] as num?)?.toDouble() ?? 0.0,
    total:                (j['total'] as num?)?.toDouble() ?? 0.0,
    formaPago:            FormaPago.fromString(j['formaPago']?.toString() ?? ''),
    estado:               EstadoFactura.fromString(j['estado']?.toString() ?? ''),
    fechaEmision:         j['fechaEmision']?.toString(),
    fechaVencimiento:     j['fechaVencimiento']?.toString(),
    observaciones:        j['observaciones']?.toString(),
    emisorRuc:            j['emisorRuc']?.toString(),
    emisorRazonSocial:    j['emisorRazonSocial']?.toString(),
    detalles: (j['detalles'] as List<dynamic>?)
        ?.map((d) => FacturaDetalleModel.fromJson(d as Map<String, dynamic>))
        .toList() ??
        [],
    creadoEn: j['creadoEn']?.toString(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGO MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class PagoModel {
  final String     id;
  final String     numeroPago;
  final String     facturaId;
  final String?    facturaNumero;
  final String?    clienteNombre;
  final double     monto;
  final FormaPago  formaPago;
  final String?    referencia;
  final String?    banco;
  final String?    comprobanteUrl;
  final EstadoPago estado;
  final String?    fechaPago;
  final String?    fechaConfirmacion;
  final String?    registradoPor;
  final String?    confirmadoPor;
  final String?    observaciones;

  const PagoModel({
    required this.id,
    required this.numeroPago,
    required this.facturaId,
    this.facturaNumero,
    this.clienteNombre,
    required this.monto,
    required this.formaPago,
    this.referencia,
    this.banco,
    this.comprobanteUrl,
    required this.estado,
    this.fechaPago,
    this.fechaConfirmacion,
    this.registradoPor,
    this.confirmadoPor,
    this.observaciones,
  });

  factory PagoModel.fromJson(Map<String, dynamic> j) => PagoModel(
    id:               j['id']?.toString() ?? '',
    numeroPago:       j['numeroPago']?.toString() ?? '',
    facturaId:        j['facturaId']?.toString() ?? '',
    facturaNumero:    j['facturaNumero']?.toString(),
    clienteNombre:    j['clienteNombre']?.toString(),
    monto:            (j['monto'] as num?)?.toDouble() ?? 0.0,
    formaPago:        FormaPago.fromString(j['formaPago']?.toString() ?? ''),
    referencia:       j['referencia']?.toString(),
    banco:            j['banco']?.toString(),
    comprobanteUrl:   j['comprobanteUrl']?.toString(),
    estado:           EstadoPago.fromString(j['estado']?.toString() ?? ''),
    fechaPago:        j['fechaPago']?.toString(),
    fechaConfirmacion:j['fechaConfirmacion']?.toString(),
    registradoPor:    j['registradoPor']?.toString(),
    confirmadoPor:    j['confirmadoPor']?.toString(),
    observaciones:    j['observaciones']?.toString(),
  );
}