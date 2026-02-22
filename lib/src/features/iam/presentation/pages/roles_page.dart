// lib/src/features/iam/presentation/pages/roles_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../domain/models/permission_model.dart';
import '../../domain/models/role_model.dart';
import '../bloc/iam_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
class RolesPage extends StatelessWidget {
  const RolesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<IamBloc>()..add(IamRolesRequested()),
      child: const _RolesView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RolesView extends StatefulWidget {
  const _RolesView();
  @override
  State<_RolesView> createState() => _RolesViewState();
}

class _RolesViewState extends State<_RolesView> {
  final _ctrl = TextEditingController();
  String _q   = '';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<RoleModel> _filter(List<RoleModel> src) {
    if (_q.isEmpty) return src;
    return src.where((r) =>
        r.displayName.toLowerCase().contains(_q.toLowerCase())).toList();
  }

  void _openCreate(BuildContext ctx) {
    showModalBottomSheet(
        context: ctx, isScrollControlled: true,
        useSafeArea: true, backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
            value: ctx.read<IamBloc>(),
            child: const _RoleCreateSheet()));
  }

  void _openPerms(BuildContext ctx, RoleModel role) {
    showModalBottomSheet(
        context: ctx, isScrollControlled: true,
        useSafeArea: true, backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
            value: ctx.read<IamBloc>(),
            child: _AssignPermsSheet(role: role)));
  }

  void _snack(BuildContext ctx, String msg, {required bool ok}) {
    ScaffoldMessenger.of(ctx)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: ok ? 3 : 5),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return BlocConsumer<IamBloc, IamState>(
      listener: (ctx, state) {
        if (state is IamRolesLoaded && state.message != null)
          _snack(ctx, state.message!, ok: true);
        if (state is IamError) _snack(ctx, state.message, ok: false);
      },
      builder: (ctx, state) {
        final all = switch (state) {
          IamRolesLoaded s => s.roles,
          IamError s       => s.roles,
          _                => <RoleModel>[],
        };
        final roles   = _filter(all);
        final loading = state is IamLoading;
        final errOnly = state is IamError && all.isEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            _IamPageHeader(
              title: 'Gestión de Roles',
              subtitle: '${all.length} rol${all.length == 1 ? '' : 'es'} creado${all.length == 1 ? '' : 's'}',
              addLabel: 'Nuevo rol',
              onAdd:     () => _openCreate(ctx),
              onRefresh: () => ctx.read<IamBloc>().add(IamRolesRequested()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: _IamSearchField(
                ctrl: _ctrl,
                hint: 'Buscar rol...',
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(child: _body(ctx, state, roles, loading, errOnly, isDesktop)),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext ctx, IamState state, List<RoleModel> roles,
      bool loading, bool errOnly, bool isDesktop) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }
    if (errOnly) {
      return _IamErrorView(
        message: (state as IamError).message,
        onRetry: () => ctx.read<IamBloc>().add(IamRolesRequested()),
      );
    }
    if (roles.isEmpty) {
      return _IamEmptyView(
        icon: Icons.badge_outlined,
        title: _q.isEmpty ? 'No hay roles' : 'Sin resultados',
        subtitle: _q.isEmpty
            ? 'Crea el primer rol con "Nuevo rol"'
            : 'Intenta con otro término',
      );
    }
    return isDesktop
        ? _RolesTable(roles: roles, onPerms: (r) => _openPerms(ctx, r))
        : _RoleCards(roles: roles, onPerms: (r) => _openPerms(ctx, r));
  }
}

// ─── TABLA DESKTOP ────────────────────────────────────────────────────────────
class _RolesTable extends StatelessWidget {
  final List<RoleModel> roles;
  final void Function(RoleModel) onPerms;
  const _RolesTable({required this.roles, required this.onPerms});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(4),
              3: FixedColumnWidth(120),
            },
            children: [
              // Encabezado
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: ['Rol', 'Permisos', 'Permisos asignados', 'Acciones']
                    .map((h) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Text(h,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280))),
                ))
                    .toList(),
              ),
              // Filas
              ...roles.map((r) => TableRow(
                decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB)))),
                children: [
                  // Nombre
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(children: [
                      _RoleAvatar(name: r.displayName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(r.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E))),
                      ),
                    ]),
                  ),
                  // Conteo
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF6),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('${r.permissions.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A237E))),
                    ),
                  ),
                  // Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: r.permissions.isEmpty
                        ? const Text('Sin permisos asignados',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD1D5DB)))
                        : Wrap(spacing: 4, runSpacing: 4, children: [
                      ...r.permissions
                          .take(4)
                          .map((p) => _PChip(label: p.displayName)),
                      if (r.permissions.length > 4)
                        _PChip(
                            label:
                            '+${r.permissions.length - 4}',
                            isCount: true),
                    ]),
                  ),
                  // Acción
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: _IamIconBtn(
                      icon: Icons.lock_outline_rounded,
                      color: const Color(0xFF7B1FA2),
                      tip: 'Gestionar permisos',
                      onTap: () => onPerms(r),
                    ),
                  ),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CARDS MÓVIL ──────────────────────────────────────────────────────────────
