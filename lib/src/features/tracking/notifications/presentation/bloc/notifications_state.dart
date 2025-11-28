import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_template.dart';
import '../../domain/entities/notification_log.dart';

class NotificationsState extends Equatable {
  final bool loadingTemplates;
  final List<NotificationTemplate> templates;
  final List<NotificationLog> logs;
  final bool sending;
  final String? error;
  final String? message;

  const NotificationsState({
    this.loadingTemplates = false,
    this.templates = const [],
    this.logs = const [],
    this.sending = false,
    this.error,
    this.message,
  });

  NotificationsState copyWith({
    bool? loadingTemplates,
    List<NotificationTemplate>? templates,
    List<NotificationLog>? logs,
    bool? sending,
    String? error,
    String? message,
  }) {
    return NotificationsState(
      loadingTemplates: loadingTemplates ?? this.loadingTemplates,
      templates: templates ?? this.templates,
      logs: logs ?? this.logs,
      sending: sending ?? this.sending,
      error: error,
      message: message,
    );
  }

  @override
  List<Object?> get props => [loadingTemplates, templates, logs, sending, error ?? '', message ?? ''];
}
