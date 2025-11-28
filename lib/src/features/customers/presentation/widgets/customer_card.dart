import 'package:flutter/material.dart';

class CustomerCard extends StatelessWidget {
  final String name;
  final String document;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.name,
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name),
        subtitle: Text(document),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
      ),
    );
  }
}
