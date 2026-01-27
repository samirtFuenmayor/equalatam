import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client _client = http.Client();

  @override
  Future<bool> login(String email, String password) async {
    final res = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': email, // 👈 aquí el truco
        'password': password,
      }),
    );

    if (res.statusCode != 200) {
      return false;
    }

    final data = jsonDecode(res.body);

    final token = data['token'] as String;

    await saveToken(token);

    return true;
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

  // 🔥 NUEVO: guardar rol
  Future<void> saveRole(String roleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roleId', roleId);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('roleId');
  }
}
