import '../../domain/entities/financial_report.dart';

class FinancialReportModel extends FinancialReport {
  FinancialReportModel({
    required super.ingresosTotales,
    required super.egresosTotales,
    required super.utilidad,
    required super.flujoCaja,
    required super.balances,
  });

  factory FinancialReportModel.fromJson(Map<String, dynamic> json) {
    return FinancialReportModel(
      ingresosTotales: json['ingresosTotales'],
      egresosTotales: json['egresosTotales'],
      utilidad: json['utilidad'],
      flujoCaja: json['flujoCaja'],
      balances: (json["balances"] as List)
          .map((e) => BranchBalance(
        sucursal: e["sucursal"],
        ingresos: e["ingresos"],
        egresos: e["egresos"],
        utilidad: e["utilidad"],
      ))
          .toList(),
    );
  }
}
