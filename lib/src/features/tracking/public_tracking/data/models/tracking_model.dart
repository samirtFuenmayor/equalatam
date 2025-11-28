import '../../domain/entities/tracking_info.dart';

class TrackingModel extends TrackingInfo {
  TrackingModel({
    required String waybill,
    required String status,
    required String origin,
    required String destination,
    required DateTime createdAt,
    required List<TrackingEvent> events,
    double? lastLat,
    double? lastLng,
  }) : super(
    waybill: waybill,
    status: status,
    origin: origin,
    destination: destination,
    createdAt: createdAt,
    events: events,
    lastLat: lastLat,
    lastLng: lastLng,
  );

  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    final ev = (json['events'] as List<dynamic>?) ?? [];
    return TrackingModel(
      waybill: json['waybill'] ?? '',
      status: json['status'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      events: ev.map((e) {
        return TrackingEvent(
          timestamp: DateTime.parse(e['timestamp']),
          location: e['location'] ?? '',
          description: e['description'] ?? '',
          code: e['code'] ?? '',
        );
      }).toList(),
      lastLat: json['lastLat'] != null ? (json['lastLat'] as num).toDouble() : null,
      lastLng: json['lastLng'] != null ? (json['lastLng'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'waybill': waybill,
    'status': status,
    'origin': origin,
    'destination': destination,
    'createdAt': createdAt.toIso8601String(),
    'events': events.map((e) => {
      'timestamp': e.timestamp.toIso8601String(),
      'location': e.location,
      'description': e.description,
      'code': e.code,
    }).toList(),
    'lastLat': lastLat,
    'lastLng': lastLng,
  };
}
