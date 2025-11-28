import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  PaymentModel({
    required super.id,
    required super.receivableId,
    required super.method,
    required super.reference,
    required super.date,
    required super.amount,
    required super.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
    id: j['id'],
    receivableId: j['receivableId'],
    method: j['method'],
    reference: j['reference'],
    date: DateTime.parse(j['date']),
    amount: (j['amount'] as num).toDouble(),
    status: j['status'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'receivableId': receivableId,
    'method': method,
    'reference': reference,
    'date': date.toIso8601String(),
    'amount': amount,
    'status': status,
  };
}
