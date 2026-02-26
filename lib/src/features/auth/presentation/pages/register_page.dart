// lib/src/features/auth/presentation/pages/register_page.dart
import 'package:equalatam/src/features/network/presentation/data/repositories/sucursal_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../bloc/auth_bloc.dart';
import '../../../network/presentation/domain/models/sucursal_model.dart';
import '../../../network/presentation/data/repositories/despacho_repository_impl.dart';

class RegisterContent extends StatefulWidget {
  const RegisterContent({super.key});

  @override
  State<RegisterContent> createState() => _RegisterContentState();
}

class _RegisterContentState extends State<RegisterContent> {
  final _formKey    = GlobalKey<FormState>();
  final _idCtrl     = TextEditingController();
  final _nomCtrl    = TextEditingController();
  final _apCtrl     = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _dirCtrl    = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confirmCtrl= TextEditingController();

  String _tipoId  = 'CEDULA';
  String _pais    = 'Ecuador';
  bool   _obscure = true;

  // Pasos: 0=Identificación · 1=Sucursal · 2=Datos · 3=Seguridad · 4=Familia
  int _step = 0;
  static const _totalSteps = 5;

  // ─── Sucursal ──────────────────────────────────────────────────────────────
  String?              _sucursalId;
  List<SucursalModel>  _sucursales  = [];
  bool                 _loadingSuc  = false;

  // ─── Afiliación ────────────────────────────────────────────────────────────
  String? _titularId;
  String? _titularNombre;
  String  _parentesco      = 'HIJO';
  bool    _quiereAfiliarse = false;

  final _tipos      = ['CEDULA', 'RUC', 'PASAPORTE'];
  final _paises     = ['Ecuador', 'Estados Unidos', 'Canadá', 'España', 'Otro'];
  final _parentescos= ['HIJO', 'HIJA', 'CONYUGE', 'PADRE', 'MADRE',
    'HERMANO', 'HERMANA', 'AMIGO', 'OTRO'];

  @override
  void initState() {
    super.initState();
    _fetchSucursales();
  }

