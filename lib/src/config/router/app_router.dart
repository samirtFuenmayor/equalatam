import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/finance/accounts_receivable/presentation/pages/accounts_receivable_page.dart';
import '../../features/finance/accounts_receivable/presentation/pages/payment_page.dart';
import '../../features/finance/accounts_receivable/presentation/pages/reconciliation_page.dart';
import '../../features/iam/presentation/pages/audit_logs_page.dart';
import '../../features/iam/presentation/pages/iam_home_page.dart';
import '../../features/iam/presentation/pages/permissions_page.dart';
import '../../features/iam/presentation/pages/roles_page.dart';
import '../../features/iam/presentation/pages/user_form_page.dart';
import '../../features/iam/presentation/pages/users_page.dart';
import '../../features/network/presentation/pages/branches_page.dart';
import '../../features/network/presentation/pages/hubs_page.dart';
import '../../features/network/presentation/pages/network_home_page.dart';
import '../../features/network/presentation/pages/routes_page.dart';
import '../../features/network/presentation/pages/zones_page.dart';
import '../../features/operations/presentation/pages/commissions_page.dart';
import '../../features/operations/presentation/pages/exceptions_page.dart';
import '../../features/operations/presentation/pages/operations_home_page.dart';
import '../../features/operations/presentation/pages/routing_page.dart';
import '../../features/operations/presentation/pages/tracking_scans_page.dart';
import '../../features/operations/presentation/pages/waybill_create_page.dart';
import '../../features/tariff/quote_generator/presentation/pages/cotizador_page.dart';
import '../../features/tariff/tariff_matrices/presentation/pages/matrices_page.dart';
import '../../features/tracking/corporate_tracking/presentation/pages/bulk_upload_page.dart';
import '../../features/tracking/corporate_tracking/presentation/pages/corporate_home_page.dart';
import '../../features/tracking/corporate_tracking/presentation/pages/reports_page.dart';
import '../../features/tracking/notifications/presentation/pages/logs_page.dart';
import '../../features/tracking/notifications/presentation/pages/notifications_home_page.dart';
import '../../features/tracking/notifications/presentation/pages/send_test_page.dart';
import '../../features/tracking/notifications/presentation/pages/templates_page.dart';
import '../../features/tracking/public_tracking/presentation/pages/public_tracking_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
    GoRoute(path: '/operations', builder: (context, state) => const OperationsHomePage()),
    GoRoute(path: '/operations/waybill', builder: (context, state) => const WaybillCreatePage()),
    GoRoute(path: '/operations/routing', builder: (context, state) => const RoutingPage()),
    GoRoute(path: '/operations/tracking', builder: (context, state) => const TrackingScansPage()),
    GoRoute(path: '/operations/exceptions', builder: (context, state) => const ExceptionsPage()),
    GoRoute(path: '/operations/commissions', builder: (context, state) => const CommissionsPage()),
    GoRoute(path: '/network', builder: (_, __) => const NetworkHomePage()),
    GoRoute(path: '/network/branches', builder: (_, __) => const BranchesPage()),
    GoRoute(path: '/network/hubs', builder: (_, __) => const HubsPage()),
    GoRoute(path: '/network/zones', builder: (_, __) => const ZonesPage()),
    GoRoute(path: '/network/routes', builder: (_, __) => const RoutesNetworkPage()),
    GoRoute(path: '/iam', builder: (_, __) => const IamHomePage()),
    GoRoute(path: '/iam/users', builder: (_, __) => const UsersPage()),
    GoRoute(path: '/iam/users/new', builder: (_, __) => const UserFormPage()),
    GoRoute(path: '/iam/roles', builder: (_, __) => const RolesPage()),
    GoRoute(path: '/iam/permissions', builder: (_, __) => const PermissionsPage()),
    GoRoute(path: '/iam/audit', builder: (_, __) => const AuditLogsPage()),
    GoRoute(path: '/tracking', builder: (_, __) => const PublicTrackingPage()),
    GoRoute(path: '/tracking/notifications', builder: (_, __) => const NotificationsHomePage()),
    GoRoute(path: '/tracking/notifications/templates', builder: (_, __) => const TemplatesPage()),
    GoRoute(path: '/tracking/notifications/logs', builder: (_, __) => const LogsPage()),
    GoRoute(path: '/tracking/notifications/send', builder: (_, __) => const SendTestPage()),
    GoRoute(path: '/tracking/corporate', builder: (_, __) => const CorporateHomePage()),
    GoRoute(path: '/tracking/corporate/upload', builder: (_, __) => BulkUploadPage(clientRef: 'CLIENT-1')), // Aquí ya no es necesario MaterialPage
    GoRoute(path: '/tracking/corporate/reports', builder: (_, __) => const ReportsPage()),
    GoRoute(path: '/finance/accounts', builder: (_, __) => const AccountsReceivablePage()),
    GoRoute(path: '/finance/payment', builder: (_, __) => const PaymentPage()),
    GoRoute(path: '/finance/reconciliation', builder: (_, __) => const ReconciliationPage()),
    GoRoute(path: '/tarifacion/cotizador', builder: (_, __) => const CotizadorPage()),
    GoRoute(path: '/tarifacion/matrices', builder: (_, __) => const MatricesPage()),


  ],
);