class _RoleCards extends StatelessWidget {
  final List<RoleModel> roles;
  final void Function(RoleModel) onPerms;
  const _RoleCards({required this.roles, required this.onPerms});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    itemCount: roles.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) =>
        _RoleCard(role: roles[i], onPerms: () => onPerms(roles[i])),
  );
}

class _RoleCard extends StatelessWidget {
  final RoleModel    role;
  final VoidCallback onPerms;
  const _RoleCard({required this.role, required this.onPerms});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _RoleAvatar(name: role.displayName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E))),
                Text(
                    '${role.permissions.length} permiso${role.permissions.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ]),
        if (role.permissions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ...role.permissions
                .take(6)
                .map((p) => _PChip(label: p.displayName)),
            if (role.permissions.length > 6)
              _PChip(
                  label: '+${role.permissions.length - 6}', isCount: true),
          ]),
        ] else ...[
          const SizedBox(height: 8),
          const Text('Sin permisos asignados',
              style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPerms,
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7B1FA2),
                side: const BorderSide(color: Color(0xFFCE93D8)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10)),
            icon: const Icon(Icons.lock_outline_rounded, size: 16),
            label: Text(
                'Gestionar permisos (${role.permissions.length})',
                style: const TextStyle(fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}

// ─── SHEET CREAR ROL ──────────────────────────────────────────────────────────
class _RoleCreateSheet extends StatefulWidget {
  const _RoleCreateSheet();
  @override
  State<_RoleCreateSheet> createState() => _RoleCreateSheetState();
}

class _RoleCreateSheetState extends State<_RoleCreateSheet> {
  final _key  = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    context.read<IamBloc>()
        .add(IamRoleCreateRequested(_ctrl.text.trim().toUpperCase()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _IamBottomSheet(
      title: 'Nuevo rol',
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IamFieldLabel('Nombre del rol'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: iamInputDeco('Ej: SUPERVISOR'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 4),
            const Text('Se guardará en mayúsculas. Ej: ADMIN, SUPERVISOR',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 24),
            _IamSubmitBtn(label: 'Crear rol', onTap: _submit),
          ],
        ),
      ),
    );
  }
}

// ─── SHEET ASIGNAR PERMISOS ───────────────────────────────────────────────────
class _AssignPermsSheet extends StatefulWidget {
  final RoleModel role;
  const _AssignPermsSheet({required this.role});
  @override
  State<_AssignPermsSheet> createState() => _AssignPermsSheetState();
}

