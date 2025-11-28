// lib/src/features/bi_reports/data/datasources/bi_reports_remote_ds.dart

class BiReportsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchReports() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      {"type": "Sucursal", "value": "Quito Norte", "count": 230},
      {"type": "Sucursal", "value": "Guayaquil Centro", "count": 190},
      {"type": "Rentabilidad", "value": "Express", "count": 80},
      {"type": "Tendencia", "value": "Creciente", "count": 12},
      {"type": "SLA", "value": "94%", "count": 1},
    ];
  }
}
