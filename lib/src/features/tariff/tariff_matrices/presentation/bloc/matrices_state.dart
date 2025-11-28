abstract class MatricesState {}

class MatricesInitial extends MatricesState {}

class MatricesLoading extends MatricesState {}

class MatricesLoaded extends MatricesState {
  final List<dynamic> matrices;
  MatricesLoaded(this.matrices);
}

class MatricesError extends MatricesState {
  final String message;
  MatricesError(this.message);
}
