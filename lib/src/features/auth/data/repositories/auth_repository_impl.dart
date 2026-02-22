// lib/src/features/auth/data/repositories/auth_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client _client = http.Client();

  static const _tokenKey = 'eq_token';
  static const _roleKey  = 'eq_role';

  // ─── LOGIN ─────────────────────────────────────────────────────────────────
  @override
  Future<String> login(String username, String password) async {
    final http.Response res;
    try {
      res = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
    } catch (_) {
      throw Exception('Sin conexión al servidor. Verifica tu internet.');
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Usuario o contraseña incorrectos');
    }
    if (res.statusCode != 200) {
      String msg = 'Error del servidor (${res.statusCode})';
      try {
        final b = jsonDecode(res.body);
        if (b['message'] != null) msg = b['message'];
      } catch (_) {}
      throw Exception(msg);
    }

    final data  = jsonDecode(res.body) as Map<String, dynamic>;
    final token = data['token'] as String;

    final rolesList = (data['roles'] as List<dynamic>? ?? [])
        .map((e) => e.toString().toUpperCase())
        .toList();

    String role = 'CLIENTE';
    if (rolesList.any((r) => r.contains('ADMIN')))       role = 'ADMIN';
    else if (rolesList.any((r) => r.contains('SUPER')))  role = 'SUPERVISOR';
    else if (rolesList.any((r) => r.contains('REPART'))) role = 'REPARTIDOR';
    else if (rolesList.any((r) => r.contains('EMPL')))   role = 'EMPLEADO';

    await saveToken(token);
    await saveRole(role);
    return role;
  }

  // ─── REGISTRO DE CLIENTE ───────────────────────────────────────────────────
  @override
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
  }) async {
    final http.Response res;
    try {
      res = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/api/clientes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tipoIdentificacion':   tipoIdentificacion,
          'numeroIdentificacion': numeroIdentificacion,
          'nombres':              nombres,
          'apellidos':            apellidos,
          'email':                email,
          'telefono':             telefono,
          'pais':                 pais,
          'ciudad':               ciudad,
          'direccion':            direccion,
          'password':             password,
        }),
      );
    } catch (_) {
      throw Exception('Sin conexión al servidor. Verifica tu internet.');
    }

    if (res.statusCode == 409) {
      throw Exception('Ya existe una cuenta con ese número de identificación.');
    }
    if (res.statusCode != 200 && res.statusCode != 201) {
      String msg = 'Error al crear la cuenta (${res.statusCode})';
      try {
        final b = jsonDecode(utf8.decode(res.bodyBytes));
        if (b['message'] != null) msg = b['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // ─── STORAGE ───────────────────────────────────────────────────────────────
  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  @override
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
  }
}