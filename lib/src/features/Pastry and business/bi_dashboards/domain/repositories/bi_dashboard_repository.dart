// lib/src/features/bi_dashboards/domain/repositories/bi_dashboard_repository.dart

import '../entities/bi_dashboard.dart';

abstract class BiDashboardRepository {
  Future<BiDashboard> getMetrics();
}
