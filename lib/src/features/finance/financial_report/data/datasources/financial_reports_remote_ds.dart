import 'package:dio/dio.dart';
import '../models/financial_report_model.dart';

class FinancialReportsRemoteDS {
  final Dio dio = Dio();
  final String baseUrl = "https://api.tuservidor.com/finanzas/reportes";

  Future<FinancialReportModel> getGeneralReport() async {
    final response = await dio.get("$baseUrl/general");
    return FinancialReportModel.fromJson(response.data);
  }

  Future<FinancialReportModel> getSucursalReport(String id) async {
    final response = await dio.get("$baseUrl/sucursal/$id");
    return FinancialReportModel.fromJson(response.data);
  }
}
