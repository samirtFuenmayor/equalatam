class NotificationLog {
  final String id;
  final String notificationId;
  final DateTime timestamp;
  final String channel;
  final String to;
  final String status; // sent | failed
  final String details; // provider response or error

  NotificationLog({
    required this.id,
    required this.notificationId,
    required this.timestamp,
    required this.channel,
    required this.to,
    required this.status,
    required this.details,
  });
}
