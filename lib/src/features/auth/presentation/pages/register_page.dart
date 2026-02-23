// lib/src/features/auth/presentation/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

/// Contenido del registro — se reutiliza tanto en Dialog (web) como en BottomSheet (móvil)
class RegisterContent extends StatefulWidget {
  const RegisterContent({super.key});

  @override
  State<RegisterContent> createState() => _RegisterContentState();
}

class _RegisterContentState extends State<RegisterContent> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _idCtrl      = TextEditingController();
  final _nomCtrl     = TextEditingController();
  final _apCtrl      = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _telCtrl     = TextEditingController();
  final _ciudadCtrl  = TextEditingController();
  final _dirCtrl     = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _tipoId  = 'CEDULA';
  String _pais    = 'Ecuador';
  bool   _obscure = true;
  int    _step    = 0; // 0=Identificación  1=Datos  2=Seguridad

  final _tipos  = ['CEDULA', 'RUC', 'PASAPORTE'];
  final _paises = ['Ecuador', 'Estados Unidos', 'Canadá', 'España', 'Otro'];

  @override
  void dispose() {
    for (final c in [_idCtrl, _nomCtrl, _apCtrl, _emailCtrl, _telCtrl,
      _ciudadCtrl, _dirCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        return _idCtrl.text.trim().isNotEmpty;
      case 1:
        return _nomCtrl.text.trim().isNotEmpty &&
            _apCtrl.text.trim().isNotEmpty &&
            _emailCtrl.text.trim().isNotEmpty;
      case 2:
        return _passCtrl.text.length >= 6 &&
            _passCtrl.text == _confirmCtrl.text;
      default:
        return true;
    }
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _submit() {
    if (_passCtrl.text != _confirmCtrl.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    context.read<AuthBloc>().add(RegisterSubmitted(
      tipoIdentificacion:   _tipoId,
      numeroIdentificacion: _idCtrl.text.trim(),
      nombres:    _nomCtrl.text.trim(),
      apellidos:  _apCtrl.text.trim(),
      email:      _emailCtrl.text.trim(),
      telefono:   _telCtrl.text.trim(),
      pais:       _pais,
      ciudad:     _ciudadCtrl.text.trim(),
      direccion:  _dirCtrl.text.trim(),
      password:   _passCtrl.text,
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        // El registro exitoso lo maneja el login_page con auto-login
        // Solo cerramos el modal
        if (state is AuthRegistered || state is AuthSuccess) {
          Navigator.of(ctx, rootNavigator: true).pop();
        }
        if (state is AuthFailure) {
          _showError(state.message);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Crear cuenta',
                          style: TextStyle(fontSize: 22,
                              fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                      const SizedBox(height: 2),
                      Text('Tu usuario será tu número de ${_tipoId.toLowerCase()}',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ]),
              const SizedBox(height: 20),

              // Indicador de pasos
              _StepIndicator(current: _step),
              const SizedBox(height: 24),

              // Contenido del paso actual
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _stepContent(),
                ),
              ),
              const SizedBox(height: 28),

              // Botones
              Row(children: [
                if (_step > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A237E),
                        side: const BorderSide(color: Color(0xFF1A237E)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Atrás',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (_, state) {
                      final loading = state is AuthLoading;
                      return SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: loading
                              ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : Text(
                              _step < 2 ? 'Siguiente' : 'Crear mi cuenta',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0: return _StepIdentificacion(
          tipoId: _tipoId, idCtrl: _idCtrl, pais: _pais,
          tipos: _tipos, paises: _paises,
          onTipoChanged: (v) => setState(() => _tipoId = v),
          onPaisChanged: (v) => setState(() => _pais   = v));
      case 1: return _StepDatos(
          nomCtrl: _nomCtrl, apCtrl: _apCtrl, emailCtrl: _emailCtrl,
          telCtrl: _telCtrl, ciudadCtrl: _ciudadCtrl, dirCtrl: _dirCtrl);
      default: return _StepSeguridad(
          passCtrl: _passCtrl, confirmCtrl: _confirmCtrl,
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure));
    }
  }
}

// ─── Indicador de pasos ───────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  static const _labels = ['Identificación', 'Datos', 'Seguridad'];
  static const _icons  = [
    Icons.badge_outlined,
    Icons.person_outline,
    Icons.lock_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final done   = i < current;
        final active = i == current;
        final color  = done || active
            ? const Color(0xFF1A237E)
            : const Color(0xFFE5E7EB);

        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF1A237E)
                        : active
                        ? Colors.white
                        : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                      : Icon(_icons[i],
                      color: active
                          ? const Color(0xFF1A237E)
                          : const Color(0xFF9CA3AF),
                      size: 16),
                ),
                const SizedBox(height: 4),
                Text(_labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active
                          ? FontWeight.w600 : FontWeight.normal,
                      color: active
                          ? const Color(0xFF1A237E)
                          : const Color(0xFF9CA3AF),
                    )),
              ]),
            ),
            if (i < _labels.length - 1)
              Expanded(
                child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: done
                        ? const Color(0xFF1A237E)
                        : const Color(0xFFE5E7EB)),
              ),
          ]),
        );
      }),
    );
  }
}

// ─── PASO 1: Identificación ───────────────────────────────────────────────────
class _StepIdentificacion extends StatelessWidget {
  final String tipoId, pais;
  final TextEditingController idCtrl;
  final List<String> tipos, paises;
  final void Function(String) onTipoChanged, onPaisChanged;

  const _StepIdentificacion({
    required this.tipoId, required this.idCtrl, required this.pais,
    required this.tipos, required this.paises,
    required this.onTipoChanged, required this.onPaisChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Tipo de identificación'),
      const SizedBox(height: 10),

      // Selector de tipo
      Row(children: tipos.map((t) {
        final selected = t == tipoId;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: t != tipos.last ? 8 : 0),
          child: GestureDetector(
            onTap: () => onTipoChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1A237E)
                      : const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: selected
                          ? const Color(0xFF1A237E)
                          : const Color(0xFFE5E7EB))),
              child: Text(t,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF6B7280))),
            ),
          ),
        ));
      }).toList()),
      const SizedBox(height: 16),

      _label('Número de ${tipoId.toLowerCase()}'),
      const SizedBox(height: 8),
      TextFormField(
        controller: idCtrl,
        keyboardType: TextInputType.number,
        decoration: _deco(
            hint: tipoId == 'CEDULA' ? 'Ej: 1104567890'
                : tipoId == 'RUC'    ? 'Ej: 1104567890001'
                : 'Número de pasaporte',
            icon: Icons.badge_outlined),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Ingresa tu número de identificación' : null,
      ),
      const SizedBox(height: 16),

      _label('País de residencia'),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: pais,
        decoration: _deco(hint: 'Selecciona tu país', icon: Icons.public_rounded),
        items: paises.map((p) =>
            DropdownMenuItem(value: p, child: Text(p))).toList(),
        onChanged: (v) => onPaisChanged(v!),
      ),

      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF01579B)),
          SizedBox(width: 10),
          Expanded(child: Text(
              'Tu número de identificación será tu usuario para iniciar sesión.',
              style: TextStyle(fontSize: 12, color: Color(0xFF01579B)))),
        ]),
      ),
    ]);
  }
}

// ─── PASO 2: Datos personales ─────────────────────────────────────────────────
class _StepDatos extends StatelessWidget {
  final TextEditingController nomCtrl, apCtrl, emailCtrl,
      telCtrl, ciudadCtrl, dirCtrl;

  const _StepDatos({
    required this.nomCtrl, required this.apCtrl, required this.emailCtrl,
    required this.telCtrl, required this.ciudadCtrl, required this.dirCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nombres *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: nomCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _deco(hint: 'Juan Carlos', icon: Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Apellidos *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: apCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _deco(hint: 'Pérez López', icon: Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ])),
      ]),
      const SizedBox(height: 14),

      _label('Correo electrónico *'),
      const SizedBox(height: 8),
      TextFormField(
        controller: emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: _deco(hint: 'ejemplo@correo.com', icon: Icons.email_outlined),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Requerido';
          if (!v.contains('@') || !v.contains('.')) return 'Email inválido';
          return null;
        },
      ),
      const SizedBox(height: 14),

      _label('Teléfono'),
      const SizedBox(height: 8),
      TextFormField(
        controller: telCtrl,
        keyboardType: TextInputType.phone,
        decoration: _deco(hint: '0999123456', icon: Icons.phone_outlined),
      ),
      const SizedBox(height: 14),

      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Ciudad'),
              const SizedBox(height: 8),
              TextFormField(
                controller: ciudadCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _deco(hint: 'Loja', icon: Icons.location_city_outlined),
              ),
            ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Dirección'),
              const SizedBox(height: 8),
              TextFormField(
                controller: dirCtrl,
                decoration: _deco(hint: 'Av. Principal...', icon: Icons.home_outlined),
              ),
            ])),
      ]),
    ]);
  }
}

// ─── PASO 3: Seguridad ────────────────────────────────────────────────────────
class _StepSeguridad extends StatelessWidget {
  final TextEditingController passCtrl, confirmCtrl;
  final bool obscure;
  final VoidCallback onToggle;

  const _StepSeguridad({
    required this.passCtrl, required this.confirmCtrl,
    required this.obscure, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(
              'Ya casi terminas. Crea una contraseña segura para tu cuenta.',
              style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13))),
        ]),
      ),
      const SizedBox(height: 20),

      _label('Contraseña *'),
      const SizedBox(height: 8),
      TextFormField(
        controller: passCtrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: 'Mínimo 6 caracteres',
          prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.lock_outline_rounded,
                  size: 20, color: Color(0xFF9CA3AF))),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: const Color(0xFF9CA3AF))),
          filled: true, fillColor: Colors.white,
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
        ),
        validator: (v) =>
        (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
      ),
      const SizedBox(height: 14),

      _label('Confirmar contraseña *'),
      const SizedBox(height: 8),
      TextFormField(
        controller: confirmCtrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: 'Repite tu contraseña',
          prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.lock_outline_rounded,
                  size: 20, color: Color(0xFF9CA3AF))),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true, fillColor: Colors.white,
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
        ),
        validator: (v) => (v != passCtrl.text)
            ? 'Las contraseñas no coinciden' : null,
      ),
    ]);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
Widget _label(String text) => Text(text,
    style: const TextStyle(
        fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151)));

InputDecoration _deco({required String hint, required IconData icon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(icon, size: 20, color: const Color(0xFF9CA3AF))),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  );
}