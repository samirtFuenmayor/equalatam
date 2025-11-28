import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/public_tracking_bloc.dart';
import '../bloc/public_tracking_event.dart';

class TrackingSearchForm extends StatefulWidget {
  const TrackingSearchForm({super.key});

  @override
  State<TrackingSearchForm> createState() => _TrackingSearchFormState();
}

class _TrackingSearchFormState extends State<TrackingSearchForm> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search() {
    final val = _ctrl.text.trim();
    if (val.isEmpty) return;
    context.read<PublicTrackingBloc>().add(SearchWaybill(val));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'Número de guía',
                  hintText: 'Ej: WB123456',
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(onPressed: _search, icon: const Icon(Icons.search), label: const Text('Buscar')),
            const SizedBox(width: 8),
            TextButton(onPressed: () => context.read<PublicTrackingBloc>().add(ClearSearch()), child: const Text('Limpiar')),
          ],
        ),
      ),
    );
  }
}
