// lib/src/features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

abstract class AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;
  LoginSubmitted({required this.username, required this.password});
}

class LogoutRequested extends AuthEvent {}