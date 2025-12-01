import 'package:flutter/material.dart';
import '../../../finance/accounts_receivable/presentation/pages/accounts_receivable_page.dart';
import '../../../finance/accounts_receivable/presentation/pages/payment_page.dart';
import '../../../finance/accounts_receivable/presentation/pages/reconciliation_page.dart';
import '../../../iam/presentation/pages/audit_logs_page.dart';
import '../../../iam/presentation/pages/permissions_page.dart';
import '../../../iam/presentation/pages/roles_page.dart';
import '../../../iam/presentation/pages/users_page.dart';
import '../../../network/presentation/pages/branches_page.dart';
import '../../../network/presentation/pages/hubs_page.dart';
import '../../../network/presentation/pages/routes_page.dart';
import '../../../network/presentation/pages/zones_page.dart';
import '../../../operations/presentation/pages/commissions_page.dart';
import '../../../operations/presentation/pages/exceptions_page.dart';
import '../../../operations/presentation/pages/routing_page.dart';
import '../../../operations/presentation/pages/tracking_scans_page.dart';
import '../../../operations/presentation/pages/waybill_create_page.dart';
import '../../../tariff/quote_generator/presentation/pages/cotizador_page.dart';
import '../../../tariff/tariff_matrices/presentation/pages/matrices_page.dart';
import '../../../tracking/corporate_tracking/presentation/pages/corporate_home_page.dart';
import '../../../tracking/notifications/presentation/pages/notifications_home_page.dart';
import '../../../tracking/public_tracking/presentation/pages/public_tracking_page.dart';
import '../widgets/sidebar_menu.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Controla qué módulo/submódulo mostrar
  String selectedContent = 'dashboard';

  void setContent(String contentKey) {
    setState(() {
      selectedContent = contentKey;
    });
  }

  Widget _renderContent() {
    switch (selectedContent) {
    // OPERACIONES
      case 'operations_waybill':
        return const WaybillCreatePage();
      case 'operations_routing':
        return const RoutingPage();
      case 'operations_tracking':
        return const TrackingScansPage();
      case 'operations_exceptions':
        return const ExceptionsPage();
      case 'operations_commissions':
        return const CommissionsPage();

    // RED LOGÍSTICA
      case 'network_branches':
        return const BranchesPage();
      case 'network_hubs':
        return const HubsPage();
      case 'network_zones':
        return const ZonesPage();
      case 'network_routes':
        return const RoutesNetworkPage();

    // FINANZAS
      case 'finance_accounts':
        return const AccountsReceivablePage();
      case 'finance_payment':
        return const PaymentPage();
      case 'finance_reconciliation':
        return const ReconciliationPage();

    // IAM
      case 'iam_users':
        return const UsersPage();
      case 'iam_roles':
        return const RolesPage();
      case 'iam_permissions':
        return const PermissionsPage();
      case 'iam_audit':
        return const AuditLogsPage();

    // TRACKING
      case 'tracking_public':
        return const PublicTrackingPage();
      case 'tracking_notifications':
        return const NotificationsHomePage();
      case 'tracking_corporate':
        return const CorporateHomePage();

    // TARIFACIÓN
      case 'tariff_cotizador':
        return const CotizadorPage();
      case 'tariff_matrices':
        return const MatricesPage();

    // DASHBOARD POR DEFECTO
      default:
        return SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _InfoCard(title: 'Ventas', value: '1.2k'),
                  _InfoCard(title: 'Clientes', value: '532'),
                  _InfoCard(title: 'Paquetes', value: '112'),
                  _InfoCard(title: 'Incidencias', value: '12'),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Gráfica / Estadísticas',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const Text('Panel Administrativo')),
      drawer: isDesktop ? null : SidebarMenuExpanded(onSelect: setContent),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 260,
              child: SidebarMenuExpanded(onSelect: setContent),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: _renderContent(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: SizedBox(
        width: 180,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                value,
                style:
                const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
