import 'package:flutter/material.dart';

class HubCard extends StatelessWidget {
  final String title;
  final String capacity;
  final String region;
  final VoidCallback onEdit;

  const HubCard({
    super.key,
    required this.title,
    required this.capacity,
    required this.region,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.home_work),
        title: Text(title),
        subtitle: Text('Capacidad: $capacity\nRegión: $region'),
        isThreeLine: true,
        trailing: OutlinedButton(onPressed: onEdit, child: const Text('Editar')),
      ),
    );
  }
}
