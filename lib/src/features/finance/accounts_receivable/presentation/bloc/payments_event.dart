import '../../domain/entities/receivable.dart';
import '../../domain/entities/payment.dart';

abstract class PaymentsEvent {}

class LoadReceivablesEvent extends PaymentsEvent {
  final String? status;
  LoadReceivablesEvent({this.status});
}

class LoadReceivableByIdEvent extends PaymentsEvent {
  final String id;
  LoadReceivableByIdEvent(this.id);
}

class MakePaymentEvent extends PaymentsEvent {
  final Payment payment;
  MakePaymentEvent(this.payment);
}

class LoadPaymentsEvent extends PaymentsEvent {}

class LoadBankExtractEvent extends PaymentsEvent {}

class ReconcileEvent extends PaymentsEvent {
  final String paymentId;
  final String extractId;
  ReconcileEvent(this.paymentId, this.extractId);
}
