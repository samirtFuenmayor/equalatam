// Receivable entity
class Receivable {
  final String id;
  final String invoiceId;
  final String customerName;
  final String customerId;
  final DateTime dueDate;
  final double amount;
  final double paid;
  final String status; // pending, partial, paid, overdue

  Receivable({
    required this.id,
    required this.invoiceId,
    required this.customerName,
    required this.customerId,
    required this.dueDate,
    required this.amount,
    required this.paid,
    required this.status,
  });

  double get balance => (amount - paid);
}
