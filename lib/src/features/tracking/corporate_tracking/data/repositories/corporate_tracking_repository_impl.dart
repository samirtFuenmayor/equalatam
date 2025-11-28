import '../../domain/entities/shipment.dart';
import '../datasources/corporate_tracking_remote_ds.dart';
import '../models/corporate_tracking_model.dart';

abstract class CorporateTrackingRepository {
  Future<List<CorporateTrackingRecord>> getForClient(String clientRef);
  Future<List<CorporateTrackingRecord>> getByWaybills(List<String> waybills);
  Future<void> uploadCsv(String csvContent, String clientRef);
  Future<List<CorporateTrackingRecord>> getAll({int limit});
}

class CorporateTrackingRepositoryImpl implements CorporateTrackingRepository {
  final CorporateTrackingRemoteDataSource remote;
  CorporateTrackingRepositoryImpl(this.remote);

  @override Future<List<CorporateTrackingRecord>> getForClient(String clientRef) async => (await remote.fetchForClient(clientRef)).cast<CorporateTrackingModel>();

  @override Future<List<CorporateTrackingRecord>> getByWaybills(List<String> waybills) async => (await remote.fetchByWaybills(waybills)).cast<CorporateTrackingModel>();

  @override Future<void> uploadCsv(String csvContent, String clientRef) async => await remote.uploadCsv(csvContent, clientRef);

  @override Future<List<CorporateTrackingRecord>> getAll({int limit = 100}) async => (await remote.fetchAll(limit: limit)).cast<CorporateTrackingModel>();
}
