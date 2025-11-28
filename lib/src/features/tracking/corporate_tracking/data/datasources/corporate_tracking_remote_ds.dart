import 'dart:async';
import '../models/corporate_tracking_model.dart';

class CorporateTrackingRemoteDataSource {
  // Mock in-memory store
  final List<CorporateTrackingModel> _store = List.generate(20, (i) {
    final now = DateTime.now();
    return CorporateTrackingModel(
      waybill: 'WB${1000 + i}',
      clientRef: 'CLIENT-${(i % 4) + 1}',
      status: i % 3 == 0 ? 'entregado' : (i % 3 == 1 ? 'en_transito' : 'pendiente'),
      origin: 'Sucursal ${(i % 5) + 1}',
      destination: 'Ciudad ${(i % 8) + 1}',
      createdAt: now.subtract(Duration(days: i+1)),
      updatedAt: now.subtract(Duration(hours: i * 3)),
    );
  });

  Future<List<CorporateTrackingModel>> fetchForClient(String clientRef) async {
    await Future.delayed(const Duration(milliseconds:300));
    return _store.where((s) => s.clientRef == clientRef).toList();
  }

  Future<List<CorporateTrackingModel>> fetchByWaybills(List<String> waybills) async {
    await Future.delayed(const Duration(milliseconds:300));
    return _store.where((s) => waybills.contains(s.waybill)).toList();
  }

  Future<List<CorporateTrackingModel>> fetchAll({int limit = 100}) async {
    await Future.delayed(const Duration(milliseconds:200));
    return _store.take(limit).toList();
  }

  // Mock CSV upload: parse lines and add to store
  Future<void> uploadCsv(String csvContent, String clientRef) async {
    await Future.delayed(const Duration(milliseconds:400));
    final lines = csvContent.split('\n').where((l) => l.trim().isNotEmpty);
    for (final l in lines) {
      final parts = l.split(',');
      final waybill = parts[0].trim();
      _store.insert(0, CorporateTrackingModel(
        waybill: waybill,
        clientRef: clientRef,
        status: 'pendiente',
        origin: parts.length>1?parts[1].trim():'Sucursal X',
        destination: parts.length>2?parts[2].trim():'Ciudad Y',
        createdAt: DateTime.now().subtract(const Duration(days:1)),
        updatedAt: DateTime.now(),
      ));
    }
  }
}
