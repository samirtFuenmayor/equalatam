// lib/src/features/iam/presentation/pages/permissions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../domain/models/permission_model.dart';
import '../bloc/iam_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<IamBloc>()..add(IamPermissionsRequested()),
      child: const _PermsView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _PermsView extends StatefulWidget {
  const _PermsView();
  @override
  State<_PermsView> createState() => _PermsViewState();
}

class _PermsViewState extends State<_PermsView> {
  final _ctrl = TextEditingController();
  String _q   = '';
  String _mod = 'Todos';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<PermissionModel> _filter(List<PermissionModel> src) {
    return src.where((p) {
      final q   = _q.toLowerCase();
      final okQ = _q.isEmpty ||
          p.displayName.toLowerCase().contains(q) ||
          p.name.toLowerCase().contains(q);
      final okM = _mod == 'Todos' || p.modulo == _mod;
      return okQ && okM;
    }).toList();
  }

  List<String> _modulos(List<PermissionModel> src) {
    final mods = src.map((p) => p.modulo).toSet().toList()..sort();
    return ['Todos', ...mods];
  }

  void _openCreate(BuildContext ctx) {
    showModalBottomSheet(
        context: ctx, isScrollControlled: true,
        useSafeArea: true, backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
            value: ctx.read<IamBloc>(),
            child: const _PermCreateSheet()));
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
        if (state is IamPermissionsLoaded && state.message != null)
          _snack(ctx, state.message!, ok: true);
        if (state is IamError) _snack(ctx, state.message, ok: false);
      },
      builder: (ctx, state) {
        final all = switch (state) {
          IamPermissionsLoaded s => s.permissions,
          IamError s             => s.permissions,
          _                      => <PermissionModel>[],
        };
        final mods     = _modulos(all);
        final filtered = _filter(all);
        final loading  = state is IamLoading;
        final errOnly  = state is IamError && all.isEmpty;

        if (!mods.contains(_mod)) _mod = 'Todos';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            // Header
            _IamPageHeader(
              title: 'Gestión de Permisos',
              subtitle:
              '${all.length} permiso${all.length == 1 ? '' : 's'} creado${all.length == 1 ? '' : 's'}',
              addLabel: 'Nuevo permiso',
              onAdd:     () => _openCreate(ctx),
              onRefresh: () =>
                  ctx.read<IamBloc>().add(IamPermissionsRequested()),
            ),
            // Búsqueda + filtro módulo
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: _buildFilterBar(mods),
            ),
            // Cuerpo
            Expanded(
                child: _body(
                    ctx, state, filtered, loading, errOnly, isDesktop)),
          ]),
        );
      },
    );
  }

  Widget _buildFilterBar(List<String> mods) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final search = _IamSearchField(
      ctrl: _ctrl,
      hint: 'Buscar permiso...',
      onChanged: (v) => setState(() => _q = v),
    );
    final filter = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _mod,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280)),
          items: mods
              .map((m) => DropdownMenuItem(
            value: m,
            child: Row(children: [
              if (m != 'Todos') ...[
                const Icon(Icons.folder_outlined,
                    size: 14, color: Color(0xFF7B1FA2)),
                const SizedBox(width: 6),
              ],
              Text(m, style: const TextStyle(fontSize: 13)),
            ]),
          ))
              .toList(),
          onChanged: (v) => setState(() => _mod = v!),
        ),
      ),
    );

    return isWide
        ? Row(children: [
      Expanded(child: search),
      const SizedBox(width: 12),
      filter,
    ])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      search,
      const SizedBox(height: 10),
      filter,
    ]);
  }

  Widget _body(
      BuildContext ctx,
      IamState state,
      List<PermissionModel> perms,
      bool loading,
      bool errOnly,
      bool isDesktop) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }
    if (errOnly) {
      return _IamErrorView(
        message: (state as IamError).message,
        onRetry: () => ctx.read<IamBloc>().add(IamPermissionsRequested()),
      );
    }
    if (perms.isEmpty) {
      return _IamEmptyView(
        icon: Icons.lock_outline,
        title: _q.isEmpty && _mod == 'Todos'
            ? 'No hay permisos'
            : 'Sin resultados',
        subtitle: _q.isEmpty && _mod == 'Todos'
            ? 'Crea el primer permiso con "Nuevo permiso"'
            : 'Intenta con otro término o módulo',
      );
    }
    return isDesktop
        ? _PermsTable(perms: perms)
        : _PermCards(perms: perms);
  }
}

