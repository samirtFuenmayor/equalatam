// lib/src/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey    = GlobalKey<FormState>();
  final _userCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool  _obscure    = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginSubmitted(
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
    ));
  }

  void _redirectByRole(BuildContext ctx, String role) {
    switch (role) {
      case 'ADMIN':
      case 'SUPERVISOR':
      case 'EMPLEADO':
        ctx.go('/dashboard');
      case 'REPARTIDOR':
        ctx.go('/operations/tracking');
      default:
      // CLIENTE → cambiará cuando tengas las rutas del cliente
        ctx.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthSuccess) {
          _redirectByRole(ctx, state.role);
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: const Color(0xFFC62828),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Web / Tablet → layout dos columnas
              if (constraints.maxWidth >= 800) {
                return _DesktopLayout(
                  formKey: _formKey,
                  userCtrl: _userCtrl,
                  passCtrl: _passCtrl,
                  obscure: _obscure,
                  onToggleObscure: () =>
                      setState(() => _obscure = !_obscure),
                  onSubmit: _submit,
                );
              }
              // Móvil → layout una columna
              return _MobileLayout(
                formKey: _formKey,
                userCtrl: _userCtrl,
                passCtrl: _passCtrl,
                obscure: _obscure,
                onToggleObscure: () =>
                    setState(() => _obscure = !_obscure),
                onSubmit: _submit,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── LAYOUT DESKTOP / WEB / TABLET ────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure, onSubmit;

  const _DesktopLayout({
    required this.formKey,
    required this.userCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Panel izquierdo: marca + features
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1257), Color(0xFF1A237E), Color(0xFF3949AB)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Equalatam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu paquete, nuestra prioridad',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 56),

                // Features
                ..._features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(f.$1,
                          color: Colors.white.withOpacity(0.9), size: 18),
                    ),
                    const SizedBox(width: 14),
                    Text(f.$2,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14)),
                  ]),
                )),

                const Spacer(),
                // Footer
                Text(
                  '© 2025 Equalatam. Todos los derechos reservados.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // Panel derecho: formulario
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFFF5F6FA),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _LoginForm(
                    formKey: formKey,
                    userCtrl: userCtrl,
                    passCtrl: passCtrl,
                    obscure: obscure,
                    onToggleObscure: onToggleObscure,
                    onSubmit: onSubmit,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── LAYOUT MÓVIL ─────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure, onSubmit;

  const _MobileLayout({
    required this.formKey,
    required this.userCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con gradiente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 52, 28, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Equalatam',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu paquete, nuestra prioridad',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
              ],
            ),
          ),

          // Formulario
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: _LoginForm(
              formKey: formKey,
              userCtrl: userCtrl,
              passCtrl: passCtrl,
              obscure: obscure,
              onToggleObscure: onToggleObscure,
              onSubmit: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FORMULARIO (compartido entre layouts) ────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure, onSubmit;

  const _LoginForm({
    required this.formKey,
    required this.userCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título
          const Text(
            'Bienvenido de nuevo',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ingresa tus credenciales para continuar',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 36),

          // Campo usuario
          const Text('Usuario',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151))),
          const SizedBox(height: 8),
          TextFormField(
            controller: userCtrl,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Cédula, RUC o usuario asignado',
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.person_outline_rounded,
                    size: 20, color: Color(0xFF9CA3AF)),
              ),
              prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E2130)
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF1A237E), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: Color(0xFFC62828)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 16),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Ingresa tu usuario'
                : null,
          ),
          const SizedBox(height: 20),

          // Campo contraseña
          const Text('Contraseña',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF374151))),
          const SizedBox(height: 8),
          TextFormField(
            controller: passCtrl,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.lock_outline_rounded,
                    size: 20, color: Color(0xFF9CA3AF)),
              ),
              prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E2130)
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF1A237E), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: Color(0xFFC62828)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 16),
            ),
            validator: (v) =>
            (v == null || v.length < 4) ? 'Contraseña requerida' : null,
          ),
          const SizedBox(height: 32),

          // Botón de ingresar
          BlocBuilder<AuthBloc, AuthState>(
            builder: (_, state) {
              final loading = state is AuthLoading;
              return SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    const Color(0xFF1A237E).withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Iniciar sesión',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Divider
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('Acceso por rol',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 20),

          // Info de roles
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF01579B).withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                _RoleInfoRow(
                    icon: Icons.person_rounded,
                    color: Color(0xFF2E7D32),
                    text: 'Cliente → Mis pedidos y cotizador'),
                SizedBox(height: 8),
                _RoleInfoRow(
                    icon: Icons.badge_rounded,
                    color: Color(0xFF1A237E),
                    text: 'Empleado / Admin → Panel completo'),
                SizedBox(height: 8),
                _RoleInfoRow(
                    icon: Icons.delivery_dining_rounded,
                    color: Color(0xFFFF6F00),
                    text: 'Repartidor → Gestión de entregas'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _RoleInfoRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              color: Color(0xFF01579B), fontSize: 12)),
    ]);
  }
}

// Lista de features para el panel izquierdo (desktop)
const _features = [
  (Icons.track_changes_rounded,     'Rastrea paquetes en tiempo real'),
  (Icons.calculate_rounded,         'Cotiza envíos al instante'),
  (Icons.notifications_rounded,     'Notificaciones automáticas'),
  (Icons.security_rounded,          'Autenticación segura con JWT'),
  (Icons.devices_rounded,           'Web, Android e iOS'),
];