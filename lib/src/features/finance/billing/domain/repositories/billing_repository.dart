import '../entities/invoice.dart';

abstract class BillingRepository {
  Future<Invoice> createInvoice(Invoice invoice);
  Future<List<Invoice>> getInvoices();
  Future<Invoice> getInvoiceById(String id);
}
