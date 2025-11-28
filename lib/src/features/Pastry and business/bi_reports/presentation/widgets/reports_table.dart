// lib/src/features/bi_reports/presentation/widgets/reports_table.dart

import 'package:flutter/material.dart';
import '../../domain/entities/bi_report.dart';

class ReportsTable extends StatelessWidget {
  final List<BiReport> reports;

  const ReportsTable({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text("Tipo")),
        DataColumn(label: Text("Valor")),
        DataColumn(label: Text("Cantidad")),
      ],
      rows: reports.map((r) {
        return DataRow(cells: [
          DataCell(Text(r.type)),
          DataCell(Text(r.value)),
          DataCell(Text("${r.count}")),
        ]);
      }).toList(),
    );
  }
}
