import '../../domain/entities/invoice.dart';

class InvoiceModel extends Invoice {
  InvoiceModel({
    required super.id,
    required super.customerName,
    required super.customerId,
    required super.date,
    required super.subtotal,
    required super.tax,
    required super.total,
    required super.items,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      customerName: json['customerName'],
      customerId: json['customerId'],
      date: DateTime.parse(json['date']),
      subtotal: json['subtotal'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
      items: (json['items'] as List)
          .map((i) => InvoiceItem(
        description: i['description'],
        quantity: i['quantity'],
        unitPrice: i['unitPrice'].toDouble(),
      ))
          .toList(),
    );
  }
}
