// lib/src/features/bi_reports/presentation/pages/bi_reports_page.dart

import 'package:flutter/material.dart';
import '../../data/datasources/bi_dashboard_remote_ds.dart';
import '../../data/repositories/bi_reports_repository_impl.dart';
import '../widgets/reports_table.dart';

class BiReportsPage extends StatelessWidget {
  const BiReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = BiReportsRepositoryImpl(BiReportsRemoteDataSource());

    return Scaffold(
      appBar: AppBar(title: const Text("Reportes Personalizables")),
      body: FutureBuilder(
        future: repo.getReports(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ReportsTable(reports: snapshot.data!);
        },
      ),
    );
  }
}
