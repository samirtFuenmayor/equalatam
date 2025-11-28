import 'package:flutter/material.dart';

class PermissionChip extends StatelessWidget {
  final String permission;
  const PermissionChip({super.key, required this.permission});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(permission, style: const TextStyle(fontSize: 12)));
  }
}
