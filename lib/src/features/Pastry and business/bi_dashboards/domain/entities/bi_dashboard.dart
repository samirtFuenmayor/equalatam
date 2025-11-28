// lib/src/features/bi_dashboards/domain/entities/bi_dashboard.dart

class BiDashboard {
  final int shipments;
  final double revenue;
  final double deliveryRate;
  final double avgTransitTime;
  final int incidents;

  const BiDashboard({
    required this.shipments,
    required this.revenue,
    required this.deliveryRate,
    required this.avgTransitTime,
    required this.incidents,
  });
}
