// lib/src/features/dashboard/widgets/sidebar_menu.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Estructura del menú ──────────────────────────────────────────────────────
class _MenuItem {
  final String label, path;
  final IconData icon;
  const _MenuItem(this.label, this.path, this.icon);
}

class _MenuSection {
  final String title;
  final IconData icon;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.icon, required this.items});
}

// ─── Secciones por rol ────────────────────────────────────────────────────────
List<_MenuSection> _sectionsForRole(String role) {
  switch (role) {

    case 'ADMIN':
      return [
        _MenuSection(title: 'Operaciones', icon: Icons.local_shipping_outlined, items: [
          _MenuItem('Pedidos',          '/operations/pedidos',     Icons.backpack_outlined),
          _MenuItem('Crear Guía',       '/operations/waybill',     Icons.add_box_outlined),
          _MenuItem('Tracking Interno', '/operations/tracking',    Icons.track_changes_outlined),
        ]),
        _MenuSection(title: 'Red Logística', icon: Icons.hub_outlined, items: [
          _MenuItem('Sucursales', '/network/branches',  Icons.store_outlined),
          _MenuItem('Despachos',  '/network/despachos', Icons.hub_outlined),
        ]),
        _MenuSection(title: 'Finanzas', icon: Icons.account_balance_outlined, items: [
          _MenuItem('Contabilidad', '/financiero', Icons.receipt_long_outlined),
        ]),
        _MenuSection(title: 'Usuarios / Clientes', icon: Icons.security_outlined, items: [
          _MenuItem('Usuarios', '/iam/users',       Icons.people_outline),
          _MenuItem('Clientes', '/iam/clientes',    Icons.people_alt_rounded),
          _MenuItem('Roles',    '/iam/roles',       Icons.badge_outlined),
          _MenuItem('Permisos', '/iam/permissions', Icons.lock_outline),
        ]),
      ];

    case 'CAJERO':
      return [
        _MenuSection(title: 'Facturación', icon: Icons.account_balance_outlined, items: [
          _MenuItem('Contabilidad',        '/financiero',           Icons.receipt_long_outlined),
          _MenuItem('Pedidos a Facturar',  '/operations/pedidos',   Icons.backpack_outlined),
        ]),
        _MenuSection(title: 'Clientes', icon: Icons.people_outline, items: [
          _MenuItem('Clientes', '/iam/clientes', Icons.people_alt_rounded),
        ]),
      ];

    case 'SUPERVISOR':
      return [
        _MenuSection(title: 'Despachos', icon: Icons.hub_outlined, items: [
          _MenuItem('Despachos',        '/network/despachos',   Icons.hub_outlined),
          _MenuItem('Pedidos',          '/operations/pedidos',  Icons.backpack_outlined),
          _MenuItem('Crear Guía',       '/operations/waybill',  Icons.add_box_outlined),
          _MenuItem('Tracking Interno', '/operations/tracking', Icons.track_changes_outlined),
        ]),
        _MenuSection(title: 'Red Logística', icon: Icons.store_outlined, items: [
          _MenuItem('Sucursales', '/network/branches', Icons.store_outlined),
        ]),
      ];

    case 'CLIENTE':
      return [
        _MenuSection(title: 'Mis Envíos', icon: Icons.inventory_2_outlined, items: [
          _MenuItem('Mis Pedidos',     '/cliente/pedidos',      Icons.backpack_outlined),
          _MenuItem('Mis Cotizaciones','/cliente/cotizaciones', Icons.calculate_outlined),
          _MenuItem('Mis Facturas',    '/cliente/facturas',     Icons.receipt_long_outlined),
        ]),
        _MenuSection(title: 'Tracking', icon: Icons.track_changes_outlined, items: [
          _MenuItem('Rastrear Paquete', '/tracking', Icons.search_outlined),
        ]),
      ];

    default:
      return [];
  }
}

// ─── Labels por rol ───────────────────────────────────────────────────────────
String _rolLabel(String role) => switch (role) {
  'ADMIN'      => 'Administrador',
  'CAJERO'     => 'Cajero',
  'SUPERVISOR' => 'Supervisor',
  'CLIENTE'    => 'Cliente',
  _            => 'Usuario',
};

