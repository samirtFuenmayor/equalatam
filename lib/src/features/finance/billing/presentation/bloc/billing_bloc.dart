import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/billing_repository.dart';
import 'billing_event.dart';
import 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final BillingRepository repo;

  BillingBloc(this.repo) : super(BillingInitial()) {
    on<LoadInvoices>((event, emit) async {
      emit(BillingLoading());
      try {
        final invoices = await repo.getInvoices();
        emit(BillingLoaded(invoices));
      } catch (e) {
        emit(BillingError(e.toString()));
      }
    });

    on<CreateInvoiceEvent>((event, emit) async {
      emit(BillingLoading());
      try {
        final invoice = await repo.createInvoice(event.invoice);
        emit(BillingCreated(invoice));
      } catch (e) {
        emit(BillingError(e.toString()));
      }
    });
  }
}
