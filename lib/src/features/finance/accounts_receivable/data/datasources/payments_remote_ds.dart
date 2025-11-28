import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/receivable_model.dart';
import '../models/payment_model.dart';

/// Mock remote data source for payments and bank extracts.
/// Replace with Dio/HTTP calls to your SpringBoot endpoints.
class PaymentsRemoteDataSource {
  final _uuid = const Uuid();

  final List<ReceivableModel> _receivables = List.generate(8, (i) {
    final now = DateTime.now();
    final due = now.add(Duration(days: (i - 3) * 7));
    final amt = 100.0 + i * 50;
    return ReceivableModel(
      id: 'R${1000 + i}',
      invoiceId: 'INV${2000 + i}',
      customerName: 'Cliente ${i+1}',
      customerId: 'CUST-${i+1}',
      dueDate: due,
      amount: amt,
      paid: i.isEven ? amt / 2 : 0.0,
      status: i.isEven ? 'partial' : (i==7 ? 'overdue' : 'pending'),
    );
  });

  final List<PaymentModel> _payments = [];

  final List<Map<String, dynamic>> _bankExtract = List.generate(6, (i) {
    final now = DateTime.now();
    return {
      'extractId': 'BEX${3000 + i}',
      'date': now.subtract(Duration(days: i)).toIso8601String(),
      'description': 'Depósito ${i+1}',
      'amount': (100 + i * 50),
      'matched': false,
    };
  });

  Future<List<ReceivableModel>> fetchReceivables({String? status}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (status == null) return List.from(_receivables);
    return _receivables.where((r) => r.status == status).toList();
  }

  Future<ReceivableModel> fetchReceivableById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _receivables.firstWhere((r) => r.id == id);
  }

  Future<PaymentModel> sendPaymentMock(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // simulate provider acceptance
    final p = PaymentModel(
      id: _uuid.v4(),
      receivableId: payload['receivableId'],
      method: payload['method'],
      reference: 'TX-${_uuid.v4().split('-').first}',
      date: DateTime.now(),
      amount: (payload['amount'] as num).toDouble(),
      status: 'completed',
    );
    _payments.insert(0, p);

    // update receivable
    final idx = _receivables.indexWhere((r) => r.id == p.receivableId);
    if (idx >= 0) {
      final r = _receivables[idx];
      final newPaid = r.paid + p.amount;
      final newStatus = (newPaid >= r.amount) ? 'paid' : 'partial';
      _receivables[idx] = ReceivableModel(
        id: r.id,
        invoiceId: r.invoiceId,
        customerName: r.customerName,
        customerId: r.customerId,
        dueDate: r.dueDate,
        amount: r.amount,
        paid: newPaid,
        status: newStatus,
      );
    }

    return p;
  }

  Future<List<PaymentModel>> fetchPayments({int limit = 100}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _payments.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> fetchBankExtract({int limit = 100}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bankExtract.take(limit).toList();
  }

  Future<void> matchExtract(String paymentId, String extractId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final exIdx = _bankExtract.indexWhere((e) => e['extractId'] == extractId);
    if (exIdx >= 0) _bankExtract[exIdx]['matched'] = true;
    final pIdx = _payments.indexWhere((p) => p.id == paymentId);
    if (pIdx >= 0) _payments[pIdx] = PaymentModel(
      id: _payments[pIdx].id,
      receivableId: _payments[pIdx].receivableId,
      method: _payments[pIdx].method,
      reference: _payments[pIdx].reference,
      date: _payments[pIdx].date,
      amount: _payments[pIdx].amount,
      status: 'reconciled',
    );
  }
}
