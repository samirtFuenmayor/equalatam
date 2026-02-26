// lib/src/features/auth/data/repositories/auth_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client _client = http.Client();

  static const _tokenKey           = 'eq_token';
  static const _roleKey            = 'eq_role';
  static const _mustChangePassKey  = 'eq_must_change_pass';

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

    // Guardar mustChangePassword para redirigir después del login
    final mustChange = data['mustChangePassword'] as bool? ?? false;

    await saveToken(token);
    await saveRole(role);
    await _saveMustChangePassword(mustChange);

    return role;
  }

  // ─── REGISTRO DE CLIENTE ───────────────────────────────────────────────────
  // Ahora apunta al nuevo endpoint /api/auth/registro-cliente
  // y acepta titularId (UUID) y parentesco opcionales
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
    String? titularId,       // UUID del titular (opcional)
    String? parentesco,      // HIJO, CONYUGE, etc. (opcional)
  }) async {
    final body = <String, dynamic>{
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
    };

    if (titularId != null && titularId.isNotEmpty) {
      body['titularId']  = titularId;
      body['parentesco'] = parentesco ?? 'OTRO';
    }

    final http.Response res;
    try {
      res = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/registro-cliente'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
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

  // ─── BUSCAR CLIENTE POR CÉDULA (para afiliación) ───────────────────────────
  // Retorna un Map con { id, nombres, apellidos } o lanza Exception si no existe
  Future<Map<String, dynamic>> buscarClientePorCedula(String cedula) async {
    final http.Response res;
    try {
      res = await _client.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/clientes/identificacion/$cedula'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {
      throw Exception('Sin conexión al servidor.');
    }

    if (res.statusCode == 404) {
      throw Exception('No se encontró ningún cliente con esa cédula.');
    }
    if (res.statusCode != 200) {
      throw Exception('Error al buscar cliente (${res.statusCode})');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return {
      'id':       data['id'] as String,
      'nombres':  data['nombres'] as String,
      'apellidos': data['apellidos'] as String,
      'casillero': data['casillero'] as String? ?? '',
    };
  }

  // ─── CAMBIAR CONTRASEÑA (mustChangePassword = true) ────────────────────────
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No autenticado');

    final http.Response res;
    try {
      res = await _client.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/cambiar-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'passwordActual': passwordActual,
          'passwordNueva':  passwordNueva,
        }),
      );
    } catch (_) {
      throw Exception('Sin conexión al servidor.');
    }

    if (res.statusCode != 200) {
      String msg = 'Error al cambiar la contraseña';
      try {
        final b = jsonDecode(utf8.decode(res.bodyBytes));
        if (b['message'] != null) msg = b['message'];
      } catch (_) {}
      throw Exception(msg);
    }

    // Ya cambió → limpiar la bandera
    await _saveMustChangePassword(false);
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

  Future<void> _saveMustChangePassword(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mustChangePassKey, value);
  }

  Future<bool> getMustChangePassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mustChangePassKey) ?? false;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_mustChangePassKey);
  }
}