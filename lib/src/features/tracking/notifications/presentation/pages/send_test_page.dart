import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../../domain/entities/notification.dart';

class SendTestPage extends StatefulWidget {
  const SendTestPage({super.key});

  @override
  State<SendTestPage> createState() => _SendTestPageState();
}

class _SendTestPageState extends State<SendTestPage> {
  final _form = GlobalKey<FormState>();
  final _channel = TextEditingController(text: 'email');
  final _to = TextEditingController(text: 'cliente@demo.com');
  final _subject = TextEditingController(text: 'Prueba de notificación');
  final _body = TextEditingController(text: 'Hola {{customer}}, su guía {{waybill}} cambió a {{status}}');
  DateTime _scheduledAt = DateTime.now();

  @override
  void dispose() {
    _channel.dispose();
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _sendNow() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final n = NotificationEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      channel: _channel.text,
      to: _to.text,
      subject: _subject.text,
      body: _body.text,
      scheduledAt: DateTime.now(),
      status: 'pending',
    );
    context.read<NotificationsBloc>().add(SendNotificationEvent(n));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Envio simulado (mock)')));
  }

  void _schedule() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final n = NotificationEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      channel: _channel.text,
      to: _to.text,
      subject: _subject.text,
      body: _body.text,
      scheduledAt: _scheduledAt,
      status: 'scheduled',
    );
    context.read<NotificationsBloc>().add(ScheduleNotificationEvent(n));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Programado (mock)')));
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(context: context, initialDate: _scheduledAt, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (dt == null) return;
    final tm = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (tm == null) return;
    setState(() => _scheduledAt = DateTime(dt.year, dt.month, dt.day, tm.hour, tm.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar Prueba / Programar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(controller: _channel, decoration: const InputDecoration(labelText: 'Canal (email|sms)'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _to, decoration: const InputDecoration(labelText: 'Para (email o teléfono)'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              TextFormField(controller: _subject, decoration: const InputDecoration(labelText: 'Asunto (email)'), ),
              TextFormField(controller: _body, decoration: const InputDecoration(labelText: 'Cuerpo'), maxLines: 4),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton(onPressed: _sendNow, child: const Text('Enviar ahora (mock)')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _pickDate, child: const Text('Programar fecha')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _schedule, child: const Text('Guardar programación (mock)')),
              ]),
              const SizedBox(height: 12),
              Text('Programado para: $_scheduledAt'),
            ],
          ),
        ),
      ),
    );
  }
}
