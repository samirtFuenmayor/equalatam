import 'dart:async';
import '../models/tariff_quote_model.dart';

/// Mock datasource: aplica lógica simple de tarifación.
/// Fórmulas:
/// - pesoVol = (alto * ancho * largo) / 5000 (cm -> kg)
/// - pesoChargeable = max(pesoReal, pesoVolumetrico)
/// - base = tarifaPorKg * pesoChargeable * distanciaFactor
/// - service multiplier: express 1.4, economy 1.0
/// - tax: 12% en ejemplo (ajustable)
class TariffEngineRemoteDS {
  // mock matrices que idealmente vienen del módulo de matrices
  final Map<String, double> _zonaFactor = {
    'local': 1.0,
    'regional': 1.3,
    'national': 1.6,
    'international': 3.0,
  };

  final Map<String, double> _serviceMultiplier = {
    'economy': 1.0,
    'express': 1.4,
  };

  final double tarifaPorKgBase = 2.5; // USD por kg base (mock)

  Future<TariffQuoteModel> calculateQuote({
    required double weightKg,
    required double lengthCm,
    required double widthCm,
    required double heightCm,
    required String originZone,
    required String destZone,
    required String service,
    required double declaredValue,
    bool applyTax = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // peso volumetrico estándar (5000)
    final pesoVol = (lengthCm * widthCm * heightCm) / 5000.0;
    final pesoChargeable = weightKg > pesoVol ? weightKg : pesoVol;

    // distancia factor: promedio entre zonas
    final fOrigin = _zoneFactorFor(originZone);
    final fDest = _zoneFactorFor(destZone);
    final distanciaFactor = (fOrigin + fDest) / 2.0;

    // tarifa por kg: base * distanciaFactor
    final tarifaKg = tarifaPorKgBase * distanciaFactor;

    final serviceMul = _serviceMultiplier[service] ?? 1.0;

    final baseCost = tarifaKg * pesoChargeable * serviceMul;

    // seguro/valor declarado: small percent of declared value (e.g., 0.5%)
    final insurance = declaredValue * 0.005;

    final subtotal = baseCost + insurance;

    final tax = applyTax ? subtotal * 0.12 : 0.0; // 12% mock

    final total = subtotal + tax;

    return TariffQuoteModel(
      pesoRealKg: weightKg,
      pesoVolumetricoKg: double.parse(pesoVol.toStringAsFixed(3)),
      pesoChargeableKg: double.parse(pesoChargeable.toStringAsFixed(3)),
      distanciaFactor: double.parse(distanciaFactor.toStringAsFixed(3)),
      service: service,
      declaredValue: declaredValue,
      baseCost: double.parse(baseCost.toStringAsFixed(2)),
      tax: double.parse(tax.toStringAsFixed(2)),
      total: double.parse(total.toStringAsFixed(2)),
    );
  }

  double _zoneFactorFor(String zone) {
    final z = zone.toLowerCase();
    if (z.contains('local')) return _zonaFactor['local']!;
    if (z.contains('regional')) return _zonaFactor['regional']!;
    if (z.contains('inter') || z.contains('international')) return _zonaFactor['international']!;
    return _zonaFactor['national']!;
  }
}
