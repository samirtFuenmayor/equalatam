import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_template.dart';
import '../../domain/entities/notification_log.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_ds.dart';
import '../models/notification_model.dart';
import '../models/notification_template_model.dart';
import '../models/notification_log_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remote;

  NotificationsRepositoryImpl(this.remote);

  @override
  Future<void> createTemplate(NotificationTemplate template) async {
    final m = NotificationTemplateModel(
      id: template.id,
      name: template.name,
      channel: template.channel,
      subject: template.subject,
      body: template.body,
    );
    await remote.saveTemplate(m);
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    await remote.deleteTemplate(templateId);
  }

  @override
  Future<List<NotificationTemplate>> getTemplates() async {
    final ms = await remote.fetchTemplates();
    return ms.map((m) => NotificationTemplate(
      id: m.id,
      name: m.name,
      channel: m.channel,
      subject: m.subject,
      body: m.body,
    )).toList();
  }

  @override
  Future<void> sendNotification(NotificationEntity notification) async {
    final m = NotificationModel(
      id: notification.id,
      channel: notification.channel,
      to: notification.to,
      subject: notification.subject,
      body: notification.body,
      scheduledAt: notification.scheduledAt,
      status: notification.status,
    );
    await remote.sendNotificationMock(m);
  }

  @override
  Future<void> scheduleNotification(NotificationEntity notification) async {
    final m = NotificationModel(
      id: notification.id,
      channel: notification.channel,
      to: notification.to,
      subject: notification.subject,
      body: notification.body,
      scheduledAt: notification.scheduledAt,
      status: notification.status,
    );
    await remote.scheduleNotificationMock(m);
  }

  @override
  Future<List<NotificationLog>> getLogs({int limit = 100}) async {
    final ls = await remote.fetchLogs(limit: limit);
    return ls.map((l) => NotificationLog(
      id: l.id,
      notificationId: l.notificationId,
      timestamp: l.timestamp,
      channel: l.channel,
      to: l.to,
      status: l.status,
      details: l.details,
    )).toList();
  }

  @override
  Future<void> updateTemplate(NotificationTemplate template) async {
    // same as create (overwrite)
    await createTemplate(template);
  }
}
