import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  // Mock implementation: reemplazar con llamadas HTTP a Spring Boot

  @override
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));
    // Mock: acepta cualquier correo que termine en @demo.com y pass '123456'
    if (email.endsWith('@demo.com') && password == '123456') {
      return true;
    }
    return false;
  }

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
