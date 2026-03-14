// lib/src/features/dashboard/widgets/sidebar_menu.dart
import 'package:flutter/material.dart';

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

const _sections = [
  _MenuSection(title: 'Operaciones', icon: Icons.local_shipping_outlined, items: [
    _MenuItem('Crear Guía',       '/operations/waybill',     Icons.add_box_outlined),
    //_MenuItem('Routing',          '/operations/routing',     Icons.alt_route_outlined),
    _MenuItem('Tracking Interno', '/operations/tracking',    Icons.track_changes_outlined),
    //_MenuItem('Incidencias',      '/operations/exceptions',  Icons.warning_amber_outlined),
    //_MenuItem('Comisiones',       '/operations/commissions', Icons.payments_outlined),
    _MenuItem('Pedidos',          '/operations/pedidos',     Icons.backpack_outlined),
  ]),

  _MenuSection(title: 'Red Logística', icon: Icons.hub_outlined, items: [
    _MenuItem('Sucursales', '/network/branches', Icons.store_outlined),
   // _MenuItem('Hubs',       '/network/hubs',     Icons.hub_outlined),
    _MenuItem('Despachos',   '/network/despachos',Icons.hub_outlined),
    //_MenuItem('Zonas',      '/network/zones',    Icons.map_outlined),
    //_MenuItem('Rutas',      '/network/routes',   Icons.route_outlined),
  ]),

  // _MenuSection(title: 'Tracking', icon: Icons.location_on_outlined, items: [
  //   _MenuItem('Tracking Público',  '/tracking',               Icons.search_outlined),
  //   _MenuItem('Notificaciones',    '/tracking/notifications', Icons.notifications_outlined),
  //   _MenuItem('Corporativo',       '/tracking/corporate',     Icons.business_outlined),
  // ]),

   _MenuSection(title: 'Finanzas', icon: Icons.account_balance_outlined, items: [
     _MenuItem('Contabilidad', '/financiero', Icons.receipt_long_outlined),
     //   _MenuItem('Pagos',              '/finance/payment',        Icons.credit_card_outlined),
  //   _MenuItem('Conciliación',       '/finance/reconciliation', Icons.balance_outlined),
   ]),

  // _MenuSection(title: 'Tarifación', icon: Icons.calculate_outlined, items: [
  //   _MenuItem('Cotizador', '/tarifacion/cotizador', Icons.calculate_outlined),
  //   _MenuItem('Matrices',  '/tarifacion/matrices',  Icons.grid_on_outlined),
  // ]),
  //

  _MenuSection(title: 'Usarios / Clientes', icon: Icons.security_outlined, items: [
    _MenuItem('Usuarios',  '/iam/users',       Icons.people_outline),
    _MenuItem('Clientes',  '/iam/clientes',    Icons.people_alt_rounded),
    _MenuItem('Roles',     '/iam/roles',       Icons.badge_outlined),
    _MenuItem('Permisos',  '/iam/permissions', Icons.lock_outline),
    //_MenuItem('Auditoría', '/iam/audit',       Icons.history_outlined),
  ]),
];

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1257),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20, offset: const Offset(4, 0))],
      ),
      child: Column(children: [
        // Header
        _Header(onClose: widget.onClose),

        // Dashboard
        _TopItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          onTap: () => widget.onNavigate('/dashboard'),
        ),
        const SizedBox(height: 4),
        Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.white.withOpacity(0.08)),

        // Secciones
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _sections.map((s) => _Section(
              section: s,
              isExpanded: _expanded.contains(s.title),
              onToggle: () => setState(() {
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

        // Footer
        _Footer(onLogout: () => widget.onNavigate('/login')),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onClose;
  const _Header({this.onClose});

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
        const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Equalatam', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Panel administrativo',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
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
      // Encabezado de sección
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

      // Ítems
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
                      Icon(item.icon,
                          color: Colors.white38, size: 16),
                      const SizedBox(width: 10),
                      Text(item.label,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            )).toList(),
          )
              : const SizedBox.shrink(),
        ),
      ),      const SizedBox(height: 2),
    ]);
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onLogout;
  const _Footer({required this.onLogout});

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
        const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Administrador', style: TextStyle(
                  color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Text('ADMIN', style: TextStyle(color: Colors.white30, fontSize: 11)),
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

// ─── Alias para compatibilidad con código existente ───────────────────────────
class SidebarMenuExpanded extends StatelessWidget {
  final Function(String) onSelect;
  const SidebarMenuExpanded({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) => SidebarMenu(onNavigate: onSelect);
}