import 'package:flutter/material.dart';
import '../../domain/entities/shipment.dart';

class BulkListWidget extends StatelessWidget {
  final List<CorporateTrackingRecord> records;
  const BulkListWidget({super.key, required this.records});

  @override Widget build(BuildContext context) {
    if (records.isEmpty) return const Center(child: Text('No hay registros'));
    return Card(elevation:2, child: ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) {
        final r = records[i];
        return ListTile(
          title: Text(r.waybill),
          subtitle: Text('${r.origin} → ${r.destination}\nStatus: ${r.status}'),
          trailing: Text('${r.updatedAt.toLocal()}'.split('.')[0]),
          isThreeLine: true,
        );
      },
    ));
  }
}
