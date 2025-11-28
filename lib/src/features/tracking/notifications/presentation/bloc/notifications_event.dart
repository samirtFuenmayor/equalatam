import 'package:equatable/equatable.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_template.dart';

abstract class NotificationsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTemplates extends NotificationsEvent {}

class CreateTemplate extends NotificationsEvent {
  final NotificationTemplate template;
  CreateTemplate(this.template);
  @override
  List<Object?> get props => [template];
}

class DeleteTemplateEvent extends NotificationsEvent {
  final String templateId;
  DeleteTemplateEvent(this.templateId);
  @override
  List<Object?> get props => [templateId];
}

class SendNotificationEvent extends NotificationsEvent {
  final NotificationEntity notification;
  SendNotificationEvent(this.notification);
  @override
  List<Object?> get props => [notification];
}

class ScheduleNotificationEvent extends NotificationsEvent {
  final NotificationEntity notification;
  ScheduleNotificationEvent(this.notification);
  @override
  List<Object?> get props => [notification];
}

class LoadLogsEvent extends NotificationsEvent {}
