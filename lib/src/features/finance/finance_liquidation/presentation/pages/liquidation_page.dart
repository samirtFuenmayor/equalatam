// lib/src/features/finance_sub3_liquidation/presentation/pages/liquidation_page.dart

import 'package:flutter/material.dart';
import '../../data/datasources/liquidation_remote_ds.dart';
import '../../data/repositories/liquidation_repository_impl.dart';
import '../../domain/entities/liquidation.dart';
import '../widgets/liquidation_list.dart';

class LiquidationPage extends StatelessWidget {
  const LiquidationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = LiquidationRepositoryImpl(LiquidationRemoteDataSource());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Liquidación Interna"),
      ),
      body: FutureBuilder<List<Liquidation>>(
        future: repo.getLiquidations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return LiquidationList(liquidations: snapshot.data!);
        },
      ),
    );
  }
}
