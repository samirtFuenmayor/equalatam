import 'package:equatable/equatable.dart';
import '../../domain/entities/shipment.dart';

class CorporateState extends Equatable {
  final bool loading;
  final List<CorporateTrackingRecord> records;
  final String? message;
  final String? error;

  const CorporateState({ this.loading=false, this.records = const [], this.message, this.error });

  CorporateState copyWith({ bool? loading, List<CorporateTrackingRecord>? records, String? message, String? error }) {
    return CorporateState( loading: loading ?? this.loading, records: records ?? this.records, message: message, error: error );
  }

  @override List<Object?> get props => [loading, records, message ?? '', error ?? ''];
}
