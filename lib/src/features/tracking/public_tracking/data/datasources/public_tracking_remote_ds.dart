import 'dart:async';
import 'package:dio/dio.dart';
import '../models/tracking_model.dart';

/// DataSource remoto (mock/simple). Reemplaza con llamadas reales a tu backend.
/// Por ahora devuelve datos ficticios si la guía cumple cierto patrón.
class PublicTrackingRemoteDataSource {
  final Dio dio;

  PublicTrackingRemoteDataSource({Dio? dio}) : dio = dio ?? Dio();

  /// Llama al endpoint real: GET /tracking/{waybill}
  /// Aquí simulamos respuesta si waybill empieza con "WB"
  Future<TrackingModel?> fetchByWaybill(String waybill) async {
    // MOCK: si no empieza con WB, devolvemos null (no encontrado)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!waybill.toUpperCase().startsWith('WB')) return null;

    // Simulate a realistic payload
    final now = DateTime.now();
    final payload = {
      "waybill": waybill.toUpperCase(),
      "status": "En tránsito",
      "origin": "Sucursal Central",
      "destination": "Cliente Final",
      "createdAt": now.subtract(const Duration(days: 2)).toIso8601String(),
      "lastLat": -0.180653, // mock coords
      "lastLng": -78.467834,
      "events": [
        {
          "timestamp": now.subtract(const Duration(days: 2, hours: 5)).toIso8601String(),
          "location": "Recepción Sucursal",
          "description": "Paquete recibido en sucursal origen",
          "code": "RCV"
        },
        {
          "timestamp": now.subtract(const Duration(days: 1, hours: 8)).toIso8601String(),
          "location": "Salida Hub",
          "description": "Salida hacia hub intermedio",
          "code": "SH"
        },
        {
          "timestamp": now.subtract(const Duration(hours: 6)).toIso8601String(),
          "location": "En tránsito",
          "description": "En transporte - última ubicación conocida",
          "code": "IT"
        },
      ]
    };

    return TrackingModel.fromJson(payload);
  }
}
