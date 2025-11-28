import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payments_bloc.dart';
import '../bloc/payments_event.dart';
import '../bloc/payments_state.dart';
import '../widgets/reconciliation_item.dart';
import '../../data/repositories/payments_repository_impl.dart';
import '../../data/datasources/payments_remote_ds.dart';

class ReconciliationPage extends StatelessWidget {
  const ReconciliationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PaymentsRepositoryImpl(PaymentsRemoteDataSource());
    return BlocProvider(
      create: (_) => PaymentsBloc(repo)..add(LoadBankExtractEvent())..add(LoadPaymentsEvent()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Conciliación Bancaria')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            const Text('Extractos bancarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height:8),
            Expanded(child: BlocBuilder<PaymentsBloc, PaymentsState>(builder: (context,state){
              if (state is PaymentsLoading) return const Center(child: CircularProgressIndicator());
              if (state is BankExtractLoaded) {
                final extracts = state.extracts;
                return ListView.separated(
                  itemCount: extracts.length,
                  separatorBuilder: (_,__) => const SizedBox(height:6),
                  itemBuilder: (context, i) {
                    final ex = extracts[i];
                    return ReconciliationItem(
                      extract: ex,
                      onMatch: ex['matched'] == true ? null : () async {
                        // For demo, match first payment
                        final paymentsState = context.read<PaymentsBloc>().state;
                        if (paymentsState is PaymentsLoaded && paymentsState.payments.isNotEmpty) {
                          final paymentId = paymentsState.payments.first.id;
                          context.read<PaymentsBloc>().add(ReconcileEvent(paymentId, ex['extractId']));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conciliación ejecutada (mock)')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay pagos para conciliar')));
                        }
                      },
                    );
                  },
                );
              }
              if (state is PaymentsLoaded) {
                final ps = state.payments;
                return ListView.separated(itemCount: ps.length, separatorBuilder: (_,__)=> const Divider(), itemBuilder: (context,i){
                  final p = ps[i];
                  return ListTile(title: Text('${p.method} — \$${p.amount}'), subtitle: Text('${p.date} — ${p.status}'));
                });
              }
              if (state is PaymentsError) return Center(child: Text('Error: ${state.message}'));
              return const Center(child: Text('Sin datos'));
            })),
          ]),
        ),
      ),
    );
  }
}
