import '../../domain/entities/tracking_info.dart';
import '../../domain/repositories/public_tracking_repository.dart';
import '../datasources/public_tracking_remote_ds.dart';
import '../models/tracking_model.dart';

class PublicTrackingRepositoryImpl implements PublicTrackingRepository {
  final PublicTrackingRemoteDataSource remote;

  PublicTrackingRepositoryImpl(this.remote);

  @override
  Future<TrackingInfo?> getByWaybill(String waybill) async {
    final model = await remote.fetchByWaybill(waybill);
    return model;
  }
}
