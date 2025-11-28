abstract class MatricesEvent {}

class LoadMatricesEvent extends MatricesEvent {}

class SaveMatrixEvent extends MatricesEvent {
  final dynamic matrix;
  SaveMatrixEvent(this.matrix);
}

class DeleteMatrixEvent extends MatricesEvent {
  final String id;
  DeleteMatrixEvent(this.id);
}
