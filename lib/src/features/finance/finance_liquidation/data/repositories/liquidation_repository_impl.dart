// lib/src/features/finance_sub3_liquidation/data/repositories/liquidation_repository_impl.dart

import '../../domain/entities/liquidation.dart';
import '../../domain/repositories/liquidation_repository.dart';
import '../datasources/liquidation_remote_ds.dart';

class LiquidationRepositoryImpl implements LiquidationRepository {
  final LiquidationRemoteDataSource remote;

  LiquidationRepositoryImpl(this.remote);

  @override
  Future<List<Liquidation>> getLiquidations() async {
    return remote.getLiquidations();
  }
}
