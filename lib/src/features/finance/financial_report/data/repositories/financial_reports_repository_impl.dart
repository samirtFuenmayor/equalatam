import '../../domain/entities/financial_report.dart';
import '../../domain/repositories/financial_reports_repository.dart';
import '../datasources/financial_reports_remote_ds.dart';

class FinancialReportsRepositoryImpl implements FinancialReportsRepository {
  final FinancialReportsRemoteDS datasource;

  FinancialReportsRepositoryImpl(this.datasource);

  @override
  Future<FinancialReport> getGeneralReport() {
    return datasource.getGeneralReport();
  }

  @override
  Future<FinancialReport> getSucursalReport(String id) {
    return datasource.getSucursalReport(id);
  }
}
