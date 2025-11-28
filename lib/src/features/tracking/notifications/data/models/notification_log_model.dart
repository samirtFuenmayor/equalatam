import '../../domain/entities/notification_log.dart';

class NotificationLogModel extends NotificationLog {
  NotificationLogModel({
    required super.id,
    required super.notificationId,
    required super.timestamp,
    required super.channel,
    required super.to,
    required super.status,
    required super.details,
  });

  factory NotificationLogModel.fromJson(Map<String, dynamic> j) => NotificationLogModel(
    id: j['id'],
    notificationId: j['notificationId'],
    timestamp: DateTime.parse(j['timestamp']),
    channel: j['channel'],
    to: j['to'],
    status: j['status'],
    details: j['details'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'notificationId': notificationId,
    'timestamp': timestamp.toIso8601String(),
    'channel': channel,
    'to': to,
    'status': status,
    'details': details,
  };
}
