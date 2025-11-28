import '../entities/financial_report.dart';

abstract class FinancialReportsRepository {
  Future<FinancialReport> getGeneralReport();
  Future<FinancialReport> getSucursalReport(String id);
}
