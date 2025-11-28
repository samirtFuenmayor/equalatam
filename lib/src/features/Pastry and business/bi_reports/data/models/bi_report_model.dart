// lib/src/features/bi_reports/data/models/bi_report_model.dart

import '../../domain/entities/bi_report.dart';

class BiReportModel extends BiReport {
  const BiReportModel({
    required super.type,
    required super.value,
    required super.count,
  });

  factory BiReportModel.fromJson(Map<String, dynamic> json) {
    return BiReportModel(
      type: json["type"],
      value: json["value"],
      count: json["count"],
    );
  }
}
