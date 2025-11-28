import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/tariff_matrices_repository_impl.dart';
import 'matrices_event.dart';
import 'matrices_state.dart';

class MatricesBloc extends Bloc<MatricesEvent, MatricesState> {
  final TariffMatricesRepositoryImpl repository;

  MatricesBloc({required this.repository}) : super(MatricesInitial()) {
    on<LoadMatricesEvent>(_onLoad);
    on<SaveMatrixEvent>(_onSave);
    on<DeleteMatrixEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadMatricesEvent e, Emitter emit) async {
    emit(MatricesLoading());
    try {
      final ms = await repository.getMatrices();
      emit(MatricesLoaded(ms));
    } catch (ex) {
      emit(MatricesError(ex.toString()));
    }
  }

  Future<void> _onSave(SaveMatrixEvent e, Emitter emit) async {
    try {
      await repository.saveMatrix(e.matrix);
      add(LoadMatricesEvent());
    } catch (ex) {
      emit(MatricesError(ex.toString()));
    }
  }

  Future<void> _onDelete(DeleteMatrixEvent e, Emitter emit) async {
    try {
      await repository.deleteMatrix(e.id);
      add(LoadMatricesEvent());
    } catch (ex) {
      emit(MatricesError(ex.toString()));
    }
  }
}
