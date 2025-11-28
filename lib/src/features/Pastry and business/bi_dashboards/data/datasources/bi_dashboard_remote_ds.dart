// lib/src/features/bi_dashboards/data/datasources/bi_dashboard_remote_ds.dart

class BiDashboardRemoteDataSource {
  Future<Map<String, dynamic>> fetchDashboardMetrics() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return {
      "shipments": 1280,
      "revenue": 45200.50,
      "deliveryRate": 0.94,
      "avgTransitTime": 2.4,
      "incidents": 32,
    };
  }
}
