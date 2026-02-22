// lib/src/features/auth/presentation/bloc/auth_bloc.dart
import 'package:bloc/bloc.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(LoginSubmitted e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final role = await authRepository.login(e.username, e.password);
      emit(AuthSuccess(role: role));
    } on Exception catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegister(RegisterSubmitted e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.register(
        tipoIdentificacion:   e.tipoIdentificacion,
        numeroIdentificacion: e.numeroIdentificacion,
        nombres:    e.nombres,
        apellidos:  e.apellidos,
        email:      e.email,
        telefono:   e.telefono,
        pais:       e.pais,
        ciudad:     e.ciudad,
        direccion:  e.direccion,
        password:   e.password,
      );
      emit(AuthRegistered(
        username: e.numeroIdentificacion,
        password: e.password,
      ));
    } on Exception catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogout(LogoutRequested _, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(AuthInitial());
  }
}