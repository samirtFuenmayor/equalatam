// lib/src/features/finance_sub3_liquidation/domain/repositories/liquidation_repository.dart

import '../entities/liquidation.dart';

abstract class LiquidationRepository {
  Future<List<Liquidation>> getLiquidations();
}
