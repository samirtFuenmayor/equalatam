import '../../domain/entities/receivable.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_remote_ds.dart';
import '../models/receivable_model.dart';
import '../models/payment_model.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsRemoteDataSource remote;
  PaymentsRepositoryImpl(this.remote);

  @override
  Future<List<Receivable>> getReceivables({String? status}) async {
    final list = await remote.fetchReceivables(status: status);
    return list.cast<ReceivableModel>();
  }

  @override
  Future<Receivable> getReceivableById(String id) async {
    return await remote.fetchReceivableById(id);
  }

  @override
  Future<Payment> createPayment(Payment payment) async {
    final payload = payment is PaymentModel ? payment.toJson() : {
      'receivableId': payment.receivableId,
      'method': payment.method,
      'amount': payment.amount,
    };
    final model = await remote.sendPaymentMock(payload);
    return model;
  }

  @override
  Future<List<Payment>> getPayments({int limit = 100}) async {
    final list = await remote.fetchPayments(limit: limit);
    return list.cast<PaymentModel>();
  }

  @override
  Future<List<Map<String, dynamic>>> getBankExtract({int limit = 100}) async {
    return await remote.fetchBankExtract(limit: limit);
  }

  @override
  Future<void> reconcilePayment(String paymentId, String extractId) async {
    await remote.matchExtract(paymentId, extractId);
  }
}
