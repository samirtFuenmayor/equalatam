import '../entities/tariff_quote.dart';

abstract class TariffEngineRepository {
  Future<TariffQuote> getQuote({
    required double weightKg,
    required double lengthCm,
    required double widthCm,
    required double heightCm,
    required String originZone,
    required String destZone,
    required String service,
    required double declaredValue,
  });
}
