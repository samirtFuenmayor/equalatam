import 'package:flutter/material.dart';

class ShipmentHistoryTable extends StatelessWidget {
  const ShipmentHistoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Guía")),
          DataColumn(label: Text("Fecha")),
          DataColumn(label: Text("Estado")),
          DataColumn(label: Text("Destino")),
        ],
        rows: List.generate(
          8,
              (i) => DataRow(cells: [
            DataCell(Text("WB00$i")),
            DataCell(Text("12/0${i + 1}/2025")),
            DataCell(Text(i % 2 == 0 ? "Entregado" : "En tránsito")),
            DataCell(Text("Ciudad $i")),
          ]),
        ),
      ),
    );
  }
}