String _subtitleForRole(String role) => switch (role) {
  'ADMIN'      => 'Panel administrativo',
  'CAJERO'     => 'Panel de facturación',
  'SUPERVISOR' => 'Panel de despachos',
  'CLIENTE'    => 'Mi cuenta',
  _            => '',
};

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class SidebarMenu extends StatefulWidget {
  final void Function(String path) onNavigate;
  final VoidCallback? onClose;

  const SidebarMenu({
    super.key,
    required this.onNavigate,
    this.onClose,
  });

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  final Set<String> _expanded = {};
  String _role = 'CLIENTE';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role     = prefs.getString('eq_role') ?? 'CLIENTE';
      _username = prefs.getString('eq_username') ?? _rolLabel(_role);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sectionsForRole(_role);
    final showDashboard = _role != 'CLIENTE';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1257),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20, offset: const Offset(4, 0))],
      ),
      child: Column(children: [
        // Header
        _Header(
          onClose:   widget.onClose,
          subtitle:  _subtitleForRole(_role),
        ),

        // Dashboard solo para roles internos
        if (showDashboard) ...[
          _TopItem(
            label: 'Dashboard',
            icon:  Icons.dashboard_outlined,
            onTap: () => widget.onNavigate('/dashboard'),
          ),
          const SizedBox(height: 4),
          Container(height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.white.withOpacity(0.08)),
        ],

        // Secciones según rol
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: sections.map((s) => _Section(
              section:    s,
              isExpanded: _expanded.contains(s.title),
              onToggle:   () => setState(() {
                _expanded.contains(s.title)
                    ? _expanded.remove(s.title)
                    : _expanded.add(s.title);
              }),
              onItemTap: (path) {
                widget.onNavigate(path);
                widget.onClose?.call();
              },
            )).toList(),
          ),
        ),

        // Footer con nombre y rol real
        _Footer(
          username: _username,
          roleLabel: _rolLabel(_role),
          onLogout: () {
            widget.onNavigate('/login');
          },
        ),
      ]),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback? onClose;
  final String subtitle;
  const _Header({this.onClose, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08)))),
      child: Row(children: [
        Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: const Color(0xFF3949AB),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Equalatam', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ])),
        if (onClose != null)
          IconButton(
              icon: const Icon(Icons.close, color: Colors.white38, size: 20),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints()),
      ]),
    );
  }
}

// ─── Top item (Dashboard) ─────────────────────────────────────────────────────
class _TopItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _TopItem({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Icon(icon, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Text(label, style: const TextStyle(
                      color: Colors.white70, fontSize: 14)),
                ]))),
      ),
    );
  }
}

// ─── Sección colapsable ───────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final _MenuSection section;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(String) onItemTap;

  const _Section({
    required this.section, required this.isExpanded,
    required this.onToggle, required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onToggle,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Icon(section.icon, color: Colors.white38, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(section.title, style: const TextStyle(
                          color: Colors.white38, fontSize: 12,
                          fontWeight: FontWeight.w600, letterSpacing: 0.3))),
                      Icon(isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white30, size: 18),
                    ]))),
          )),
      TickerMode(
        enabled: true,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Column(
            children: section.items.map((item) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 12, 0),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onItemTap(item.path),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    child: Row(children: [
                      Icon(item.icon, color: Colors.white38, size: 16),
                      const SizedBox(width: 10),
                      Text(item.label, style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            )).toList(),
          )
              : const SizedBox.shrink(),
        ),
      ),
      const SizedBox(height: 2),
    ]);
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final String username;
  final String roleLabel;
  final VoidCallback onLogout;
  const _Footer({required this.username, required this.roleLabel, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))),
      child: Row(children: [
        const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF3949AB),
            child: Icon(Icons.person, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username, style: const TextStyle(
                  color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(roleLabel, style: const TextStyle(color: Colors.white30, fontSize: 11)),
            ])),
        IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white30, size: 18),
            onPressed: onLogout,
            tooltip: 'Cerrar sesión',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints()),
      ]),
    );
  }
}

// ─── Alias para compatibilidad ────────────────────────────────────────────────
class SidebarMenuExpanded extends StatelessWidget {
  final Function(String) onSelect;
  const SidebarMenuExpanded({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) => SidebarMenu(onNavigate: onSelect);
}