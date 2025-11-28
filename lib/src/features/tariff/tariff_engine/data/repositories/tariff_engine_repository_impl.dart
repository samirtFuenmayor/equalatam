import '../../domain/entities/tariff_quote.dart';
import '../../domain/repositories/tariff_engine_repository.dart';
import '../datasources/tariff_engine_remote_ds.dart';
import '../models/tariff_quote_model.dart';

class TariffEngineRepositoryImpl implements TariffEngineRepository {
  final TariffEngineRemoteDS remote;
  TariffEngineRepositoryImpl(this.remote);

  @override
  Future<TariffQuote> getQuote({
    required double weightKg,
    required double lengthCm,
    required double widthCm,
    required double heightCm,
    required String originZone,
    required String destZone,
    required String service,
    required double declaredValue,
  }) {
    return remote.calculateQuote(
      weightKg: weightKg,
      lengthCm: lengthCm,
      widthCm: widthCm,
      heightCm: heightCm,
      originZone: originZone,
      destZone: destZone,
      service: service,
      declaredValue: declaredValue,
    );
  }
}
