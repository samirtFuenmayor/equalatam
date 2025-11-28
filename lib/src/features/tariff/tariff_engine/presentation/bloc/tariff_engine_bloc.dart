import 'package:flutter_bloc/flutter_bloc.dart';
import 'tariff_engine_event.dart';
import 'tariff_engine_state.dart';
import '../../data/repositories/tariff_engine_repository_impl.dart';

class TariffEngineBloc extends Bloc<TariffEngineEvent, TariffEngineState> {
  final TariffEngineRepositoryImpl repository;

  TariffEngineBloc({required this.repository}) : super(TariffEngineInitial()) {
    on<CalculateQuoteEvent>(_onCalculate);
  }

  Future<void> _onCalculate(CalculateQuoteEvent e, Emitter emit) async {
    emit(TariffEngineLoading());
    try {
      final q = await repository.getQuote(
        weightKg: e.weightKg,
        lengthCm: e.lengthCm,
        widthCm: e.widthCm,
        heightCm: e.heightCm,
        originZone: e.originZone,
        destZone: e.destZone,
        service: e.service,
        declaredValue: e.declaredValue,
      );
      emit(TariffEngineLoaded(q));
    } catch (ex) {
      emit(TariffEngineError(ex.toString()));
    }
  }
}
