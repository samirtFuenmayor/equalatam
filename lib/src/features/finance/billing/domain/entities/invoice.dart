class Invoice {
  final String id;
  final String customerName;
  final String customerId;
  final DateTime date;
  final double subtotal;
  final double tax;
  final double total;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.customerName,
    required this.customerId,
    required this.date,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.items,
  });
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}
