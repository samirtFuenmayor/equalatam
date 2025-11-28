class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa el correo';
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!regex.hasMatch(value)) return 'Correo no válido';
    return null;
  }

  static String? minLength(String? value, int min, String field) {
    if (value == null || value.length < min) return '$field debe tener al menos $min caracteres';
    return null;
  }
}
