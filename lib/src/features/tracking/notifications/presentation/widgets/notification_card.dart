import 'package:flutter/material.dart';
import '../../domain/entities/notification.dart';

class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onSend;

  const NotificationCard({super.key, required this.notification, this.onSend});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text('${notification.channel.toUpperCase()} → ${notification.to}'),
        subtitle: Text('${notification.subject}\nProgramada: ${notification.scheduledAt}'),
        trailing: ElevatedButton(onPressed: onSend, child: const Text('Enviar')),
        isThreeLine: true,
      ),
    );
  }
}
