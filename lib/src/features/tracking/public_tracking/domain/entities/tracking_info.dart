class TrackingInfo {
  final String waybill;
  final String status;
  final String origin;
  final String destination;
  final DateTime createdAt;
  final List<TrackingEvent> events;
  final double? lastLat;
  final double? lastLng;

  TrackingInfo({
    required this.waybill,
    required this.status,
    required this.origin,
    required this.destination,
    required this.createdAt,
    required this.events,
    this.lastLat,
    this.lastLng,
  });
}

class TrackingEvent {
  final DateTime timestamp;
  final String location;
  final String description;
  final String code;

  TrackingEvent({
    required this.timestamp,
    required this.location,
    required this.description,
    required this.code,
  });
}
