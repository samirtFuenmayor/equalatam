// lib/src/features/auth/presentation/bloc/auth_state.dart
part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

/// Registro exitoso — lleva username y password para hacer auto-login
class AuthRegistered extends AuthState {
  final String username;
  final String password;
  AuthRegistered({required this.username, required this.password});
}

class AuthSuccess extends AuthState {
  final String role;
  AuthSuccess({required this.role});
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}