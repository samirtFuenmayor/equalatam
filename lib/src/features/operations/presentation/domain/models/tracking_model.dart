// lib/src/features/tracking/domain/models/tracking_model.dart
import '../../../pedidos/domain/model/pedido_model.dart';

class TrackingEventoModel {
  final String        id;
  final EstadoPedido  estado;
  final String        descripcion;
  final String?       sucursalNombre;
  final String?       sucursalPais;
  final String?       ubicacionDetalle;
  final String?       registradoPor;
  final bool          visibleParaCliente;
  final String?       notaInterna;
  final String?       numeroDespacho;
  final DateTime      fechaEvento;

  const TrackingEventoModel({
    required this.id,
    required this.estado,
    required this.descripcion,
    this.sucursalNombre,
    this.sucursalPais,
    this.ubicacionDetalle,
    this.registradoPor,
    required this.visibleParaCliente,
    this.notaInterna,
    this.numeroDespacho,
    required this.fechaEvento,
  });

  factory TrackingEventoModel.fromJson(Map<String, dynamic> j) =>
      TrackingEventoModel(
        id:                 j['id'].toString(),
        estado:             EstadoPedido.values.byName(j['estado'].toString()),
        descripcion:        j['descripcion']?.toString() ?? '',
        sucursalNombre:     j['sucursalNombre']?.toString(),
        sucursalPais:       j['sucursalPais']?.toString(),
        ubicacionDetalle:   j['ubicacionDetalle']?.toString(),
        registradoPor:      j['registradoPor']?.toString(),
        visibleParaCliente: j['visibleParaCliente'] as bool? ?? true,
        notaInterna:        j['notaInterna']?.toString(),
        numeroDespacho:     j['numeroDespacho']?.toString(),
        fechaEvento:        DateTime.parse(j['fechaEvento'].toString()),
      );
}

class TrackingResumenModel {
  final String        pedidoId;
  final String        numeroPedido;
  final EstadoPedido  estadoActual;
  final String        descripcion;
  final String?       trackingExterno;
  final String?       proveedor;
  final String        clienteNombre;
  final String        clienteCasillero;
  final String?       sucursalOrigen;
  final String?       sucursalDestino;
  final DateTime      fechaRegistro;
  final DateTime?     fechaRecepcionSede;
  final DateTime?     fechaSalidaExterior;
  final DateTime?     fechaLlegadaEcuador;
  final DateTime?     fechaDisponible;
  final DateTime?     fechaEntrega;
  final List<TrackingEventoModel> historial;

  const TrackingResumenModel({
    required this.pedidoId,
    required this.numeroPedido,
    required this.estadoActual,
    required this.descripcion,
    this.trackingExterno,
    this.proveedor,
    required this.clienteNombre,
    required this.clienteCasillero,
    this.sucursalOrigen,
    this.sucursalDestino,
    required this.fechaRegistro,
    this.fechaRecepcionSede,
    this.fechaSalidaExterior,
    this.fechaLlegadaEcuador,
    this.fechaDisponible,
    this.fechaEntrega,
    required this.historial,
  });

  factory TrackingResumenModel.fromJson(Map<String, dynamic> j) =>
      TrackingResumenModel(
        pedidoId:           j['pedidoId'].toString(),
        numeroPedido:       j['numeroPedido'].toString(),
        estadoActual:       EstadoPedido.values.byName(j['estadoActual'].toString()),
        descripcion:        j['descripcion']?.toString() ?? '',
        trackingExterno:    j['trackingExterno']?.toString(),
        proveedor:          j['proveedor']?.toString(),
        clienteNombre:      j['clienteNombre']?.toString() ?? '',
        clienteCasillero:   j['clienteCasillero']?.toString() ?? '',
        sucursalOrigen:     j['sucursalOrigen']?.toString(),
        sucursalDestino:    j['sucursalDestino']?.toString(),
        fechaRegistro:      DateTime.parse(j['fechaRegistro'].toString()),
        fechaRecepcionSede:   j['fechaRecepcionSede']   != null ? DateTime.parse(j['fechaRecepcionSede'].toString())   : null,
        fechaSalidaExterior:  j['fechaSalidaExterior']  != null ? DateTime.parse(j['fechaSalidaExterior'].toString())  : null,
        fechaLlegadaEcuador:  j['fechaLlegadaEcuador']  != null ? DateTime.parse(j['fechaLlegadaEcuador'].toString())  : null,
        fechaDisponible:      j['fechaDisponible']       != null ? DateTime.parse(j['fechaDisponible'].toString())      : null,
        fechaEntrega:         j['fechaEntrega']          != null ? DateTime.parse(j['fechaEntrega'].toString())         : null,
        historial: (j['historial'] as List? ?? [])
            .map((e) => TrackingEventoModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  double get progreso {
    const orden = [
      EstadoPedido.REGISTRADO,
      EstadoPedido.RECIBIDO_EN_SEDE,
      EstadoPedido.EN_CONSOLIDACION,
      EstadoPedido.EN_TRANSITO,
      EstadoPedido.EN_ADUANA,
      EstadoPedido.LIBERADO_ADUANA,
      EstadoPedido.RECIBIDO_EN_MATRIZ,
      EstadoPedido.EN_DISTRIBUCION,
      EstadoPedido.DISPONIBLE_EN_SUCURSAL,
      EstadoPedido.ENTREGADO,
    ];
    final idx = orden.indexOf(estadoActual);
    if (idx < 0) return 0;
    return (idx + 1) / orden.length;
  }
}