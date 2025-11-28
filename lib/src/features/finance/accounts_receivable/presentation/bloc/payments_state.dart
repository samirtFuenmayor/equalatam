import '../../domain/entities/receivable.dart';
import '../../domain/entities/payment.dart';

abstract class PaymentsState {}

class PaymentsInitial extends PaymentsState {}

class PaymentsLoading extends PaymentsState {}

class ReceivablesLoaded extends PaymentsState {
  final List<Receivable> receivables;
  ReceivablesLoaded(this.receivables);
}

class ReceivableLoaded extends PaymentsState {
  final Receivable receivable;
  ReceivableLoaded(this.receivable);
}

class PaymentsLoaded extends PaymentsState {
  final List<Payment> payments;
  PaymentsLoaded(this.payments);
}

class BankExtractLoaded extends PaymentsState {
  final List<Map<String, dynamic>> extracts;
  BankExtractLoaded(this.extracts);
}

class PaymentMadeState extends PaymentsState {
  final Payment payment;
  PaymentMadeState(this.payment);
}

class PaymentsError extends PaymentsState {
  final String message;
  PaymentsError(this.message);
}
