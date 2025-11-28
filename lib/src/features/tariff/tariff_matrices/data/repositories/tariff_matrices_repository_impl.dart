import '../../domain/entities/tariff_matrix.dart';
import '../../domain/repositories/tariff_matrices_repository.dart';
import '../datasources/tariff_matrices_remote_ds.dart';
import '../models/tariff_matrix_model.dart';

class TariffMatricesRepositoryImpl implements TariffMatricesRepository {
  final TariffMatricesRemoteDS remote;
  TariffMatricesRepositoryImpl(this.remote);

  @override
  Future<List<TariffMatrix>> getMatrices() async {
    final ms = await remote.fetchMatrices();
    return ms.cast<TariffMatrixModel>();
  }

  @override
  Future<void> saveMatrix(TariffMatrix matrix) async {
    final m = matrix is TariffMatrixModel ? matrix : TariffMatrixModel(
      id: matrix.id,
      name: matrix.name,
      scope: matrix.scope,
      tarifaPorKg: matrix.tarifaPorKg,
      zoneFactors: matrix.zoneFactors,
      serviceMultipliers: matrix.serviceMultipliers,
    );
    await remote.saveMatrix(m);
  }

  @override
  Future<void> deleteMatrix(String id) async {
    await remote.deleteMatrix(id);
  }
}
