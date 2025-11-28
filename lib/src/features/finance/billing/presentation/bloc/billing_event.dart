import 'package:equalatam/src/features/finance/billing/domain/entities/invoice.dart';

abstract class BillingEvent {}

class LoadInvoices extends BillingEvent {}

class CreateInvoiceEvent extends BillingEvent {
  final Invoice invoice;
  CreateInvoiceEvent(this.invoice);
}
