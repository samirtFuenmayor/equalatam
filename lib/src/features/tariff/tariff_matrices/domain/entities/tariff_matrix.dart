class TariffMatrix {
  final String id;
  final String name;
  final String scope; // e.g., global | client:CUST-1 | branch:Quito
  final double tarifaPorKg; // base USD/kg
  final Map<String, double> zoneFactors; // e.g., {'local':1.0,'regional':1.3}
  final Map<String, double> serviceMultipliers; // {'economy':1.0,'express':1.4}

  TariffMatrix({
    required this.id,
    required this.name,
    required this.scope,
    required this.tarifaPorKg,
    required this.zoneFactors,
    required this.serviceMultipliers,
  });
}
