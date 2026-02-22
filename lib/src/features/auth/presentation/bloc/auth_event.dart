// lib/src/features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

abstract class AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;
  LoginSubmitted({required this.username, required this.password});
}

class RegisterSubmitted extends AuthEvent {
  final String tipoIdentificacion;
  final String numeroIdentificacion;
  final String nombres;
  final String apellidos;
  final String email;
  final String telefono;
  final String pais;
  final String ciudad;
  final String direccion;
  final String password;

  RegisterSubmitted({
    required this.tipoIdentificacion,
    required this.numeroIdentificacion,
    required this.nombres,
    required this.apellidos,
    required this.email,
    required this.telefono,
    required this.pais,
    required this.ciudad,
    required this.direccion,
    required this.password,
  });
}

class LogoutRequested extends AuthEvent {}