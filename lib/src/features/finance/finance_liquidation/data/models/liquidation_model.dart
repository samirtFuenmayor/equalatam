// lib/src/features/finance_sub3_liquidation/data/models/liquidation_model.dart

import '../../domain/entities/liquidation.dart';

class LiquidationModel extends Liquidation {
  const LiquidationModel({
    required super.id,
    required super.branchOrigin,
    required super.branchDestination,
    required super.amount,
    required super.shipmentsCount,
    required super.date,
  });

  factory LiquidationModel.fromJson(Map<String, dynamic> json) {
    return LiquidationModel(
      id: json["id"],
      branchOrigin: json["branchOrigin"],
      branchDestination: json["branchDestination"],
      amount: (json["amount"] as num).toDouble(),
      shipmentsCount: json["shipmentsCount"],
      date: DateTime.parse(json["date"]),
    );
  }
}
