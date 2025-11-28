import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/tariff_matrices_repository_impl.dart';
import '../../data/datasources/tariff_matrices_remote_ds.dart';
import '../bloc/matrices_bloc.dart';
import '../bloc/matrices_event.dart';
import '../bloc/matrices_state.dart';
import '../../data/models/tariff_matrix_model.dart';

class MatricesPage extends StatelessWidget {
  const MatricesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TariffMatricesRepositoryImpl(TariffMatricesRemoteDS());
    return BlocProvider(
      create: (_) => MatricesBloc(repository: repo)..add(LoadMatricesEvent()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Matrices Tarifarias')),
        body: BlocBuilder<MatricesBloc, MatricesState>(builder: (context, state) {
          if (state is MatricesLoading) return const Center(child: CircularProgressIndicator());
          if (state is MatricesLoaded) {
            final list = state.matrices.cast<TariffMatrixModel>();
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = list[i];
                return Card(
                  child: ListTile(
                    title: Text(m.name),
                    subtitle: Text('Scope: ${m.scope}\nTarifa/kg: \$${m.tarifaPorKg}'),
                    trailing: Wrap(children: [
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => context.read<MatricesBloc>().add(DeleteMatrixEvent(m.id))),
                    ]),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }
          if (state is MatricesError) return Center(child: Text('Error: ${state.message}'));
          return const SizedBox.shrink();
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // mock: crear una matriz rápida
            final newM = TariffMatrixModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: 'Matriz nueva',
              scope: 'global',
              tarifaPorKg: 2.5,
              zoneFactors: {'local':1.0,'regional':1.3,'national':1.6,'international':3.0},
              serviceMultipliers: {'economy':1.0,'express':1.4},
            );
            context.read<MatricesBloc>().add(SaveMatrixEvent(newM));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matriz creada (mock)')));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
