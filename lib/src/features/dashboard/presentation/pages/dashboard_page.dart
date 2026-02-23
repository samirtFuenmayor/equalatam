// lib/src/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sidebar_menu.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHELL — envuelve TODAS las páginas internas con sidebar + topbar
// El router inyecta `child` según la ruta activa
// ─────────────────────────────────────────────────────────────────────────────
class DashboardShell extends StatefulWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  bool _drawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(children: [
        Row(children: [
          // ─── Sidebar fijo en desktop ───────────────────────────────────────
          if (isDesktop)
            SizedBox(
              width: 260,
              child: SidebarMenu(
                onNavigate: (path) => context.go(path),
              ),
            ),

          // ─── Área de contenido — aquí se renderiza la página activa ───────
          Expanded(
            child: Column(children: [
              _TopBar(
                isDesktop: isDesktop,
                onMenuTap: () => setState(() => _drawerOpen = !_drawerOpen),
              ),
              // child = página activa inyectada por ShellRoute
              Expanded(child: widget.child),
            ]),
          ),
        ]),

        // ─── Drawer overlay en móvil ───────────────────────────────────────
        if (!isDesktop && _drawerOpen) ...[
          GestureDetector(
            onTap: () => setState(() => _drawerOpen = false),
            child: Container(color: Colors.black45),
          ),
          SizedBox(
            width: 280,
            child: SidebarMenu(
              onNavigate: (path) {
                setState(() => _drawerOpen = false);
                context.go(path);
              },
              onClose: () => setState(() => _drawerOpen = false),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD HOME — contenido de la ruta /dashboard
// ─────────────────────────────────────────────────────────────────────────────
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) => const _DashboardBody();
}

// ─── TopBar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onMenuTap;

  const _TopBar({required this.isDesktop, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    // Título dinámico según la ruta actual
    final location = GoRouterState.of(context).uri.toString();
    final title    = _titleFor(location);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        if (!isDesktop) ...[
          IconButton(
            icon: const Icon(Icons.menu_rounded,
                color: Color(0xFF1A237E), size: 24),
            onPressed: onMenuTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
        ],
        if (isDesktop) ...[
          const Icon(Icons.grid_view_rounded,
              color: Color(0xFF1A237E), size: 18),
          const SizedBox(width: 8),
          const Text('Panel /',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(width: 6),
        ],
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF1A1A2E))),
        const Spacer(),
        // Notificaciones
        Stack(children: [
          Material(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {},
                child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.notifications_none_rounded,
                        size: 20, color: Color(0xFF6B7280)))),
          ),
          Positioned(
              top: 2,
              right: 2,
              child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Color(0xFFC62828), shape: BoxShape.circle),
                  child: const Text('3',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)))),
        ]),
        const SizedBox(width: 8),
        // Avatar
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person, color: Colors.white, size: 20)),
      ]),
    );
  }

  String _titleFor(String path) {
    if (path.startsWith('/iam/users'))       return 'Usuarios';
    if (path.startsWith('/iam/roles'))       return 'Roles';
    if (path.startsWith('/iam/permissions')) return 'Permisos';
    if (path.startsWith('/iam'))             return 'IAM';
    if (path.startsWith('/operations/waybill'))     return 'Crear Guía';
    if (path.startsWith('/operations/routing'))     return 'Ruteo';
    if (path.startsWith('/operations/tracking'))    return 'Escaneos';
    if (path.startsWith('/operations/exceptions'))  return 'Excepciones';
    if (path.startsWith('/operations/commissions')) return 'Comisiones';
    if (path.startsWith('/operations'))             return 'Operaciones';
    if (path.startsWith('/network/branches')) return 'Sucursales';
    if (path.startsWith('/network/hubs'))     return 'Hubs';
    if (path.startsWith('/network/zones'))    return 'Zonas';
    if (path.startsWith('/network/routes'))   return 'Rutas';
    if (path.startsWith('/network'))          return 'Red';
    if (path.startsWith('/tracking/notifications/templates')) return 'Plantillas';
    if (path.startsWith('/tracking/notifications/logs'))      return 'Logs';
    if (path.startsWith('/tracking/notifications/send'))      return 'Enviar Prueba';
    if (path.startsWith('/tracking/notifications'))           return 'Notificaciones';
    if (path.startsWith('/tracking/corporate/upload'))        return 'Carga Masiva';
    if (path.startsWith('/tracking/corporate/reports'))       return 'Reportes';
    if (path.startsWith('/tracking/corporate'))               return 'Tracking Corporativo';
    if (path.startsWith('/tracking'))                         return 'Rastreo';
    if (path.startsWith('/finance/accounts'))       return 'Cuentas por Cobrar';
    if (path.startsWith('/finance/payment'))        return 'Pagos';
    if (path.startsWith('/finance/reconciliation')) return 'Conciliación';
    if (path.startsWith('/tarifacion/cotizador')) return 'Cotizador';
    if (path.startsWith('/tarifacion/matrices'))  return 'Matrices';
    return 'Dashboard';
  }
}

