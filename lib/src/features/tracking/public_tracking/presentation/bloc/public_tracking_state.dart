import 'package:equatable/equatable.dart';
import '../../domain/entities/tracking_info.dart';

class PublicTrackingState extends Equatable {
  final bool loading;
  final TrackingInfo? result;
  final String? error;

  const PublicTrackingState({this.loading = false, this.result, this.error});

  PublicTrackingState copyWith({bool? loading, TrackingInfo? result, String? error}) {
    return PublicTrackingState(
      loading: loading ?? this.loading,
      result: result ?? this.result,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, result ?? '', error ?? ''];
}
