class FinancialReport {
  final double ingresosTotales;
  final double egresosTotales;
  final double utilidad;
  final double flujoCaja;
  final List<BranchBalance> balances;

  FinancialReport({
    required this.ingresosTotales,
    required this.egresosTotales,
    required this.utilidad,
    required this.flujoCaja,
    required this.balances,
  });
}

class BranchBalance {
  final String sucursal;
  final double ingresos;
  final double egresos;
  final double utilidad;

  BranchBalance({
    required this.sucursal,
    required this.ingresos,
    required this.egresos,
    required this.utilidad,
  });
}
