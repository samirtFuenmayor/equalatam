abstract class AuthRepository {
  Future<bool> login(String email, String password);
  Future<void> saveToken(String token);
  Future<String?> getToken();
}
