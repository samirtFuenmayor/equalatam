import 'package:flutter/material.dart';

class CommissionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPay;

  const CommissionCard({super.key, required this.title, required this.subtitle, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(onPressed: onPay, child: const Text('Pagar')),
      ),
    );
  }
}
