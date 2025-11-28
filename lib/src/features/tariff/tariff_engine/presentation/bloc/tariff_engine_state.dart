import '../../domain/entities/tariff_quote.dart';

abstract class TariffEngineState {}

class TariffEngineInitial extends TariffEngineState {}

class TariffEngineLoading extends TariffEngineState {}

class TariffEngineLoaded extends TariffEngineState {
  final TariffQuote quote;
  TariffEngineLoaded(this.quote);
}

class TariffEngineError extends TariffEngineState {
  final String message;
  TariffEngineError(this.message);
}
