import 'package:equatable/equatable.dart';

abstract class CorporateEvent extends Equatable {
  @override List<Object?> get props => [];
}

class LoadClientRecords extends CorporateEvent {
  final String clientRef;
  LoadClientRecords(this.clientRef);
  @override List<Object?> get props => [clientRef];
}

class UploadCsvEvent extends CorporateEvent {
  final String csvContent;
  final String clientRef;
  UploadCsvEvent(this.csvContent, this.clientRef);
  @override List<Object?> get props => [clientRef];
}

class SearchWaybillsEvent extends CorporateEvent {
  final List<String> waybills;
  SearchWaybillsEvent(this.waybills);
  @override List<Object?> get props => [waybills];
}
