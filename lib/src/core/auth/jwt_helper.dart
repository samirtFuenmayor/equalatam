import 'dart:convert';

class JwtHelper {
  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded);
  }

  static List<String> getRoles(String token) {
    final payload = decode(token);
    final roles = payload['roles'];
    if (roles == null) return [];
    return List<String>.from(roles);
  }

  static bool hasRole(String token, String role) {
    return getRoles(token).contains(role);
  }

  static bool isCliente(String token) => hasRole(token, 'CLIENTE');
  static bool isAdmin(String token)   => hasRole(token, 'ADMIN');
  static bool isCajero(String token)  => hasRole(token, 'CAJERO');
  static bool isSupervisor(String token) => hasRole(token, 'SUPERVISOR');
}