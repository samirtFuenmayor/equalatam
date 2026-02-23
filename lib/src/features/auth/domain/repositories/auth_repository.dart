// lib/src/features/auth/domain/repositories/auth_repository.dart

abstract class AuthRepository {
  /// Login → retorna el rol si es exitoso, lanza Exception si falla
  Future<String> login(String username, String password);

  /// Registro de cliente → lanza Exception si falla
  Future<void> register({
    required String tipoIdentificacion,
    required String numeroIdentificacion,
    required String nombres,
    required String apellidos,
    required String email,
    required String telefono,
    required String pais,
    required String ciudad,
    required String direccion,
    required String password,
  });

  Future<void>    saveToken(String token);
  Future<String?> getToken();
  Future<void>    saveRole(String role);
  Future<String?> getRole();
  Future<void>    logout();
}