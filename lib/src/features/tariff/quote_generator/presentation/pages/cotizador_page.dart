import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../tariff_engine/data/repositories/tariff_engine_repository_impl.dart';
import '../../../tariff_engine/data/datasources/tariff_engine_remote_ds.dart';
import '../widgets/cotizador_form.dart';
import '../../../tariff_engine/presentation/widgets/quote_summary_card.dart';
import '../../../tariff_engine/presentation/bloc/tariff_engine_bloc.dart';
import '../../../tariff_engine/presentation/bloc/tariff_engine_event.dart';
import '../../../tariff_engine/presentation/bloc/tariff_engine_state.dart';

class CotizadorPage extends StatefulWidget {
  const CotizadorPage({super.key});

  @override
  State<CotizadorPage> createState() => _CotizadorPageState();
}

class _CotizadorPageState extends State<CotizadorPage> {
  late final TariffEngineBloc _bloc;

  @override
  void initState() {
    super.initState();
    final repo = TariffEngineRepositoryImpl(TariffEngineRemoteDS());
    _bloc = TariffEngineBloc(repository: repo);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _onCalculate(Map<String, dynamic> params) {
    _bloc.add(CalculateQuoteEvent(
      weightKg: params['weightKg'],
      lengthCm: params['lengthCm'],
      widthCm: params['widthCm'],
      heightCm: params['heightCm'],
      originZone: params['originZone'],
      destZone: params['destZone'],
      service: params['service'],
      declaredValue: params['declaredValue'],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Cotizador Online')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CotizadorForm(onCalculate: _onCalculate),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<TariffEngineBloc, TariffEngineState>(
                  builder: (context, state) {
                    if (state is TariffEngineInitial) return const Center(child: Text('Complete el formulario y pulse Calcular'));
                    if (state is TariffEngineLoading) return const Center(child: CircularProgressIndicator());
                    if (state is TariffEngineLoaded) return SingleChildScrollView(child: QuoteSummaryCard(quote: state.quote));
                    if (state is TariffEngineError) return Center(child: Text('Error: ${state.message}'));
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
