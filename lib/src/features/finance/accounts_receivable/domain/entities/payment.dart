// Payment entity
class Payment {
  final String id;
  final String receivableId;
  final String method; // card, transfer, cash, paypal
  final String reference; // tx id / voucher
  final DateTime date;
  final double amount;
  final String status; // pending, completed, failed

  Payment({
    required this.id,
    required this.receivableId,
    required this.method,
    required this.reference,
    required this.date,
    required this.amount,
    required this.status,
  });
}
