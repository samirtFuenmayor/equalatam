import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/notification_template_model.dart';
import '../models/notification_log_model.dart';

/// Mock datasource: simula envío por Email/SMS y guarda logs en memoria.
class NotificationsRemoteDataSource {
  final _uuid = const Uuid();

  final List<NotificationTemplateModel> _templates = [
    NotificationTemplateModel(
      id: 't_created',
      name: 'Guía creada (email)',
      channel: 'email',
      subject: 'Su guía {{waybill}} ha sido creada',
      body: 'Hola {{customer}}, su envío {{waybill}} fue creado y está en estado {{status}}.',
    ),
    NotificationTemplateModel(
      id: 't_status',
      name: 'Actualización de estado (sms)',
      channel: 'sms',
      subject: '',
      body: 'Guía {{waybill}} ahora: {{status}}',
    ),
  ];

  final List<NotificationLogModel> _logs = [];

  Future<List<NotificationTemplateModel>> fetchTemplates() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_templates);
  }

  Future<void> saveTemplate(NotificationTemplateModel t) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final idx = _templates.indexWhere((e) => e.id == t.id);
    if (idx >= 0) _templates[idx] = t;
    else _templates.add(t);
  }

  Future<void> deleteTemplate(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _templates.removeWhere((t) => t.id == id);
  }

  Future<void> sendNotificationMock(NotificationModel n) async {
    // simulate network + provider response
    await Future.delayed(const Duration(milliseconds: 400));
    final success = n.to.contains('@') || RegExp(r'^\+?\d{7,15}$').hasMatch(n.to);
    final log = NotificationLogModel(
      id: _uuid.v4(),
      notificationId: n.id,
      timestamp: DateTime.now(),
      channel: n.channel,
      to: n.to,
      status: success ? 'sent' : 'failed',
      details: success ? 'Mock provider: accepted' : 'Mock provider: invalid target',
    );
    _logs.insert(0, log);
  }

  Future<List<NotificationLogModel>> fetchLogs({int limit = 100}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _logs.take(limit).toList();
  }

  // schedule mock: simply add a scheduled log item
  Future<void> scheduleNotificationMock(NotificationModel n) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final scheduledLog = NotificationLogModel(
      id: _uuid.v4(),
      notificationId: n.id,
      timestamp: n.scheduledAt,
      channel: n.channel,
      to: n.to,
      status: 'scheduled',
      details: 'Programado para ${n.scheduledAt}',
    );
    _logs.insert(0, scheduledLog);
  }
}
