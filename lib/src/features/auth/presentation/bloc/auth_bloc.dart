import 'package:bloc/bloc.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter emit) async {
    emit(AuthLoading());
    try {
      final ok = await authRepository.login(event.email, event.password);
      if (!ok) {
        emit(AuthFailure('Credenciales incorrectas'));
        return;
      }
      // Mock token
      await authRepository.saveToken('mock-token-123');
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure('Error de conexión'));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter emit) async {
    emit(AuthInitial());
  }
}
