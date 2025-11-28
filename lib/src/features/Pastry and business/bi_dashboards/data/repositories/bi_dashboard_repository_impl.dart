// lib/src/features/bi_dashboards/data/repositories/bi_dashboard_repository_impl.dart

import '../../domain/entities/bi_dashboard.dart';
import '../../domain/repositories/bi_dashboard_repository.dart';
import '../datasources/bi_dashboard_remote_ds.dart';
import '../models/bi_dashboard_model.dart';

class BiDashboardRepositoryImpl implements BiDashboardRepository {
  final BiDashboardRemoteDataSource remote;

  BiDashboardRepositoryImpl(this.remote);

  @override
  Future<BiDashboard> getMetrics() async {
    final data = await remote.fetchDashboardMetrics();
    return BiDashboardModel.fromJson(data);
  }
}
