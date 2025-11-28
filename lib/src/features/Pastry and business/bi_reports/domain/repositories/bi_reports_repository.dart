// lib/src/features/bi_reports/domain/repositories/bi_reports_repository.dart

import '../entities/bi_report.dart';

abstract class BiReportsRepository {
  Future<List<BiReport>> getReports();
}
