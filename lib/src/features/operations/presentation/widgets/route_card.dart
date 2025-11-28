import 'package:flutter/material.dart';

class RouteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const RouteCard({super.key, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.local_shipping),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(onPressed: onTap, child: const Text('Asignar')),
      ),
    );
  }
}
