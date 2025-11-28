import 'package:flutter/material.dart';
import '../../data/models/financial_report_model.dart';
import '../widgets/financial_reports_table.dart';
import '../../data/repositories/financial_reports_repository_impl.dart';
import '../../data/datasources/financial_reports_remote_ds.dart';

class FinancialReportsPage extends StatefulWidget {
  const FinancialReportsPage({super.key});

  @override
  State<FinancialReportsPage> createState() => _FinancialReportsPageState();
}

class _FinancialReportsPageState extends State<FinancialReportsPage> {
  final repository =
  FinancialReportsRepositoryImpl(FinancialReportsRemoteDS());

  FinancialReportModel? report;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final data = await repository.getGeneralReport();
    setState(() {
      report = data as FinancialReportModel;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reportes Financieros")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FinancialReportsTable(report: report!),
    );
  }
}
