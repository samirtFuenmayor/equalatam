import 'package:flutter/material.dart';

/// Mock de mapa para UI. Cambia por un widget real (GoogleMap, flutter_map) cuando integres la API.
/// Si hay coordenadas, las muestra; si no, muestra placeholder.
class TrackingMapMock extends StatelessWidget {
  final double? lat;
  final double? lng;
  const TrackingMapMock({super.key, this.lat, this.lng});

  @override
  Widget build(BuildContext context) {
    final isCoords = lat != null && lng != null;
    return Card(
      elevation: 2,
      child: SizedBox(
        height: 220,
        child: Center(
          child: isCoords
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map, size: 40),
              const SizedBox(height: 8),
              Text('Última posición aproximada'),
              const SizedBox(height: 6),
              Text('Lat: ${lat!.toStringAsFixed(6)}, Lng: ${lng!.toStringAsFixed(6)}'),
              const SizedBox(height: 6),
              const Text('(Reemplaza este mock con un mapa real)'),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.map_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Ubicación no disponible'),
            ],
          ),
        ),
      ),
    );
  }
}
