import 'package:flutter/material.dart';
import '../../domain/entities/tracking_info.dart';
import 'tracking_map_mock.dart';

class TrackingResultCard extends StatelessWidget {
  final TrackingInfo info;
  const TrackingResultCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guía: ${info.waybill}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Estado: ${info.status}'),
                Text('Origen: ${info.origin}  →  Destino: ${info.destination}'),
                Text('Creada: ${info.createdAt}'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Map mock (sustituir por GoogleMap / flutter_map si lo deseas)
        TrackingMapMock(lat: info.lastLat, lng: info.lastLng),

        const SizedBox(height: 12),

        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Eventos de seguimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...info.events.map((e) => ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(e.description),
                  subtitle: Text('${e.location} — ${e.timestamp}'),
                  trailing: Text(e.code),
                )),
              ],
            ),
          ),
        )
      ],
    );
  }
}
