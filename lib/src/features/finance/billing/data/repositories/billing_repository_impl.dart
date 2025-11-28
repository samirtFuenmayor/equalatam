import 'package:dio/dio.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/billing_repository.dart';
import '../models/invoice_model.dart';

class BillingRepositoryImpl implements BillingRepository {
  final Dio client;

  BillingRepositoryImpl(this.client);

  @override
  Future<Invoice> createInvoice(Invoice invoice) async {
    final response = await client.post('/billing/create', data: {
      "id": invoice.id,
      "customerName": invoice.customerName,
      "customerId": invoice.customerId,
      "date": invoice.date.toIso8601String(),
      "subtotal": invoice.subtotal,
      "tax": invoice.tax,
      "total": invoice.total,
      "items": invoice.items.map((i) {
        return {
          "description": i.description,
          "quantity": i.quantity,
          "unitPrice": i.unitPrice,
        };
      }).toList(),
    });

    return InvoiceModel.fromJson(response.data);
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    final response = await client.get('/billing/list');
    return (response.data as List).map((e) => InvoiceModel.fromJson(e)).toList();
  }

  @override
  Future<Invoice> getInvoiceById(String id) async {
    final response = await client.get('/billing/$id');
    return InvoiceModel.fromJson(response.data);
  }
}
