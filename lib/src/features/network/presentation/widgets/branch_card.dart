import 'package:flutter/material.dart';

class BranchCard extends StatelessWidget {
  final String title;
  final String address;
  final String phone;
  final VoidCallback onEdit;

  const BranchCard({
    super.key,
    required this.title,
    required this.address,
    required this.phone,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.store),
        title: Text(title),
        subtitle: Text('$address\nTel: $phone'),
        isThreeLine: true,
        trailing: ElevatedButton(onPressed: onEdit, child: const Text('Editar')),
      ),
    );
  }
}
