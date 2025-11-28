import 'package:flutter/material.dart';

class ExceptionCard extends StatelessWidget {
  final String title;
  final String details;
  final VoidCallback onResolve;

  const ExceptionCard({super.key, required this.title, required this.details, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(details),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {}, child: const Text('Ver historial')),
                ElevatedButton(onPressed: onResolve, child: const Text('Marcar resuelto')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
