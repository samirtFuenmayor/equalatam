import 'package:flutter/material.dart';

class ZoneCard extends StatelessWidget {
  final String name;
  final String cities;
  final VoidCallback onEdit;

  const ZoneCard({
    super.key,
    required this.name,
    required this.cities,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.map),
        title: Text(name),
        subtitle: Text('Ciudades: $cities'),
        trailing: ElevatedButton(onPressed: onEdit, child: const Text('Editar')),
      ),
    );
  }
}