  Future<void> _fetchSucursales() async {
    setState(() => _loadingSuc = true);
    try {
      final repo = SucursalRepositoryImpl();
      final list = await repo.findAllActivas();
      if (mounted) setState(() { _sucursales = list; _loadingSuc = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSuc = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_idCtrl, _nomCtrl, _apCtrl, _emailCtrl, _telCtrl,
      _ciudadCtrl, _dirCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (_step < _totalSteps - 1) {
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
      nombres:   _nomCtrl.text.trim(),
      apellidos: _apCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      telefono:  _telCtrl.text.trim(),
      pais:      _pais,
      ciudad:    _ciudadCtrl.text.trim(),
      direccion: _dirCtrl.text.trim(),
      password:  _passCtrl.text,
      sucursalId: _sucursalId,
      titularId:  _quiereAfiliarse ? _titularId  : null,
      parentesco: _quiereAfiliarse ? _parentesco : null,
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
        if (state is AuthRegistered || state is AuthSuccess) {
          Navigator.of(ctx, rootNavigator: true).pop();
        }
        if (state is AuthFailure) _showError(state.message);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Crear cuenta',
                          style: TextStyle(fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 2),
                      Text(
                          'Tu usuario será tu número de ${_tipoId.toLowerCase()}',
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

              _StepIndicator(current: _step),
              const SizedBox(height: 24),

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

              // ── Botones ──────────────────────────────────────────────────
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
                              _step < _totalSteps - 1
                                  ? 'Siguiente'
                                  : 'Crear mi cuenta',
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
      case 0:
        return _StepIdentificacion(
          tipoId:        _tipoId,
          idCtrl:        _idCtrl,
          pais:          _pais,
          tipos:         _tipos,
          paises:        _paises,
          onTipoChanged: (v) => setState(() => _tipoId = v),
          onPaisChanged: (v) => setState(() => _pais   = v),
        );
      case 1:
        return _StepSucursal(
          sucursalId:        _sucursalId,
          sucursales:        _sucursales,
          loadingSuc:        _loadingSuc,
          onSucursalChanged: (v) => setState(() => _sucursalId = v),
        );
      case 2:
        return _StepDatos(
          nomCtrl:    _nomCtrl,
          apCtrl:     _apCtrl,
          emailCtrl:  _emailCtrl,
          telCtrl:    _telCtrl,
          ciudadCtrl: _ciudadCtrl,
          dirCtrl:    _dirCtrl,
        );
      case 3:
        return _StepSeguridad(
          passCtrl:    _passCtrl,
          confirmCtrl: _confirmCtrl,
          obscure:     _obscure,
          onToggle:    () => setState(() => _obscure = !_obscure),
        );
      default:
        return _StepAfiliacion(
          quiereAfiliarse:     _quiereAfiliarse,
          titularId:           _titularId,
          titularNombre:       _titularNombre,
          parentesco:          _parentesco,
          parentescos:         _parentescos,
          onToggleAfiliarse:   (v) => setState(() {
            _quiereAfiliarse = v;
            if (!v) { _titularId = null; _titularNombre = null; }
          }),
          onTitularEncontrado: (id, nombre) =>
              setState(() { _titularId = id; _titularNombre = nombre; }),
          onParentescoChanged: (v) => setState(() => _parentesco = v),
        );
    }
  }
}

// ─── Indicador de pasos — 5 pasos ─────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  static const _labels = [
    'Identificación', 'Sucursal', 'Datos', 'Seguridad', 'Familia'
  ];
  static const _icons = [
    Icons.badge_outlined,
    Icons.business_outlined,
    Icons.person_outline,
    Icons.lock_outline,
    Icons.people_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final done   = i < current;
        final active = i == current;
        final color  = (done || active)
            ? const Color(0xFF1A237E)
            : const Color(0xFFE5E7EB);

        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF1A237E)
                        : active ? Colors.white : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                      : Icon(_icons[i],
                      color: active
                          ? const Color(0xFF1A237E)
                          : const Color(0xFF9CA3AF),
                      size: 13),
                ),
                const SizedBox(height: 3),
                Text(_labels[i],
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal,
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
                    margin: const EdgeInsets.only(bottom: 16),
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

// ─── PASO 0: Identificación ───────────────────────────────────────────────────
// SIN parámetros de sucursal — eso va en su propio paso
class _StepIdentificacion extends StatelessWidget {
  final String tipoId, pais;
  final TextEditingController idCtrl;
  final List<String> tipos, paises;
  final void Function(String) onTipoChanged, onPaisChanged;

  const _StepIdentificacion({
    required this.tipoId,
    required this.idCtrl,
    required this.pais,
    required this.tipos,
    required this.paises,
    required this.onTipoChanged,
    required this.onPaisChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Tipo de identificación'),
      const SizedBox(height: 10),
      Row(children: tipos.map((t) {
        final sel = t == tipoId;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: t != tipos.last ? 8 : 0),
          child: GestureDetector(
            onTap: () => onTipoChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF1A237E)
                      : const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sel
                          ? const Color(0xFF1A237E)
                          : const Color(0xFFE5E7EB))),
              child: Text(t,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF6B7280))),
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
            hint: tipoId == 'CEDULA'
                ? 'Ej: 1104567890'
                : tipoId == 'RUC'
                ? 'Ej: 1104567890001'
                : 'Número de pasaporte',
            icon: Icons.badge_outlined),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Ingresa tu número de identificación'
            : null,
      ),
      const SizedBox(height: 16),

      _label('País de residencia'),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: pais,
        decoration:
        _deco(hint: 'Selecciona tu país', icon: Icons.public_rounded),
        items: paises
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
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

// ─── PASO 1: Sucursal ─────────────────────────────────────────────────────────
class _StepSucursal extends StatelessWidget {
  final String?             sucursalId;
  final List<SucursalModel> sucursales;
  final bool                loadingSuc;
  final void Function(String?) onSucursalChanged;

  const _StepSucursal({
    required this.sucursalId,
    required this.sucursales,
    required this.loadingSuc,
    required this.onSucursalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Banner informativo
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.business_outlined, size: 18, color: Color(0xFF01579B)),
          SizedBox(width: 10),
          Expanded(child: Text(
              'Elige la sucursal más cercana. Aquí recibirás tus paquetes '
                  'y se asignará tu casillero.',
              style: TextStyle(fontSize: 12, color: Color(0xFF01579B)))),
        ]),
      ),
      const SizedBox(height: 20),

      _label('Selecciona tu sucursal'),
      const SizedBox(height: 12),

