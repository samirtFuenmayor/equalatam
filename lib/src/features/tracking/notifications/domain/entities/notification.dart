class NotificationEntity {
  final String id;
  final String channel; // email | sms | webhook
  final String to;
  final String subject;
  final String body;
  final DateTime scheduledAt; // for scheduled sends
  final String status; // pending | sent | failed

  NotificationEntity({
    required this.id,
    required this.channel,
    required this.to,
    required this.subject,
    required this.body,
    required this.scheduledAt,
    required this.status,
  });
}
