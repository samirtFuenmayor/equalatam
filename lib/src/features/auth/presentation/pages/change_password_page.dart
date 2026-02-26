// lib/src/features/auth/presentation/pages/change_password_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../bloc/auth_bloc.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AuthBloc>(),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _formKey      = GlobalKey<FormState>();
  final _actualCtrl   = TextEditingController();
  final _nuevaCtrl    = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool  _obscureActual = true;
  bool  _obscureNueva  = true;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(CambiarPasswordRequested(
      passwordActual: _actualCtrl.text,
      passwordNueva:  _nuevaCtrl.text,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthPasswordChanged) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('¡Contraseña actualizada correctamente!'),
            ]),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
          ));
          _redirectByRole(ctx, state.role);
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(state.message)),
            ]),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
              actualCtrl: _actualCtrl,
              nuevaCtrl: _nuevaCtrl,
              confirmCtrl: _confirmCtrl,
              obscureActual: _obscureActual,
              obscureNueva: _obscureNueva,
              onToggleActual: () =>
                  setState(() => _obscureActual = !_obscureActual),
              onToggleNueva: () =>
                  setState(() => _obscureNueva = !_obscureNueva),
              onSubmit: _submit,
            )
                : _MobileLayout(
              formKey: _formKey,
              actualCtrl: _actualCtrl,
              nuevaCtrl: _nuevaCtrl,
              confirmCtrl: _confirmCtrl,
              obscureActual: _obscureActual,
              obscureNueva: _obscureNueva,
              onToggleActual: () =>
                  setState(() => _obscureActual = !_obscureActual),
              onToggleNueva: () =>
                  setState(() => _obscureNueva = !_obscureNueva),
              onSubmit: _submit,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── DESKTOP ──────────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController actualCtrl, nuevaCtrl, confirmCtrl;
  final bool obscureActual, obscureNueva;
  final VoidCallback onToggleActual, onToggleNueva, onSubmit;

  const _DesktopLayout({
    required this.formKey,
    required this.actualCtrl, required this.nuevaCtrl, required this.confirmCtrl,
    required this.obscureActual, required this.obscureNueva,
    required this.onToggleActual, required this.onToggleNueva,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Panel izquierdo — igual al login
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
                  child: const Icon(Icons.lock_reset_rounded,
                      color: Colors.white, size: 30)),
              const SizedBox(height: 28),
              const Text('Cambia tu\ncontraseña',
                  style: TextStyle(color: Colors.white, fontSize: 38,
                      fontWeight: FontWeight.bold, letterSpacing: -1,
                      height: 1.1)),
              const SizedBox(height: 16),
              Text(
                'Tu cuenta fue creada por un administrador.\n'
                    'Por seguridad, debes establecer tu propia contraseña antes de continuar.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65), fontSize: 14,
                    height: 1.6),
              ),
              const SizedBox(height: 40),
              _SecurityTip(
                  icon: Icons.check_circle_outline,
                  text: 'Usa al menos 8 caracteres'),
              const SizedBox(height: 12),
              _SecurityTip(
                  icon: Icons.check_circle_outline,
                  text: 'Combina letras y números'),
              const SizedBox(height: 12),
              _SecurityTip(
                  icon: Icons.check_circle_outline,
                  text: 'No compartas tu contraseña con nadie'),
              const Spacer(),
              Text('© 2025 Equalatam. Todos los derechos reservados.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 11)),
            ],
          ),
        ),
      ),
      // Panel derecho — formulario
      Expanded(
        flex: 4,
        child: Container(
          color: const Color(0xFFF5F6FA),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _PasswordForm(
                  formKey: formKey,
                  actualCtrl: actualCtrl,
                  nuevaCtrl: nuevaCtrl,
                  confirmCtrl: confirmCtrl,
                  obscureActual: obscureActual,
                  obscureNueva: obscureNueva,
                  onToggleActual: onToggleActual,
                  onToggleNueva: onToggleNueva,
                  onSubmit: onSubmit,
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── MÓVIL ────────────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController actualCtrl, nuevaCtrl, confirmCtrl;
  final bool obscureActual, obscureNueva;
  final VoidCallback onToggleActual, onToggleNueva, onSubmit;

  const _MobileLayout({
    required this.formKey,
    required this.actualCtrl, required this.nuevaCtrl, required this.confirmCtrl,
    required this.obscureActual, required this.obscureNueva,
    required this.onToggleActual, required this.onToggleNueva,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [
        // Header
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
                child: const Icon(Icons.lock_reset_rounded,
                    color: Colors.white, size: 26)),
            const SizedBox(height: 18),
            const Text('Cambia tu contraseña',
                style: TextStyle(color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text(
              'Tu cuenta fue creada por un administrador. '
                  'Establece tu propia contraseña para continuar.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13, height: 1.5),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _PasswordForm(
            formKey: formKey,
            actualCtrl: actualCtrl,
            nuevaCtrl: nuevaCtrl,
            confirmCtrl: confirmCtrl,
            obscureActual: obscureActual,
            obscureNueva: obscureNueva,
            onToggleActual: onToggleActual,
            onToggleNueva: onToggleNueva,
            onSubmit: onSubmit,
          ),
        ),
      ]),
    );
  }
}

// ─── FORMULARIO ───────────────────────────────────────────────────────────────
class _PasswordForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController actualCtrl, nuevaCtrl, confirmCtrl;
  final bool obscureActual, obscureNueva;
  final VoidCallback onToggleActual, onToggleNueva, onSubmit;

  const _PasswordForm({
    required this.formKey,
    required this.actualCtrl, required this.nuevaCtrl, required this.confirmCtrl,
    required this.obscureActual, required this.obscureNueva,
    required this.onToggleActual, required this.onToggleNueva,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        const Text('Establece tu contraseña',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                letterSpacing: -0.3)),
        const SizedBox(height: 6),
        const Text('Esta será la contraseña que usarás para ingresar',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
        const SizedBox(height: 32),

        // Aviso
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFF8F00).withOpacity(0.3))),
          child: const Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF8F00), size: 18),
            SizedBox(width: 10),
            Expanded(child: Text(
                'Ingresa la contraseña temporal que te proporcionó '
                    'el administrador como contraseña actual.',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF5D4037)))),
          ]),
        ),
        const SizedBox(height: 24),

        // Contraseña actual (temporal)
        _fieldLabel('Contraseña actual (temporal)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: actualCtrl,
          obscureText: obscureActual,
          textInputAction: TextInputAction.next,
          decoration: _inputDeco(
            hint: 'Tu contraseña temporal',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: onToggleActual,
              icon: Icon(
                  obscureActual
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20, color: const Color(0xFF9CA3AF)),
            ),
          ),
          validator: (v) =>
          (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
        ),
        const SizedBox(height: 20),

        // Nueva contraseña
        _fieldLabel('Nueva contraseña'),
        const SizedBox(height: 8),
        TextFormField(
          controller: nuevaCtrl,
          obscureText: obscureNueva,
          textInputAction: TextInputAction.next,
          decoration: _inputDeco(
            hint: 'Mínimo 8 caracteres',
            icon: Icons.lock_reset_rounded,
            suffix: IconButton(
              onPressed: onToggleNueva,
              icon: Icon(
                  obscureNueva
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20, color: const Color(0xFF9CA3AF)),
            ),
          ),
          validator: (v) =>
          (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
        ),
        const SizedBox(height: 20),

        // Confirmar nueva contraseña
        _fieldLabel('Confirmar nueva contraseña'),
        const SizedBox(height: 8),
        TextFormField(
          controller: confirmCtrl,
          obscureText: obscureNueva,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
          decoration: _inputDeco(
            hint: 'Repite tu nueva contraseña',
            icon: Icons.lock_rounded,
          ),
          validator: (v) => (v != nuevaCtrl.text)
              ? 'Las contraseñas no coinciden' : null,
        ),
        const SizedBox(height: 32),

        // Botón
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
                    Text('Guardar contraseña',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF374151)));

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
          borderSide:
          const BorderSide(color: Color(0xFF1A237E), width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC62828))),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}

// ─── Widget tip de seguridad ──────────────────────────────────────────────────
class _SecurityTip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SecurityTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: Colors.white.withOpacity(0.6), size: 16),
    const SizedBox(width: 10),
    Text(text,
        style: TextStyle(
            color: Colors.white.withOpacity(0.7), fontSize: 13)),
  ]);
}