      // Estado: cargando
      if (loadingSuc)
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(
                color: Color(0xFF1A237E), strokeWidth: 2),
          ),
        )

      // Estado: sin sucursales
      else if (sucursales.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFECB3))),
          child: const Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF8F00), size: 18),
            SizedBox(width: 10),
            Expanded(child: Text(
                'No hay sucursales disponibles por el momento.',
                style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)))),
          ]),
        )

      // Lista de tarjetas seleccionables
      else
        ...sucursales.map((s) {
          final sel = s.id == sucursalId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onSucursalChanged(sel ? null : s.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF1A237E).withOpacity(0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel
                            ? const Color(0xFF1A237E)
                            : const Color(0xFFE5E7EB),
                        width: sel ? 2 : 1)),
                child: Row(children: [
                  // Ícono según tipo
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF1A237E).withOpacity(0.1)
                            : const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                        s.tipo == TipoSucursal.INTERNACIONAL
                            ? Icons.flight_rounded
                            : s.tipo == TipoSucursal.MATRIZ
                            ? Icons.apartment_rounded
                            : Icons.store_rounded,
                        color: sel
                            ? const Color(0xFF1A237E)
                            : const Color(0xFF6B7280),
                        size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nombre,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: sel
                                  ? const Color(0xFF1A237E)
                                  : const Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      Text('${s.ciudad}, ${s.pais}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                      const SizedBox(height: 5),
                      Row(children: [
                        _TipoBadge(tipo: s.tipo),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1A237E).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('${s.prefijoCasillero}XXXX',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A237E))),
                        ),
                      ]),
                    ],
                  )),

                  // Círculo de selección
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                        color: sel ? const Color(0xFF1A237E) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel
                                ? const Color(0xFF1A237E)
                                : const Color(0xFFD1D5DB),
                            width: 2)),
                    child: sel
                        ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                        : null,
                  ),
                ]),
              ),
            ),
          );
        }),

      if (!loadingSuc && sucursales.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 14, color: Color(0xFF9CA3AF)),
            SizedBox(width: 8),
            Expanded(child: Text(
                'Puedes cambiar tu sucursal después desde tu perfil.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))),
          ]),
        ),
    ]);
  }
}

// Badge de tipo de sucursal
class _TipoBadge extends StatelessWidget {
  final TipoSucursal tipo;
  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final color = switch (tipo) {
      TipoSucursal.MATRIZ        => const Color(0xFF7B1FA2),
      TipoSucursal.INTERNACIONAL => const Color(0xFF00695C),
      TipoSucursal.NACIONAL      => const Color(0xFF1565C0),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(tipo.label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─── PASO 2: Datos personales ─────────────────────────────────────────────────
class _StepDatos extends StatelessWidget {
  final TextEditingController nomCtrl, apCtrl, emailCtrl,
      telCtrl, ciudadCtrl, dirCtrl;
  const _StepDatos({
    required this.nomCtrl,    required this.apCtrl,
    required this.emailCtrl,  required this.telCtrl,
    required this.ciudadCtrl, required this.dirCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nombres *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: nomCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _deco(hint: 'Juan Carlos', icon: Icons.person_outline),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ])),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Apellidos *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: apCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _deco(hint: 'Pérez López', icon: Icons.person_outline),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
    required this.passCtrl,    required this.confirmCtrl,
    required this.obscure,     required this.onToggle,
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
          Icon(Icons.check_circle_outline,
              color: Color(0xFF2E7D32), size: 20),
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
          hintText: 'Mínimo 8 caracteres',
          prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.lock_outline_rounded,
                  size: 20, color: Color(0xFF9CA3AF))),
          prefixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
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
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (v) =>
        (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
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
          prefixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
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
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (v) =>
        (v != passCtrl.text) ? 'Las contraseñas no coinciden' : null,
      ),
    ]);
  }
}

// ─── PASO 4: Afiliación familiar ──────────────────────────────────────────────
class _StepAfiliacion extends StatefulWidget {
  final bool        quiereAfiliarse;
  final String?     titularId;
  final String?     titularNombre;
  final String      parentesco;
  final List<String> parentescos;
  final void Function(bool)              onToggleAfiliarse;
  final void Function(String, String)    onTitularEncontrado;
  final void Function(String)            onParentescoChanged;

