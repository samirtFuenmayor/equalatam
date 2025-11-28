import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/payments_repository.dart';
import 'payments_event.dart';
import 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final PaymentsRepository repository;
  PaymentsBloc(this.repository) : super(PaymentsInitial()) {
    on<LoadReceivablesEvent>(_onLoadReceivables);
    on<LoadReceivableByIdEvent>(_onLoadReceivableById);
    on<MakePaymentEvent>(_onMakePayment);
    on<LoadPaymentsEvent>(_onLoadPayments);
    on<LoadBankExtractEvent>(_onLoadBankExtract);
    on<ReconcileEvent>(_onReconcile);
  }

  Future<void> _onLoadReceivables(LoadReceivablesEvent e, Emitter emit) async {
    emit(PaymentsLoading());
    try {
      final r = await repository.getReceivables(status: e.status);
      emit(ReceivablesLoaded(r));
    } catch (ex) {
      emit(PaymentsError(ex.toString()));
    }
  }

  Future<void> _onLoadReceivableById(LoadReceivableByIdEvent e, Emitter emit) async {
    emit(PaymentsLoading());
    try {
      final r = await repository.getReceivableById(e.id);
      emit(ReceivableLoaded(r));
    } catch (ex) {
      emit(PaymentsError(ex.toString()));
    }
  }

  Future<void> _onMakePayment(MakePaymentEvent e, Emitter emit) async {
    emit(PaymentsLoading());
    try {
      final p = await repository.createPayment(e.payment);
      emit(PaymentMadeState(p));
      add(LoadReceivablesEvent()); // refresh list
      add(LoadPaymentsEvent());
    } catch (ex) {
      emit(PaymentsError(ex.toString()));
    }
  }

  Future<void> _onLoadPayments(LoadPaymentsEvent e, Emitter emit) async {
    emit(PaymentsLoading());
    try {
      final ps = await repository.getPayments();
      emit(PaymentsLoaded(ps));
    } catch (ex) {
      emit(PaymentsError(ex.toString()));
    }
  }

  Future<void> _onLoadBankExtract(LoadBankExtractEvent e, Emitter emit) async {
    emit(PaymentsLoading());
    try {
      final ex = await repository.getBankExtract();
      emit(BankExtractLoaded(ex));
    } catch (er) {
      emit(PaymentsError(er.toString()));
    }
  }

  Future<void> _onReconcile(ReconcileEvent e, Emitter emit) async {
    emit(PaymentsLoading());
    try {
      await repository.reconcilePayment(e.paymentId, e.extractId);
      emit(PaymentsLoaded(await repository.getPayments()));
      emit(BankExtractLoaded(await repository.getBankExtract()));
    } catch (er) {
      emit(PaymentsError(er.toString()));
    }
  }
}
