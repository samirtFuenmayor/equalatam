import '../../domain/entities/tariff_matrix.dart';

class TariffMatrixModel extends TariffMatrix {
  TariffMatrixModel({
    required super.id,
    required super.name,
    required super.scope,
    required super.tarifaPorKg,
    required super.zoneFactors,
    required super.serviceMultipliers,
  });

  factory TariffMatrixModel.fromJson(Map<String, dynamic> j) => TariffMatrixModel(
    id: j['id'],
    name: j['name'],
    scope: j['scope'],
    tarifaPorKg: (j['tarifaPorKg'] as num).toDouble(),
    zoneFactors: Map<String, double>.from((j['zoneFactors'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()))),
    serviceMultipliers: Map<String, double>.from((j['serviceMultipliers'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()))),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'scope': scope,
    'tarifaPorKg': tarifaPorKg,
    'zoneFactors': zoneFactors,
    'serviceMultipliers': serviceMultipliers,
  };
}
