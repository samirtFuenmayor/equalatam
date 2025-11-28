class TariffQuote {
  final double pesoRealKg;
  final double pesoVolumetricoKg;
  final double pesoChargeableKg;
  final double distanciaFactor; // factor según zona
  final String service; // express | economy
  final double declaredValue;
  final double baseCost;
  final double tax;
  final double total;

  TariffQuote({
    required this.pesoRealKg,
    required this.pesoVolumetricoKg,
    required this.pesoChargeableKg,
    required this.distanciaFactor,
    required this.service,
    required this.declaredValue,
    required this.baseCost,
    required this.tax,
    required this.total,
  });
}
