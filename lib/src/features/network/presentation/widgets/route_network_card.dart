import 'package:flutter/material.dart';

class RouteNetworkCard extends StatelessWidget {
  final String routeName;
  final String origin;
  final String destination;
  final VoidCallback onEdit;

  const RouteNetworkCard({
    super.key,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.alt_route),
        title: Text(routeName),
        subtitle: Text('Origen: $origin\nDestino: $destination'),
        isThreeLine: true,
        trailing: OutlinedButton(
          onPressed: onEdit,
          child: const Text('Editar'),
        ),
      ),
    );
  }
}
