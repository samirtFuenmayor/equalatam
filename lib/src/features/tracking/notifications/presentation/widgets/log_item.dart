import 'package:flutter/material.dart';
import '../../domain/entities/notification_log.dart';

class LogItem extends StatelessWidget {
  final NotificationLog log;
  const LogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final ok = log.status == 'sent';
    return ListTile(
      leading: Icon(ok ? Icons.check_circle : Icons.error, color: ok ? Colors.green : Colors.red),
      title: Text('${log.channel.toUpperCase()} → ${log.to}'),
      subtitle: Text('${log.timestamp} — ${log.details}'),
    );
  }
}
