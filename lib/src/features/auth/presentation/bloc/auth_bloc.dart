// lib/src/features/auth/presentation/bloc/auth_bloc.dart
import 'package:bloc/bloc.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // login() retorna el rol del usuario
      final role = await authRepository.login(event.username, event.password);
      emit(AuthSuccess(role: role));
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(msg));
    } catch (_) {
      emit(AuthFailure('Error inesperado. Intenta de nuevo.'));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(AuthInitial());
  }
}