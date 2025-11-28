abstract class TariffEngineEvent {}

class CalculateQuoteEvent extends TariffEngineEvent {
  final double weightKg;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final String originZone;
  final String destZone;
  final String service;
  final double declaredValue;

  CalculateQuoteEvent({
    required this.weightKg,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.originZone,
    required this.destZone,
    required this.service,
    required this.declaredValue,
  });
}
