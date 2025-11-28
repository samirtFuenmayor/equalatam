import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/public_tracking_bloc.dart';
import '../bloc/public_tracking_event.dart';
import '../bloc/public_tracking_state.dart';
import '../widgets/tracking_search_form.dart';
import '../widgets/tracking_result_card.dart';
import '../../data/repositories/public_tracking_repository_impl.dart';
import '../../data/datasources/public_tracking_remote_ds.dart';

/// Página pública de tracking. Puedes exponerla en la web pública.
class PublicTrackingPage extends StatelessWidget {
  const PublicTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyección manual local: si usas service locator, registra allí y usa BlocProvider.value
    final repo = PublicTrackingRepositoryImpl(PublicTrackingRemoteDataSource());

    return BlocProvider(
      create: (_) => PublicTrackingBloc(repository: repo),
      child: Scaffold(
        appBar: AppBar(title: const Text('Consulta de Tracking')),
        body: LayoutBuilder(builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (isDesktop) const SizedBox(width: 260, child: SizedBox()), // aquí puede ir un panel lateral público
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const TrackingSearchForm(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: BlocBuilder<PublicTrackingBloc, PublicTrackingState>(
                          builder: (context, state) {
                            if (state.loading) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (state.error != null) {
                              return Center(child: Text(state.error!));
                            }
                            if (state.result == null) {
                              return const Center(child: Text('Ingrese número de guía para consultar el estado'));
                            }
                            return SingleChildScrollView(
                              child: TrackingResultCard(info: state.result!),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
