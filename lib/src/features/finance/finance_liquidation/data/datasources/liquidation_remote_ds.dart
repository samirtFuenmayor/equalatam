// lib/src/features/finance_sub3_liquidation/data/datasources/liquidation_remote_ds.dart

import '../models/liquidation_model.dart';

class LiquidationRemoteDataSource {
  Future<List<LiquidationModel>> getLiquidations() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      LiquidationModel(
        id: "LQD001",
        branchOrigin: "Sucursal Quito",
        branchDestination: "Sucursal Guayaquil",
        amount: 1250.50,
        shipmentsCount: 42,
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      LiquidationModel(
        id: "LQD002",
        branchOrigin: "Sucursal Cuenca",
        branchDestination: "Sucursal Quito",
        amount: 980.25,
        shipmentsCount: 30,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
