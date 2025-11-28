import '../entities/notification.dart';
import '../entities/notification_template.dart';
import '../entities/notification_log.dart';

abstract class NotificationsRepository {
  // Templates
  Future<List<NotificationTemplate>> getTemplates();
  Future<void> createTemplate(NotificationTemplate template);
  Future<void> updateTemplate(NotificationTemplate template);
  Future<void> deleteTemplate(String templateId);

  // Send / schedule
  Future<void> sendNotification(NotificationEntity notification);
  Future<void> scheduleNotification(NotificationEntity notification);

  // Logs
  Future<List<NotificationLog>> getLogs({int limit = 100});
}
