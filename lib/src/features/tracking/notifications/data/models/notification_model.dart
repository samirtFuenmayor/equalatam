import '../../domain/entities/notification.dart';

class NotificationModel extends NotificationEntity {
  NotificationModel({
    required super.id,
    required super.channel,
    required super.to,
    required super.subject,
    required super.body,
    required super.scheduledAt,
    required super.status,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    id: j['id'],
    channel: j['channel'],
    to: j['to'],
    subject: j['subject'],
    body: j['body'],
    scheduledAt: DateTime.parse(j['scheduledAt']),
    status: j['status'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel': channel,
    'to': to,
    'subject': subject,
    'body': body,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status,
  };
}