class _AssignPermsSheetState extends State<_AssignPermsSheet> {
  List<PermissionModel> _all      = [];
  Set<String>           _selected = {};
  bool                  _loading  = false;
  String                _q        = '';
  final _sCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.role.permissions.map((p) => p.id).toSet();
    _fetchPerms();
  }

  @override
  void dispose() { _sCtrl.dispose(); super.dispose(); }

  Future<void> _fetchPerms() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<IamBloc>().repo.getPermissions();
      if (mounted) setState(() { _all = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PermissionModel> get _filtered {
    if (_q.isEmpty) return _all;
    return _all.where((p) =>
    p.displayName.toLowerCase().contains(_q.toLowerCase()) ||
        p.name.toLowerCase().contains(_q.toLowerCase())).toList();
  }

  Map<String, List<PermissionModel>> get _byModule {
    final map = <String, List<PermissionModel>>{};
    for (final p in _filtered) {
      map.putIfAbsent(p.modulo, () => []).add(p);
    }
    return map;
  }

  void _save() {
    context.read<IamBloc>().add(
        IamRoleAssignPermsRequested(widget.role.id, _selected.toList()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final byMod = _byModule;

    return _IamBottomSheet(
      title: 'Permisos — ${widget.role.displayName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Color(0xFF7B1FA2)),
              const SizedBox(width: 8),
              Text(
                '${_selected.length} permiso${_selected.length == 1 ? '' : 's'} seleccionado${_selected.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7B1FA2),
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _IamSearchField(
            ctrl: _sCtrl,
            hint: 'Buscar permiso...',
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 14),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFF7B1FA2)),
              ),
            )
          else if (_all.isEmpty)
            const _IamEmptyView(
              icon: Icons.lock_outline,
              title: 'No hay permisos',
              subtitle: 'Crea permisos en la sección "Permisos"',
            )
          else
            ...byMod.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera módulo
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Container(
                      width: 3, height: 16,
                      decoration: BoxDecoration(
                          color: const Color(0xFF7B1FA2),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Color(0xFF6B7280))),
                    ),
                    TextButton(
                      onPressed: () {
                        final ids =
                        entry.value.map((p) => p.id).toSet();
                        final allSel =
                        ids.every((id) => _selected.contains(id));
                        setState(() {
                          if (allSel) _selected.removeAll(ids);
                          else        _selected.addAll(ids);
                        });
                      },
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          minimumSize: Size.zero),
                      child: Text(
                        entry.value.every(
                                (p) => _selected.contains(p.id))
                            ? 'Quitar todos'
                            : 'Todos',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF7B1FA2)),
                      ),
                    ),
                  ]),
                ),
                // Items del módulo
                ...entry.value.map((p) {
                  final sel = _selected.contains(p.id);
                  return Material(
                    color: sel
                        ? const Color(0xFFF3E5F5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() {
                        if (sel) _selected.remove(p.id);
                        else     _selected.add(p.id);
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(p.displayName,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: sel
                                            ? const Color(0xFF7B1FA2)
                                            : const Color(0xFF374151))),
                                Text(p.name,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: sel,
                            onChanged: (v) => setState(() {
                              if (v == true) _selected.add(p.id);
                              else           _selected.remove(p.id);
                            }),
                            activeColor: const Color(0xFF7B1FA2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ]),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
              ],
            )),

          const SizedBox(height: 16),
          _IamSubmitBtn(
            label: 'Guardar permisos (${_selected.length})',
            onTap: _save,
            color: const Color(0xFF7B1FA2),
          ),
        ],
      ),
    );
  }
}

// ─── WIDGETS PROPIOS DE ROLES ─────────────────────────────────────────────────
class _RoleAvatar extends StatelessWidget {
  final String name;
  const _RoleAvatar({required this.name});

  Color get _c => switch (name) {
    'ADMIN'      => const Color(0xFFC62828),
    'SUPERVISOR' => const Color(0xFFF57F17),
    'EMPLEADO'   => const Color(0xFF1A237E),
    'REPARTIDOR' => const Color(0xFFE65100),
    'CLIENTE'    => const Color(0xFF2E7D32),
    _            => const Color(0xFF7B1FA2),
  };

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 18,
    backgroundColor: _c.withOpacity(0.12),
    child: Text(name.isNotEmpty ? name[0] : '?',
        style: TextStyle(
            color: _c, fontSize: 14, fontWeight: FontWeight.bold)),
  );
}

