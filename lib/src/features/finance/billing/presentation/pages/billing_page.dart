import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/billing_bloc.dart';
import '../bloc/billing_event.dart';
import '../bloc/billing_state.dart';
import '../widgets/invoice_card.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BillingBloc(context.read())..add(LoadInvoices()),
      child: Scaffold(
        appBar: AppBar(title: const Text("Facturación")),
        body: BlocBuilder<BillingBloc, BillingState>(
          builder: (context, state) {
            if (state is BillingLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BillingLoaded) {
              return ListView.builder(
                itemCount: state.invoices.length,
                itemBuilder: (context, i) => InvoiceCard(invoice: state.invoices[i]),
              );
            }
            return const Center(child: Text("Sin facturas"));
          },
        ),
      ),
    );
  }
}
