import '../entities/tracking_info.dart';

abstract class PublicTrackingRepository {
  /// Retorna TrackingInfo si existe, o null si no encontrado.
  Future<TrackingInfo?> getByWaybill(String waybill);
}
