// lib/src/features/auth/presentation/pages/login_page.dart
// CAMBIO: solo se actualizó el BlocListener para manejar AuthMustChangePassword
// El diseño NO se modificó en absoluto

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../bloc/auth_bloc.dart';
import 'register_page.dart';

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
  final _formKey  = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool  _obscure  = true;

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
        ctx.go('/dashboard');
    }
  }

  void _openRegister(BuildContext ctx) {
    final isWide = MediaQuery.of(ctx).size.width >= 800;

    if (isWide) {
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: ctx.read<AuthBloc>(),
          child: const Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: SizedBox(
              width: 560,
              child: RegisterContent(),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: ctx.read<AuthBloc>(),
          child: const _RegisterSheet(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthSuccess) {
          _redirectByRole(ctx, state.role);
        }

        // ── NUEVO: usuario debe cambiar contraseña ──────────────────────────
        if (state is AuthMustChangePassword) {
          ctx.go('/auth/cambiar-password');
        }

        if (state is AuthRegistered) {
          ctx.read<AuthBloc>().add(LoginSubmitted(
            username: state.username,
            password: state.password,
          ));
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
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
          ));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, constraints) => constraints.maxWidth >= 800
                ? _DesktopLayout(
              formKey: _formKey,
              userCtrl: _userCtrl,
              passCtrl: _passCtrl,
              obscure: _obscure,
              onToggle:   () => setState(() => _obscure = !_obscure),
              onSubmit:   _submit,
              onRegister: () => _openRegister(ctx),
            )
                : _MobileLayout(
              formKey: _formKey,
              userCtrl: _userCtrl,
              passCtrl: _passCtrl,
              obscure: _obscure,
              onToggle:   () => setState(() => _obscure = !_obscure),
              onSubmit:   _submit,
              onRegister: () => _openRegister(ctx),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── LAYOUT DESKTOP ────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl;
  final bool obscure;
  final VoidCallback onToggle, onSubmit, onRegister;

  const _DesktopLayout({
    required this.formKey, required this.userCtrl, required this.passCtrl,
    required this.obscure, required this.onToggle,
    required this.onSubmit, required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
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
              Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 30)),
              const SizedBox(height: 28),
              const Text('Equalatam',
                  style: TextStyle(color: Colors.white, fontSize: 42,
                      fontWeight: FontWeight.bold, letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('Tu paquete, nuestra prioridad',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 16)),
              const SizedBox(height: 56),
              ..._features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(f.$1,
                          color: Colors.white.withOpacity(0.9), size: 18)),
                  const SizedBox(width: 14),
                  Text(f.$2,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 14)),
                ]),
              )),
              const Spacer(),
              Text('© 2025 Equalatam. Todos los derechos reservados.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 11)),
            ],
          ),
        ),
      ),
      Expanded(
        flex: 4,
        child: Container(
          color: const Color(0xFFF5F6FA),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _LoginForm(
                  formKey: formKey, userCtrl: userCtrl, passCtrl: passCtrl,
                  obscure: obscure, onToggle: onToggle,
                  onSubmit: onSubmit, onRegister: onRegister,
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── LAYOUT MÓVIL ─────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl;
  final bool obscure;
  final VoidCallback onToggle, onSubmit, onRegister;

  const _MobileLayout({
    required this.formKey, required this.userCtrl, required this.passCtrl,
    required this.obscure, required this.onToggle,
    required this.onSubmit, required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 52, 28, 40),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
              borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(32),
                  bottomRight: Radius.circular(32))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Colors.white, size: 26)),
            const SizedBox(height: 18),
            const Text('Equalatam',
                style: TextStyle(color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Tu paquete, nuestra prioridad',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 14)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _LoginForm(
            formKey: formKey, userCtrl: userCtrl, passCtrl: passCtrl,
            obscure: obscure, onToggle: onToggle,
            onSubmit: onSubmit, onRegister: onRegister,
          ),
        ),
      ]),
    );
  }
}

// ─── FORMULARIO DE LOGIN ──────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl;
  final bool obscure;
  final VoidCallback onToggle, onSubmit, onRegister;

  const _LoginForm({
    required this.formKey, required this.userCtrl, required this.passCtrl,
    required this.obscure, required this.onToggle,
    required this.onSubmit, required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Bienvenido de nuevo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                letterSpacing: -0.3)),
        const SizedBox(height: 6),
        const Text('Ingresa tus credenciales para continuar',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
        const SizedBox(height: 36),

        const Text('Usuario',
            style: TextStyle(fontWeight: FontWeight.w600,
                fontSize: 13, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: userCtrl,
          textInputAction: TextInputAction.next,
          decoration: _inputDeco(
              hint: 'Cédula, RUC o usuario asignado',
              icon: Icons.person_outline_rounded),
          validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Ingresa tu usuario' : null,
        ),
        const SizedBox(height: 20),

        const Text('Contraseña',
            style: TextStyle(fontWeight: FontWeight.w600,
                fontSize: 13, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: passCtrl,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
          decoration: _inputDeco(
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: onToggle,
              icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: const Color(0xFF9CA3AF)),
            ),
          ),
          validator: (v) =>
          (v == null || v.length < 4) ? 'Contraseña requerida' : null,
        ),
        const SizedBox(height: 32),

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
                    ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Iniciar sesión',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onRegister,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A237E),
              side: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('¿Cliente nuevo? Regístrate aquí',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF01579B).withOpacity(0.2))),
          child: const Column(children: [
            _RoleRow(icon: Icons.person_rounded,
                color: Color(0xFF2E7D32),
                text: 'Cliente → Mis pedidos y cotizador'),
            SizedBox(height: 8),
            _RoleRow(icon: Icons.badge_rounded,
                color: Color(0xFF1A237E),
                text: 'Empleado / Admin → Panel completo'),
            SizedBox(height: 8),
            _RoleRow(icon: Icons.delivery_dining_rounded,
                color: Color(0xFFFF6F00),
                text: 'Repartidor → Gestión de entregas'),
          ]),
        ),
      ]),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, size: 20, color: const Color(0xFF9CA3AF))),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC62828))),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}

class _RoleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _RoleRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 14, color: color)),
    const SizedBox(width: 10),
    Text(text,
        style: const TextStyle(color: Color(0xFF01579B), fontSize: 12)),
  ]);
}

const _features = [
  (Icons.track_changes_rounded,  'Rastrea paquetes en tiempo real'),
  (Icons.calculate_rounded,      'Cotiza envíos al instante'),
  (Icons.notifications_rounded,  'Notificaciones automáticas'),
  (Icons.security_rounded,       'Autenticación segura con JWT'),
  (Icons.devices_rounded,        'Web, Android e iOS'),
];

class _RegisterSheet extends StatelessWidget {
  const _RegisterSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        const Flexible(child: RegisterContent()),
      ]),
    );
  }
}