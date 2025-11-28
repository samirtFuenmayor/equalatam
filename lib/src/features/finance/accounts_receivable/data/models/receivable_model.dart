import '../../domain/entities/receivable.dart';

class ReceivableModel extends Receivable {
  ReceivableModel({
    required super.id,
    required super.invoiceId,
    required super.customerName,
    required super.customerId,
    required super.dueDate,
    required super.amount,
    required super.paid,
    required super.status,
  });

  factory ReceivableModel.fromJson(Map<String, dynamic> j) => ReceivableModel(
    id: j['id'],
    invoiceId: j['invoiceId'],
    customerName: j['customerName'],
    customerId: j['customerId'],
    dueDate: DateTime.parse(j['dueDate']),
    amount: (j['amount'] as num).toDouble(),
    paid: (j['paid'] as num).toDouble(),
    status: j['status'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceId': invoiceId,
    'customerName': customerName,
    'customerId': customerId,
    'dueDate': dueDate.toIso8601String(),
    'amount': amount,
    'paid': paid,
    'status': status,
  };
}
