import 'package:flutter/material.dart';
import '../../data/models/financial_report_model.dart';

class FinancialReportsTable extends StatelessWidget {
  final FinancialReportModel report;

  const FinancialReportsTable({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _kpis(),
        const SizedBox(height: 20),
        _table(),
      ],
    );
  }

  Widget _kpis() {
    return Wrap(
      spacing: 20,
      children: [
        _kpi("Ingresos Totales", report.ingresosTotales),
        _kpi("Egresos Totales", report.egresosTotales),
        _kpi("Utilidad", report.utilidad),
        _kpi("Flujo de Caja", report.flujoCaja),
      ],
    );
  }

  Widget _kpi(String title, double value) {
    return Card(
      elevation: 3,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("\$${value.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _table() {
    return DataTable(
      columns: const [
        DataColumn(label: Text("Sucursal")),
        DataColumn(label: Text("Ingresos")),
        DataColumn(label: Text("Egresos")),
        DataColumn(label: Text("Utilidad")),
      ],
      rows: report.balances
          .map(
            (b) => DataRow(
          cells: [
            DataCell(Text(b.sucursal)),
            DataCell(Text("\$${b.ingresos}")),
            DataCell(Text("\$${b.egresos}")),
            DataCell(Text("\$${b.utilidad}")),
          ],
        ),
      )
          .toList(),
    );
  }
}
