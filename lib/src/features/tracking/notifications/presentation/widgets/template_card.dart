import 'package:flutter/material.dart';
import '../../domain/entities/notification_template.dart';

class TemplateCard extends StatelessWidget {
  final NotificationTemplate template;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TemplateCard({super.key, required this.template, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(template.name),
        subtitle: Text('Canal: ${template.channel}\n${template.subject}\n${template.body}'),
        trailing: Wrap(spacing: 6, children: [
          OutlinedButton(onPressed: onEdit, child: const Text('Editar')),
          ElevatedButton(onPressed: onDelete, child: const Text('Eliminar')),
        ]),
        isThreeLine: true,
      ),
    );
  }
}
