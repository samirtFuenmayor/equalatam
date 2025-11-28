import 'package:flutter/material.dart';

class ScanList extends StatelessWidget {
  const ScanList({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(12, (i) => {
      'code': 'WB00${i + 11}',
      'point': i % 3 == 0 ? 'Recepción' : (i % 3 == 1 ? 'Salida Hub' : 'Llegada Sucursal'),
      'date': '2025-11-${10 + i} 10:${i}0'
    });

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final it = items[i];
          return ListTile(
            leading: const Icon(Icons.qr_code),
            title: Text('${it['code']} • ${it['point']}'),
            subtitle: Text('${it['date']}'),
            trailing: Text(i % 2 == 0 ? 'OK' : 'Pendiente', style: TextStyle(color: i % 2 == 0 ? Colors.green : Colors.orange)),
          );
        },
      ),
    );
  }
}
