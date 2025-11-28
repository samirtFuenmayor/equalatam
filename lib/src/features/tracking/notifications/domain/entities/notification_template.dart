class NotificationTemplate {
  final String id;
  final String name;
  final String channel; // email | sms
  final String subject; // SMS may ignore subject
  final String body; // body with placeholders, e.g. {{waybill}}, {{status}}

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.channel,
    required this.subject,
    required this.body,
  });
}
