import '../entities/receivable.dart';
import '../entities/payment.dart';

abstract class PaymentsRepository {
  // Receivables
  Future<List<Receivable>> getReceivables({String? status});
  Future<Receivable> getReceivableById(String id);

  // Payments
  Future<Payment> createPayment(Payment payment);
  Future<List<Payment>> getPayments({int limit});

  // Reconciliation
  Future<List<Map<String, dynamic>>> getBankExtract({int limit});
  Future<void> reconcilePayment(String paymentId, String extractId);
}
