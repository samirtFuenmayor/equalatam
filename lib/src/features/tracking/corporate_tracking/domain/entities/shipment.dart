class CorporateTrackingRecord {
  final String waybill;
  final String clientRef;
  final String status;
  final String origin;
  final String destination;
  final DateTime createdAt;
  final DateTime updatedAt;

  CorporateTrackingRecord({
    required this.waybill,
    required this.clientRef,
    required this.status,
    required this.origin,
    required this.destination,
    required this.createdAt,
    required this.updatedAt,
  });
}
