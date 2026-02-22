// lib/src/features/auth/domain/repositories/auth_repository.dart

abstract class AuthRepository {
  /// Retorna el rol del usuario si el login es exitoso, lanza Exception si falla
  Future<String> login(String username, String password);

  Future<void>    saveToken(String token);
  Future<String?> getToken();
  Future<void>    saveRole(String role);
  Future<String?> getRole();
  Future<void>    logout();
}