import '../../domain/entities/tariff_matrix.dart';

abstract class TariffMatricesRepository {
  Future<List<TariffMatrix>> getMatrices();
  Future<void> saveMatrix(TariffMatrix matrix);
  Future<void> deleteMatrix(String id);
}
