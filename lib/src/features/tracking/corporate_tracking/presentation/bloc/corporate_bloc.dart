import 'package:flutter_bloc/flutter_bloc.dart';
import 'corporate_event.dart';
import 'corporate_state.dart';
import '../../data/repositories/corporate_tracking_repository_impl.dart';

class CorporateBloc extends Bloc<CorporateEvent, CorporateState> {
  final CorporateTrackingRepositoryImpl repository;
  CorporateBloc({required this.repository}) : super(const CorporateState()) {
    on<LoadClientRecords>(_onLoadClient);
    on<UploadCsvEvent>(_onUploadCsv);
    on<SearchWaybillsEvent>(_onSearchWaybills);
  }

  Future<void> _onLoadClient(LoadClientRecords e, Emitter<CorporateState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final recs = await repository.getForClient(e.clientRef);
      emit(state.copyWith(loading: false, records: recs));
    } catch (ex) {
      emit(state.copyWith(loading: false, error: ex.toString()));
    }
  }

  Future<void> _onUploadCsv(UploadCsvEvent e, Emitter<CorporateState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      await repository.uploadCsv(e.csvContent, e.clientRef);
      add(LoadClientRecords(e.clientRef));
      emit(state.copyWith(loading: false, message: 'CSV subido (mock)'));
    } catch (ex) {
      emit(state.copyWith(loading: false, error: ex.toString()));
    }
  }

  Future<void> _onSearchWaybills(SearchWaybillsEvent e, Emitter<CorporateState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final recs = await repository.getByWaybills(e.waybills);
      emit(state.copyWith(loading: false, records: recs));
    } catch (ex) {
      emit(state.copyWith(loading: false, error: ex.toString()));
    }
  }
}