// ─── TABLA DESKTOP ────────────────────────────────────────────────────────────
class _PermsTable extends StatelessWidget {
  final List<PermissionModel> perms;
  const _PermsTable({required this.perms});

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
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(2),
            },
            children: [
              // Encabezado
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: ['Permiso', 'Nombre técnico', 'Módulo']
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
              ...perms.map((p) => TableRow(
                decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB)))),
                children: [
                  // Nombre legible
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.lock_outline_rounded,
                            size: 14, color: Color(0xFF7B1FA2)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(p.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E))),
                      ),
                    ]),
                  ),
                  // Nombre técnico
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Text(p.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontFamily: 'monospace')),
                  ),
                  // Módulo badge
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: _ModBadge(mod: p.modulo),
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
class _PermCards extends StatelessWidget {
  final List<PermissionModel> perms;
  const _PermCards({required this.perms});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    itemCount: perms.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _PermCard(perm: perms[i]),
  );
}

class _PermCard extends StatelessWidget {
  final PermissionModel perm;
  const _PermCard({required this.perm});

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
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.lock_outline_rounded,
              size: 20, color: Color(0xFF7B1FA2)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(perm.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
              Text(perm.name,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 6),
              _ModBadge(mod: perm.modulo),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── SHEET CREAR PERMISO ──────────────────────────────────────────────────────
class _PermCreateSheet extends StatefulWidget {
  const _PermCreateSheet();
  @override
  State<_PermCreateSheet> createState() => _PermCreateSheetState();
}

class _PermCreateSheetState extends State<_PermCreateSheet> {
  final _key  = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  static const _suggestions = [
    'CREATE_USER',  'READ_USER',    'UPDATE_USER',  'DELETE_USER',
    'CREATE_ROLE',  'READ_ROLE',    'ASSIGN_PERMISSIONS',
    'CREATE_ORDER', 'READ_ORDER',   'UPDATE_ORDER', 'DELETE_ORDER',
    'READ_REPORT',  'MANAGE_BILLING',
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    context.read<IamBloc>().add(
        IamPermissionCreateRequested(_ctrl.text.trim().toUpperCase()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _IamBottomSheet(
      title: 'Nuevo permiso',
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IamFieldLabel('Nombre del permiso'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: iamInputDeco('Ej: CREATE_USER'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 6),
            const Text('Convención: ACCIÓN_RECURSO en mayúsculas.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 14),

            _IamFieldLabel('Sugerencias rápidas'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestions
                  .map((s) => ActionChip(
                label: Text(s,
                    style: const TextStyle(fontSize: 10)),
                onPressed: () => setState(() => _ctrl.text = s),
                backgroundColor: _ctrl.text == s
                    ? const Color(0xFFF3E5F5)
                    : const Color(0xFFF9FAFB),
                side: BorderSide(
                    color: _ctrl.text == s
                        ? const Color(0xFFCE93D8)
                        : const Color(0xFFE5E7EB)),
                labelStyle: TextStyle(
                    color: _ctrl.text == s
                        ? const Color(0xFF7B1FA2)
                        : const Color(0xFF6B7280)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            _IamSubmitBtn(
              label: 'Crear permiso',
              onTap: _submit,
              color: const Color(0xFF7B1FA2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BADGE MÓDULO ─────────────────────────────────────────────────────────────
class _ModBadge extends StatelessWidget {
  final String mod;
  const _ModBadge({required this.mod});

  Color get _c => switch (mod) {
    'USER'        => const Color(0xFF1A237E),
    'ROLE'        => const Color(0xFF7B1FA2),
    'ORDER'       => const Color(0xFFE65100),
    'CLIENT'      => const Color(0xFF2E7D32),
    'REPORT'      => const Color(0xFF558B2F),
    'BILLING'     => const Color(0xFFF57F17),
    'PERMISSIONS' => const Color(0xFF7B1FA2),
    _             => const Color(0xFF546E7A),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: _c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _c.withOpacity(0.2))),
    child: Text(mod,
        style: TextStyle(
            color: _c, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS — copiados aquí porque Flutter no comparte clases
// privadas (_) entre archivos distintos
// ═════════════════════════════════════════════════════════════════════════════

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280))),
            ],
          ),
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
                padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 16 : 12)),
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
        borderSide:
        BorderSide(color: c ?? const Color(0xFFE5E7EB), width: w),
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

InputDecoration iamInputDeco(String hint, {Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle:
      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
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