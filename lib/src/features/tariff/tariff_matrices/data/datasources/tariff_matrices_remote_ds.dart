import 'dart:async';
import '../models/tariff_matrix_model.dart';

class TariffMatricesRemoteDS {
  final List<TariffMatrixModel> _store = [
    TariffMatrixModel(
      id: 'm_global',
      name: 'Matriz Global',
      scope: 'global',
      tarifaPorKg: 2.5,
      zoneFactors: {'local': 1.0, 'regional': 1.3, 'national': 1.6, 'international': 3.0},
      serviceMultipliers: {'economy': 1.0, 'express': 1.4},
    ),
    TariffMatrixModel(
      id: 'm_client_premium',
      name: 'Matriz Cliente PREMIUM',
      scope: 'client:CUST-1',
      tarifaPorKg: 2.0,
      zoneFactors: {'local': 0.9, 'regional': 1.2, 'national': 1.5, 'international': 2.8},
      serviceMultipliers: {'economy': 1.0, 'express': 1.2},
    ),
  ];

  Future<List<TariffMatrixModel>> fetchMatrices() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_store);
  }

  Future<void> saveMatrix(TariffMatrixModel m) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _store.indexWhere((e) => e.id == m.id);
    if (idx >= 0) _store[idx] = m;
    else _store.insert(0, m);
  }

  Future<void> deleteMatrix(String id) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _store.removeWhere((m) => m.id == id);
  }
}
