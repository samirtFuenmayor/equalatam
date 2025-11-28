import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payments_bloc.dart';
import '../bloc/payments_event.dart';
import '../bloc/payments_state.dart';
import '../widgets/receivable_card.dart';
import '../../data/repositories/payments_repository_impl.dart';
import '../../data/datasources/payments_remote_ds.dart';
import 'payment_page.dart';

class AccountsReceivablePage extends StatelessWidget {
  const AccountsReceivablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PaymentsRepositoryImpl(PaymentsRemoteDataSource());
    return BlocProvider(
      create: (_) => PaymentsBloc(repo)..add(LoadReceivablesEvent()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Cuentas por Cobrar')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(children: [
                ElevatedButton(onPressed: ()=> context.read<PaymentsBloc>().add(LoadReceivablesEvent()), child: const Text('Actualizar')),
                const SizedBox(width:8),
                ElevatedButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentPage())), child: const Text('Ver pagos')),
                const SizedBox(width:8),
                ElevatedButton(onPressed: ()=> Navigator.pushNamed(context, '/finance/reconciliation'), child: const Text('Conciliación Bancaria')),
              ]),
              const SizedBox(height:12),
              Expanded(child: BlocBuilder<PaymentsBloc, PaymentsState>(builder: (context, state) {
                if (state is PaymentsLoading) return const Center(child: CircularProgressIndicator());
                if (state is ReceivablesLoaded) {
                  final list = state.receivables;
                  if (list.isEmpty) return const Center(child: Text('No hay cuentas por cobrar'));
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_,__) => const SizedBox(height:8),
                    itemBuilder: (context, i) {
                      final r = list[i];
                      return ReceivableCard(
                        receivable: r,
                        onPay: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(receivable: r))),
                      );
                    },
                  );
                }
                if (state is PaymentsError) return Center(child: Text('Error: ${state.message}'));
                return const SizedBox.shrink();
              })),
            ],
          ),
        ),
      ),
    );
  }
}
