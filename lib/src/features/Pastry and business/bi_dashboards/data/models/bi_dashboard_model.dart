// lib/src/features/bi_dashboards/data/models/bi_dashboard_model.dart

import '../../domain/entities/bi_dashboard.dart';

class BiDashboardModel extends BiDashboard {
  const BiDashboardModel({
    required super.shipments,
    required super.revenue,
    required super.deliveryRate,
    required super.avgTransitTime,
    required super.incidents,
  });

  factory BiDashboardModel.fromJson(Map<String, dynamic> json) {
    return BiDashboardModel(
      shipments: json["shipments"],
      revenue: json["revenue"],
      deliveryRate: json["deliveryRate"],
      avgTransitTime: json["avgTransitTime"],
      incidents: json["incidents"],
    );
  }
}
