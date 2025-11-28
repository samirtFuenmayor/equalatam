import 'package:flutter/material.dart';
import 'users_page.dart';
import 'roles_page.dart';
import 'permissions_page.dart';
import 'audit_logs_page.dart';

class IamHomePage extends StatelessWidget {
  const IamHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Usuarios & Seguridad')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            const Text('Gestión de Usuarios, Roles y Permisos', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(icon: const Icon(Icons.people), label: const Text('Usuarios'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersPage()))),
                ElevatedButton.icon(icon: const Icon(Icons.admin_panel_settings), label: const Text('Roles'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolesPage()))),
                ElevatedButton.icon(icon: const Icon(Icons.lock), label: const Text('Permisos'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsPage()))),
                ElevatedButton.icon(icon: const Icon(Icons.history), label: const Text('Audit Logs'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsPage()))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
