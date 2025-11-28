import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/payment_form.dart';
import '../bloc/payments_bloc.dart';
import '../bloc/payments_event.dart';
import '../bloc/payments_state.dart';
import '../../domain/entities/receivable.dart';
import '../../data/repositories/payments_repository_impl.dart';
import '../../data/datasources/payments_remote_ds.dart';

class PaymentPage extends StatelessWidget {
  final Receivable? receivable;
  const PaymentPage({super.key, this.receivable});

  @override
  Widget build(BuildContext context) {
    final repo = PaymentsRepositoryImpl(PaymentsRemoteDataSource());
    return BlocProvider(
      create: (_) => PaymentsBloc(repo),
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar Pago')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            if (receivable != null) Card(child: ListTile(title: Text('Factura: ${receivable!.invoiceId}'), subtitle: Text('Cliente: ${receivable!.customerName}\nSaldo: \$${receivable!.balance.toStringAsFixed(2)}'))),
            const SizedBox(height:12),
            PaymentForm(
              receivableId: receivable?.id ?? '',
              maxAmount: receivable?.balance ?? 1000000,
              onSubmit: (payment) {
                // dispatch event
                final bloc = context.read<PaymentsBloc>();
                bloc.add(MakePaymentEvent(payment));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago enviado (mock)')));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height:12),
            Expanded(child: BlocBuilder<PaymentsBloc, PaymentsState>(builder: (context,state){
              if (state is PaymentsLoading) return const Center(child:CircularProgressIndicator());
              if (state is PaymentsLoaded) {
                final ps = state.payments;
                if (ps.isEmpty) return const Center(child: Text('No hay pagos registrados'));
                return ListView.separated(itemCount: ps.length, separatorBuilder: (_,__)=> const Divider(), itemBuilder: (context,i){
                  final p = ps[i];
                  return ListTile(title: Text('${p.method} — \$${p.amount.toStringAsFixed(2)}'), subtitle: Text('${p.date} — ${p.status}'));
                });
              }
              return const SizedBox.shrink();
            })),
          ]),
        ),
      ),
    );
  }
}
