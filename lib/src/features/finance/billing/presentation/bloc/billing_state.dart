import '../../domain/entities/invoice.dart';

abstract class BillingState {}

class BillingInitial extends BillingState {}

class BillingLoading extends BillingState {}

class BillingLoaded extends BillingState {
  final List<Invoice> invoices;
  BillingLoaded(this.invoices);
}

class BillingCreated extends BillingState {
  final Invoice invoice;
  BillingCreated(this.invoice);
}

class BillingError extends BillingState {
  final String message;
  BillingError(this.message);
}
