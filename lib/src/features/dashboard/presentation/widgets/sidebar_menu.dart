import 'package:flutter/material.dart';

class SidebarMenuExpanded extends StatefulWidget {
  final Function(String) onSelect;
  const SidebarMenuExpanded({super.key, required this.onSelect});

  @override
  State<SidebarMenuExpanded> createState() => _SidebarMenuExpandedState();
}

class _SidebarMenuExpandedState extends State<SidebarMenuExpanded> {
  final Map<String, bool> expanded = {};

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: CircleAvatar(radius: 40, child: Icon(Icons.person)),
          ),
          _item('Dashboard', 'dashboard', Icons.dashboard),

          // Operaciones
          _category('Operaciones'),
          _expandable(
            title: 'Gestión de Pedidos',
            icon: Icons.add_box,
            items: {
              'Crear Guía': 'operations_waybill',
              'Routing': 'operations_routing',
              'Tracking Interno': 'operations_tracking',
            },
          ),
          _expandable(
            title: 'Incidencias y Comisiones',
            icon: Icons.error,
            items: {
              'Incidencias': 'operations_exceptions',
              'Comisiones': 'operations_commissions',
            },
          ),

          // Red Logística
          _category('Red Logística'),
          _expandable(
            title: 'Sucursales y Rutas',
            icon: Icons.store,
            items: {
              'Sucursales': 'network_branches',
              'Hubs': 'network_hubs',
              'Zonas': 'network_zones',
              'Rutas': 'network_routes',
            },
          ),

          // Finanzas
          _category('Finanzas'),
          _expandable(
            title: 'Finanzas y Contabilidad',
            icon: Icons.receipt_long,
            items: {
              'Cuentas por Cobrar': 'finance_accounts',
              'Pagos': 'finance_payment',
              'Conciliación': 'finance_reconciliation',
            },
          ),

          // Reportería & BI
          _category('Reportería & BI'),
          _expandable(
            title: 'Reportes',
            icon: Icons.analytics,
            items: {
              'KPIs Ejecutivos': 'reports_kpis',
              'Reportes Personalizados': 'reports_custom',
              'Estacionalidad': 'reports_seasonality',
              'SLAs': 'reports_slas',
            },
          ),

          // IAM
          _category('Seguridad / IAM'),
          _expandable(
            title: 'Gestión de IAM',
            icon: Icons.security,
            items: {
              'Usuarios': 'iam_users',
              'Roles': 'iam_roles',
              'Permisos': 'iam_permissions',
              'Auditoría': 'iam_audit',
            },
          ),

          // Tracking
          _category('Tracking'),
          _expandable(
            title: 'Seguimiento',
            icon: Icons.track_changes,
            items: {
              'Tracking Público': 'tracking_public',
              'Notificaciones': 'tracking_notifications',
              'Corporativo': 'tracking_corporate',
            },
          ),

          // Tarifación
          _category('Tarifación'),
          _expandable(
            title: 'Cotizador & Matrices',
            icon: Icons.calculate,
            items: {
              'Cotizador': 'tariff_cotizador',
              'Matrices': 'tariff_matrices',
            },
          ),
        ],
      ),
    );
  }

  Widget _category(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
  );

  Widget _item(String text, String contentKey, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () => widget.onSelect(contentKey),
    );
  }

  Widget _expandable(
      {required String title,
        required IconData icon,
        required Map<String, String> items}) {
    final isExpanded = expanded[title] ?? false;
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      initiallyExpanded: isExpanded,
      onExpansionChanged: (val) {
        setState(() {
          expanded[title] = val;
        });
      },
      children: items.entries
          .map((e) => ListTile(
        title: Text(e.key),
        onTap: () => widget.onSelect(e.value),
      ))
          .toList(),
    );
  }
}