// ─── Dashboard Body ───────────────────────────────────────────────────────────
class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isTablet  = MediaQuery.of(context).size.width >= 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _WelcomeBanner(),
        const SizedBox(height: 24),

        // KPIs
        GridView.count(
          crossAxisCount: isDesktop ? 4 : isTablet ? 2 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isDesktop ? 1.6 : 1.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _KpiCard(
                title: 'Paquetes hoy',
                value: '248',
                delta: '+12%',
                positive: true,
                icon: Icons.inventory_2_outlined,
                color: Color(0xFF1A237E)),
            _KpiCard(
                title: 'En tránsito',
                value: '1,832',
                delta: '+5%',
                positive: true,
                icon: Icons.local_shipping_outlined,
                color: Color(0xFF01579B)),
            _KpiCard(
                title: 'Entregados',
                value: '5,491',
                delta: '+18%',
                positive: true,
                icon: Icons.check_circle_outline,
                color: Color(0xFF2E7D32)),
            _KpiCard(
                title: 'Incidencias',
                value: '14',
                delta: '-3%',
                positive: false,
                icon: Icons.warning_amber_outlined,
                color: Color(0xFFC62828)),
          ],
        ),
        const SizedBox(height: 24),

        if (isDesktop)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _RecentActivity()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _QuickActions()),
          ])
        else ...[
          _RecentActivity(),
          const SizedBox(height: 16),
          _QuickActions(),
        ],
      ]),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  String _today() {
    final n = DateTime.now();
    const m = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const d = [
      '', 'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo'
    ];
    return '${d[n.weekday]}, ${n.day} de ${m[n.month]} de ${n.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Buenos días, Admin 👋',
                      style:
                      TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Panel Equalatam',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_today(),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                ])),
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.local_shipping_rounded,
                color: Colors.white, size: 36)),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title, value, delta;
  final bool positive;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.positive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: positive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      positive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: positive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828)),
                  const SizedBox(width: 3),
                  Text(delta,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: positive
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828))),
                ])),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            Text(title,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF))),
          ]),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  static const _items = [
    (Icons.inventory_2_outlined,    'Guía #EQ-20548 creada',        'Hace 5 min',  Color(0xFF1A237E)),
    (Icons.check_circle_outline,    'Paquete #EQ-20301 entregado',  'Hace 12 min', Color(0xFF2E7D32)),
    (Icons.warning_amber_outlined,  'Incidencia en ruta MIA-GYE',   'Hace 25 min', Color(0xFFFF6F00)),
    (Icons.local_shipping_outlined, 'Despacho #D-0892 en camino',   'Hace 40 min', Color(0xFF01579B)),
    (Icons.person_add_outlined,     'Nuevo cliente registrado',     'Hace 1 hora', Color(0xFF3949AB)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(children: [
              const Text('Actividad reciente',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
              const Spacer(),
              TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1A237E),
                      padding: EdgeInsets.zero),
                  child: const Text('Ver todo',
                      style: TextStyle(fontSize: 13))),
            ])),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        ..._items.map((e) => Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: e.$4.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(e.$1, color: e.$4, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(e.$2,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF374151)))),
              Text(e.$3,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
            ]))),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _QuickActions extends StatelessWidget {
  static const _actions = [
    (Icons.add_box_outlined,       'Crear Guía',       '/operations/waybill',   Color(0xFF1A237E)),
    (Icons.person_search_outlined, 'Buscar Cliente',   '/iam/users',            Color(0xFF01579B)),
    (Icons.track_changes_outlined, 'Rastrear Paquete', '/tracking',             Color(0xFF2E7D32)),
    (Icons.calculate_outlined,     'Cotizar Envío',    '/tarifacion/cotizador', Color(0xFFFF6F00)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Acciones rápidas',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E))),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _actions.map<Widget>((action) {
              final (icon, label, path, color) = action;
              return Material(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go(path),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(label,
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}