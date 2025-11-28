// lib/src/features/bi_reports/data/repositories/bi_reports_repository_impl.dart

import '../../domain/entities/bi_report.dart';
import '../../domain/repositories/bi_reports_repository.dart';
import '../datasources/bi_dashboard_remote_ds.dart';
import '../models/bi_report_model.dart';

class BiReportsRepositoryImpl implements BiReportsRepository {
  final BiReportsRemoteDataSource remote;

  BiReportsRepositoryImpl(this.remote);

  @override
  Future<List<BiReport>> getReports() async {
    final list = await remote.fetchReports();
    return list.map((e) => BiReportModel.fromJson(e)).toList();
  }
}