class _PChip extends StatelessWidget {
  final String label;
  final bool   isCount;
  const _PChip({required this.label, this.isCount = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: isCount
            ? const Color(0xFFE8EAF6)
            : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isCount
                ? const Color(0xFF1A237E)
                : const Color(0xFF7B1FA2))),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS — definidos aquí para no depender de archivos externos
// (Flutter no permite usar clases privadas _ entre archivos)
// ═════════════════════════════════════════════════════════════════════════════

// ── Header de página ─────────────────────────────────────────────────────────
class _IamPageHeader extends StatelessWidget {
  final String title, subtitle, addLabel;
  final VoidCallback onAdd, onRefresh;

  const _IamPageHeader({
    required this.title,
    required this.subtitle,
    required this.addLabel,
    required this.onAdd,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
          onPressed: onRefresh,
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12)),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(isWide ? addLabel : 'Nuevo',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ── Campo de búsqueda ─────────────────────────────────────────────────────────
class _IamSearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final void Function(String) onChanged;

  const _IamSearchField({
    required this.ctrl,
    required this.hint,
    required this.onChanged,
  });

  OutlineInputBorder _border({Color? c, double w = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: c ?? const Color(0xFFE5E7EB), width: w),
      );

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle:
      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: const Icon(Icons.search_rounded,
          color: Color(0xFF9CA3AF), size: 20),
      suffixIcon: ctrl.text.isNotEmpty
          ? IconButton(
          icon: const Icon(Icons.close_rounded,
              color: Color(0xFF9CA3AF), size: 18),
          onPressed: () {
            ctrl.clear();
            onChanged('');
          })
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(c: const Color(0xFF1A237E), w: 2),
    ),
  );
}

// ── Bottom Sheet wrapper ──────────────────────────────────────────────────────
class _IamBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _IamBottomSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                24, 12, 24,
                MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Botón guardar ─────────────────────────────────────────────────────────────
class _IamSubmitBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _IamSubmitBtn({
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF1A237E),
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
      child: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600)),
    ),
  );
}

// ── Label de campo ────────────────────────────────────────────────────────────
class _IamFieldLabel extends StatelessWidget {
  final String text;
  const _IamFieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Color(0xFF374151)));
}

// ── Botón icono en tabla ──────────────────────────────────────────────────────
class _IamIconBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   tip;
  final VoidCallback onTap;

  const _IamIconBtn({
    required this.icon,
    required this.color,
    required this.tip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    child: Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    ),
  );
}

// ── Vista vacía ───────────────────────────────────────────────────────────────
class _IamEmptyView extends StatelessWidget {
  final IconData icon;
  final String   title, subtitle;

  const _IamEmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6), shape: BoxShape.circle),
          child: Icon(icon, size: 48, color: const Color(0xFF1A237E)),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Vista error ───────────────────────────────────────────────────────────────
class _IamErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _IamErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded,
              size: 48, color: Color(0xFFC62828)),
        ),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reintentar'),
        ),
      ]),
    ),
  );
}

// ── Input decoration helper ───────────────────────────────────────────────────
InputDecoration iamInputDeco(String hint, {Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: _iamBorder(),
      enabledBorder: _iamBorder(),
      focusedBorder: _iamBorder(c: const Color(0xFF1A237E), w: 2),
      errorBorder: _iamBorder(c: const Color(0xFFC62828)),
      focusedErrorBorder: _iamBorder(c: const Color(0xFFC62828), w: 2),
    );

OutlineInputBorder _iamBorder({Color? c, double w = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
      BorderSide(color: c ?? const Color(0xFFE5E7EB), width: w),
    );