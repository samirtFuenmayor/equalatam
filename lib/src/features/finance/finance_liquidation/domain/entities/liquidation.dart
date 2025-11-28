// lib/src/features/finance_sub3_liquidation/domain/entities/liquidation.dart

import 'package:equatable/equatable.dart';

class Liquidation extends Equatable {
  final String id;
  final String branchOrigin;
  final String branchDestination;
  final double amount;
  final int shipmentsCount;
  final DateTime date;

  const Liquidation({
    required this.id,
    required this.branchOrigin,
    required this.branchDestination,
    required this.amount,
    required this.shipmentsCount,
    required this.date,
  });

  @override
  List<Object?> get props => [
    id,
    branchOrigin,
    branchDestination,
    amount,
    shipmentsCount,
    date,
  ];
}
