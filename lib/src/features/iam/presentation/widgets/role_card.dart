import 'package:flutter/material.dart';
import '../../data/models/role_model.dart';
import 'permission_chip.dart';

class RoleCard extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onEdit;
  const RoleCard({super.key, required this.role, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(role.name),
        subtitle: Wrap(spacing: 6, children: role.permissions.map((p) => PermissionChip(permission: p)).toList()),
        trailing: OutlinedButton(onPressed: onEdit, child: const Text('Editar')),
      ),
    );
  }
}
