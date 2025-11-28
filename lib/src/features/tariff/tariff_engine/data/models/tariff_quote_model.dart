import '../../domain/entities/tariff_quote.dart';

class TariffQuoteModel extends TariffQuote {
  TariffQuoteModel({
    required super.pesoRealKg,
    required super.pesoVolumetricoKg,
    required super.pesoChargeableKg,
    required super.distanciaFactor,
    required super.service,
    required super.declaredValue,
    required super.baseCost,
    required super.tax,
    required super.total,
  });

  factory TariffQuoteModel.fromJson(Map<String, dynamic> j) => TariffQuoteModel(
    pesoRealKg: (j['pesoRealKg'] as num).toDouble(),
    pesoVolumetricoKg: (j['pesoVolumetricoKg'] as num).toDouble(),
    pesoChargeableKg: (j['pesoChargeableKg'] as num).toDouble(),
    distanciaFactor: (j['distanciaFactor'] as num).toDouble(),
    service: j['service'],
    declaredValue: (j['declaredValue'] as num).toDouble(),
    baseCost: (j['baseCost'] as num).toDouble(),
    tax: (j['tax'] as num).toDouble(),
    total: (j['total'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'pesoRealKg': pesoRealKg,
    'pesoVolumetricoKg': pesoVolumetricoKg,
    'pesoChargeableKg': pesoChargeableKg,
    'distanciaFactor': distanciaFactor,
    'service': service,
    'declaredValue': declaredValue,
    'baseCost': baseCost,
    'tax': tax,
    'total': total,
  };
}
