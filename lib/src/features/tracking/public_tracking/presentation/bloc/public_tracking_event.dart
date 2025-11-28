import 'package:equatable/equatable.dart';

abstract class PublicTrackingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchWaybill extends PublicTrackingEvent {
  final String waybill;
  SearchWaybill(this.waybill);

  @override
  List<Object?> get props => [waybill];
}

class ClearSearch extends PublicTrackingEvent {}
