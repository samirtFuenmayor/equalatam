import '../../domain/entities/notification_template.dart';

class NotificationTemplateModel extends NotificationTemplate {
  NotificationTemplateModel({
    required super.id,
    required super.name,
    required super.channel,
    required super.subject,
    required super.body,
  });

  factory NotificationTemplateModel.fromJson(Map<String, dynamic> j) => NotificationTemplateModel(
    id: j['id'],
    name: j['name'],
    channel: j['channel'],
    subject: j['subject'],
    body: j['body'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'channel': channel,
    'subject': subject,
    'body': body,
  };
}
