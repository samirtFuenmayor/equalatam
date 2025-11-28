// lib/src/features/bi_dashboards/presentation/pages/bi_dashboard_page.dart

import 'package:flutter/material.dart';
import '../../data/datasources/bi_dashboard_remote_ds.dart';
import '../../data/repositories/bi_dashboard_repository_impl.dart';
import '../widgets/kpi_cards.dart';

class BiDashboardPage extends StatelessWidget {
  const BiDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = BiDashboardRepositoryImpl(BiDashboardRemoteDataSource());

    return FutureBuilder(
      future: repo.getMetrics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final metrics = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text("Dashboard Ejecutivo")),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: KpiCards(metrics: metrics),
          ),
        );
      },
    );
  }
}