  const _StepAfiliacion({
    required this.quiereAfiliarse,
    required this.titularId,
    required this.titularNombre,
    required this.parentesco,
    required this.parentescos,
    required this.onToggleAfiliarse,
    required this.onTitularEncontrado,
    required this.onParentescoChanged,
  });

  @override
  State<_StepAfiliacion> createState() => _StepAfiliacionState();
}

class _StepAfiliacionState extends State<_StepAfiliacion> {
  final _cedulaCtrl = TextEditingController();
  bool    _buscando      = false;
  String? _errorBusqueda;

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarTitular() async {
    final cedula = _cedulaCtrl.text.trim();
    if (cedula.isEmpty) {
      setState(() => _errorBusqueda = 'Ingresa la cédula del titular');
      return;
    }
    setState(() { _buscando = true; _errorBusqueda = null; });
    try {
      final repo   = AuthRepositoryImpl();
      final result = await repo.buscarClientePorCedula(cedula);
      widget.onTitularEncontrado(
        result['id'] as String,
        '${result['nombres']} ${result['apellidos']}',
      );
      setState(() => _errorBusqueda = null);
    } catch (e) {
      setState(() =>
      _errorBusqueda = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF01579B)),
          SizedBox(width: 10),
          Expanded(child: Text(
              'Si eres familiar o conocido de un cliente, '
                  'puedes afiliarte para compartir beneficios.',
              style: TextStyle(fontSize: 12, color: Color(0xFF01579B)))),
        ]),
      ),
      const SizedBox(height: 20),

      // Toggle
      GestureDetector(
        onTap: () => widget.onToggleAfiliarse(!widget.quiereAfiliarse),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: widget.quiereAfiliarse
                  ? const Color(0xFF1A237E).withOpacity(0.06)
                  : const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: widget.quiereAfiliarse
                      ? const Color(0xFF1A237E)
                      : const Color(0xFFE5E7EB),
                  width: widget.quiereAfiliarse ? 2 : 1)),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                  color: widget.quiereAfiliarse
                      ? const Color(0xFF1A237E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: widget.quiereAfiliarse
                          ? const Color(0xFF1A237E)
                          : const Color(0xFFD1D5DB))),
              child: widget.quiereAfiliarse
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Afiliarme a un titular',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF111827))),
                    SizedBox(height: 2),
                    Text('Opcional — puedes hacerlo después',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                  ]),
            ),
            const Icon(Icons.people_outline,
                color: Color(0xFF6B7280), size: 20),
          ]),
        ),
      ),

      if (widget.quiereAfiliarse) ...[
        const SizedBox(height: 20),
        _label('Cédula del titular'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _cedulaCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej: 1104567890',
                prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(Icons.badge_outlined,
                        size: 20, color: Color(0xFF9CA3AF))),
                prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
                filled: true, fillColor: Colors.white,
                errorText: _errorBusqueda,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A237E), width: 2)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFC62828))),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _buscando ? null : _buscarTitular,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16)),
              child: _buscando
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Buscar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),

        if (widget.titularNombre != null &&
            widget.titularNombre!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF2E7D32).withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.check_circle_outline,
                  color: Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Titular encontrado',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600)),
                  Text(widget.titularNombre!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.bold)),
                ],
              )),
              GestureDetector(
                onTap: () {
                  _cedulaCtrl.clear();
                  widget.onTitularEncontrado('', '');
                },
                child: const Icon(Icons.close,
                    size: 16, color: Color(0xFF2E7D32)),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 16),
        _label('Tu parentesco con el titular'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: widget.parentescos.map((p) {
            final sel = p == widget.parentesco;
            return GestureDetector(
              onTap: () => widget.onParentescoChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF1A237E)
                        : const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? const Color(0xFF1A237E)
                            : const Color(0xFFE5E7EB))),
                child: Text(p,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? Colors.white
                            : const Color(0xFF6B7280))),
              ),
            );
          }).toList(),
        ),
      ],

      if (!widget.quiereAfiliarse) ...[
        const SizedBox(height: 16),
        const Text(
          'Sin problema, puedes afiliarte después desde tu perfil.',
          style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    ]);
  }
}

// ─── Helpers globales ─────────────────────────────────────────────────────────
Widget _label(String text) => Text(text,
    style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF374151)));

InputDecoration _deco({required String hint, required IconData icon}) =>
    InputDecoration(
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
      contentPadding:
      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );