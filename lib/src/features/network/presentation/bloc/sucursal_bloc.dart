// lib/src/features/network/presentation/bloc/sucursal_bloc.dart
import 'package:bloc/bloc.dart';
import '../domain/models/sucursal_model.dart';
import '../domain/repositories/sucursal_repository.dart';

// ─── EVENTOS ──────────────────────────────────────────────────────────────────
abstract class SucursalEvent {}

/// Carga todas (incluyendo inactivas) — para la pantalla de gestión
class SucursalLoadAll      extends SucursalEvent {}
/// Carga solo activas — para dropdowns
class SucursalLoadActivas  extends SucursalEvent {}
/// Filtrar por tipo
class SucursalFilterByTipo extends SucursalEvent {
  final TipoSucursal? tipo; // null = todas
  SucursalFilterByTipo(this.tipo);
}
/// Crear nueva sucursal
class SucursalCreateRequested extends SucursalEvent {
  final Map<String, dynamic> data;
  SucursalCreateRequested(this.data);
}
/// Actualizar sucursal
class SucursalUpdateRequested extends SucursalEvent {
  final String id;
  final Map<String, dynamic> data;
  SucursalUpdateRequested(this.id, this.data);
}
/// Desactivar (soft delete)
class SucursalDesactivarRequested extends SucursalEvent {
  final String id;
  SucursalDesactivarRequested(this.id);
}
/// Reactivar
class SucursalReactivarRequested extends SucursalEvent {
  final String id;
  SucursalReactivarRequested(this.id);
}

// ─── ESTADOS ──────────────────────────────────────────────────────────────────
abstract class SucursalState {}

class SucursalInitial extends SucursalState {}
class SucursalLoading  extends SucursalState {}

class SucursalLoaded extends SucursalState {
  final List<SucursalModel> sucursales;
  final String?             message;
  SucursalLoaded(this.sucursales, {this.message});
}

class SucursalError extends SucursalState {
  final String              message;
  final List<SucursalModel> sucursales; // preserva lista al fallar
  SucursalError(this.message, {this.sucursales = const []});
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────
class SucursalBloc extends Bloc<SucursalEvent, SucursalState> {
  final SucursalRepository repo;

  List<SucursalModel> _all = []; // caché completo

  SucursalBloc({required this.repo}) : super(SucursalInitial()) {
    on<SucursalLoadAll>(_onLoadAll);
    on<SucursalLoadActivas>(_onLoadActivas);
    on<SucursalFilterByTipo>(_onFilter);
    on<SucursalCreateRequested>(_onCreate);
    on<SucursalUpdateRequested>(_onUpdate);
    on<SucursalDesactivarRequested>(_onDesactivar);
    on<SucursalReactivarRequested>(_onReactivar);
  }

  // ── Cargar todas (incluyendo inactivas) ───────────────────────────────────
  Future<void> _onLoadAll(SucursalLoadAll _, Emitter<SucursalState> emit) async {
    emit(SucursalLoading());
    try {
      _all = await repo.findAll();
      emit(SucursalLoaded(_all));
    } on Exception catch (e) {
      emit(SucursalError(_m(e)));
    }
  }

  // ── Cargar solo activas ───────────────────────────────────────────────────
  Future<void> _onLoadActivas(SucursalLoadActivas _, Emitter<SucursalState> emit) async {
    emit(SucursalLoading());
    try {
      _all = await repo.findAllActivas();
      emit(SucursalLoaded(_all));
    } on Exception catch (e) {
      emit(SucursalError(_m(e)));
    }
  }

  // ── Filtrar por tipo (client-side sobre el caché) ─────────────────────────
  Future<void> _onFilter(SucursalFilterByTipo e, Emitter<SucursalState> emit) async {
    final filtered = e.tipo == null
        ? _all
        : _all.where((s) => s.tipo == e.tipo).toList();
    emit(SucursalLoaded(filtered));
  }

  // ── Crear ─────────────────────────────────────────────────────────────────
  Future<void> _onCreate(SucursalCreateRequested e, Emitter<SucursalState> emit) async {
    emit(SucursalLoading());
    try {
      final nueva = await repo.create(e.data);
      _all = [..._all, nueva];
      emit(SucursalLoaded(_all,
          message: 'Sucursal "${nueva.nombre}" creada exitosamente'));
    } on Exception catch (e) {
      emit(SucursalError(_m(e), sucursales: _all));
    }
  }

  // ── Actualizar ────────────────────────────────────────────────────────────
  Future<void> _onUpdate(SucursalUpdateRequested e, Emitter<SucursalState> emit) async {
    emit(SucursalLoading());
    try {
      final updated = await repo.update(e.id, e.data);
      _all = _all.map((s) => s.id == e.id ? updated : s).toList();
      emit(SucursalLoaded(_all, message: 'Sucursal actualizada correctamente'));
    } on Exception catch (e) {
      emit(SucursalError(_m(e), sucursales: _all));
    }
  }

  // ── Desactivar (soft delete + optimistic) ────────────────────────────────
  Future<void> _onDesactivar(SucursalDesactivarRequested e,
      Emitter<SucursalState> emit) async {
    // Optimistic: marca como inactiva inmediatamente
    _all = _all.map((s) => s.id == e.id ? s.copyWith(activa: false) : s).toList();
    emit(SucursalLoaded(_all));
    try {
      await repo.desactivar(e.id);
      // Recarga para asegurar sincronía
      _all = await repo.findAll();
      emit(SucursalLoaded(_all, message: 'Sucursal desactivada correctamente'));
    } on Exception catch (ex) {
      // Revertir
      _all = _all.map((s) => s.id == e.id ? s.copyWith(activa: true) : s).toList();
      emit(SucursalError(_m(ex), sucursales: _all));
    }
  }

  // ── Reactivar ─────────────────────────────────────────────────────────────
  Future<void> _onReactivar(SucursalReactivarRequested e,
      Emitter<SucursalState> emit) async {
    _all = _all.map((s) => s.id == e.id ? s.copyWith(activa: true) : s).toList();
    emit(SucursalLoaded(_all));
    try {
      final reactivada = await repo.reactivar(e.id);
      _all = _all.map((s) => s.id == e.id ? reactivada : s).toList();
      emit(SucursalLoaded(_all, message: 'Sucursal reactivada correctamente'));
    } on Exception catch (ex) {
      _all = _all.map((s) => s.id == e.id ? s.copyWith(activa: false) : s).toList();
      emit(SucursalError(_m(ex), sucursales: _all));
    }
  }

  String _m(Exception e) => e.toString().replaceAll('Exception: ', '');
}