// lib/src/features/auth/presentation/bloc/auth_state.dart
part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthRegistered extends AuthState {
  final String username;
  final String password;
  AuthRegistered({required this.username, required this.password});
}

class AuthSuccess extends AuthState {
  final String role;
  final bool mustChangePassword;
  AuthSuccess({required this.role, this.mustChangePassword = false});
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

// Login exitoso pero debe cambiar contraseña → redirige a change_password_page
class AuthMustChangePassword extends AuthState {}

// Contraseña cambiada correctamente → redirige al dashboard
class AuthPasswordChanged extends AuthState {
  final String role;
  AuthPasswordChanged({required this.role});
}