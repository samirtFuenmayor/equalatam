import '../../domain/entities/shipment.dart';

class CorporateTrackingModel extends CorporateTrackingRecord {
  CorporateTrackingModel({
    required super.waybill,
    required super.clientRef,
    required super.status,
    required super.origin,
    required super.destination,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CorporateTrackingModel.fromJson(Map<String,dynamic> j) => CorporateTrackingModel(
    waybill: j['waybill'],
    clientRef: j['clientRef'],
    status: j['status'],
    origin: j['origin'],
    destination: j['destination'],
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
  );

  Map<String,dynamic> toJson() => {
    'waybill': waybill,
    'clientRef': clientRef,
    'status': status,
    'origin': origin,
    'destination': destination,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
