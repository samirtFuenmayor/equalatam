import 'package:flutter_bloc/flutter_bloc.dart';
import 'public_tracking_event.dart';
import 'public_tracking_state.dart';
import '../../domain/repositories/public_tracking_repository.dart';

class PublicTrackingBloc extends Bloc<PublicTrackingEvent, PublicTrackingState> {
  final PublicTrackingRepository repository;

  PublicTrackingBloc({required this.repository}) : super(const PublicTrackingState()) {
    on<SearchWaybill>(_onSearch);
    on<ClearSearch>((event, emit) => emit(const PublicTrackingState()));
  }

  Future<void> _onSearch(SearchWaybill event, Emitter<PublicTrackingState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final res = await repository.getByWaybill(event.waybill.trim());
      if (res == null) {
        emit(state.copyWith(loading: false, result: null, error: 'Guía no encontrada'));
      } else {
        emit(state.copyWith(loading: false, result: res, error: null));
      }
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
