// lib/src/features/bi_reports/domain/entities/bi_report.dart

class BiReport {
  final String type;
  final String value;
  final int count;

  const BiReport({
    required this.type,
    required this.value,
    required this.count,
  });
}
