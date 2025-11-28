import 'package:flutter/material.dart';

/// Widget demo que muestra un menú condicional según roleId.
/// En la práctica, obtén el roleId del usuario logueado (AuthRepository / SharedPreferences).
class RoleBasedMenu extends StatelessWidget {
  final String roleId;
  const RoleBasedMenu({super.key, required this.roleId});

  bool has(String perm) {
    if (roleId == 'r_admin') return true;
    if (roleId == 'r_operator') return perm.startsWith('shipments') || perm.startsWith('scan');
    return perm == 'reports.view';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (has('users.manage'))
          ListTile(leading: const Icon(Icons.people), title: const Text('Usuarios'), onTap: () => Navigator.pushNamed(context, '/iam/users')),
        if (has('roles.manage'))
          ListTile(leading: const Icon(Icons.admin_panel_settings), title: const Text('Roles'), onTap: () => Navigator.pushNamed(context, '/iam/roles')),
        if (has('reports.view'))
          ListTile(leading: const Icon(Icons.bar_chart), title: const Text('Reportes'), onTap: () {}),
        if (has('shipments.view'))
          ListTile(leading: const Icon(Icons.local_shipping), title: const Text('Operaciones'), onTap: () => Navigator.pushNamed(context, '/operations')),
      ],
    );
  }
}
