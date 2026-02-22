// lib/src/features/iam/presentation/pages/users_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../domain/models/sucursal_model.dart';
import '../../domain/models/user_model.dart';
import '../bloc/iam_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<IamBloc>()..add(IamUsersRequested()),
      child: const _UsersView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VISTA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _searchCtrl = TextEditingController();
  String _search    = '';
  String _filterRol = 'Todos';

  static const _roles = [
    'Todos', 'ADMIN', 'SUPERVISOR', 'EMPLEADO', 'REPARTIDOR', 'CLIENTE'
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserModel> _filter(List<UserModel> src) => src.where((u) {
    final q = _search.toLowerCase();
    final matchQ = q.isEmpty ||
        u.fullName.toLowerCase().contains(q) ||
        u.username.toLowerCase().contains(q) ||
        u.correo.toLowerCase().contains(q);
    return matchQ && (_filterRol == 'Todos' || u.rol == _filterRol);
  }).toList();

  // ── Abrir formulario (crear o editar) ──────────────────────────────────────
  void _openForm(BuildContext ctx, {UserModel? user}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<IamBloc>(),
        child: _UserFormSheet(user: user),
      ),
    );
  }

  // ── Confirmar eliminación ──────────────────────────────────────────────────
  void _confirmDelete(BuildContext ctx, UserModel user) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFC62828), size: 28)),
        title: const Text('Eliminar usuario',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        content: Text('¿Eliminar a ${user.fullName}?\nEsta acción no se puede deshacer.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(d),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280)))),
          const SizedBox(width: 8),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(d);
                ctx.read<IamBloc>().add(IamUserDeleteRequested(user.id));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Sí, eliminar')),
        ],
      ),
    );
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
        backgroundColor: ok
            ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: ok ? 3 : 5),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return BlocConsumer<IamBloc, IamState>(
      listener: (ctx, state) {
        if (state is IamUsersLoaded && state.message != null) {
          _snack(ctx, state.message!, ok: true);
        }
        if (state is IamError) {
          _snack(ctx, state.message, ok: false);
        }
      },
      builder: (ctx, state) {
        final allUsers = switch (state) {
          IamUsersLoaded s => s.users,
          IamError s       => s.users,
          _                => <UserModel>[],
        };

        final users   = _filter(allUsers);
        final loading = state is IamLoading;
        final errOnly = state is IamError && allUsers.isEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            // ── Header ───────────────────────────────────────────────────────
            _Header(
              total: allUsers.length,
              onAdd:     () => _openForm(ctx),
              onRefresh: () => ctx.read<IamBloc>().add(IamUsersRequested()),
            ),
            // ── Búsqueda + filtro ─────────────────────────────────────────────
            _FilterBar(
              ctrl:        _searchCtrl,
              selectedRol: _filterRol,
              roles:       _roles,
              onSearch: (v) => setState(() => _search = v),
              onFilter: (v) => setState(() => _filterRol = v),
            ),
            // ── Cuerpo ────────────────────────────────────────────────────────
            Expanded(child: _body(ctx, state, users, loading, errOnly, isDesktop)),
          ]),
        );
      },
    );
  }

  Widget _body(BuildContext ctx, IamState state, List<UserModel> users,
      bool loading, bool errOnly, bool isDesktop) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }
    if (errOnly) {
      return _ErrorView(
          message: (state as IamError).message,
          onRetry: () => ctx.read<IamBloc>().add(IamUsersRequested()));
    }
    if (users.isEmpty) return _EmptyView(hasSearch: _search.isNotEmpty);

    if (isDesktop) {
      return _TableView(
          users: users,
          onEdit:   (u) => _openForm(ctx, user: u),
          onToggle: (u) => ctx.read<IamBloc>()
              .add(IamUserToggleRequested(u.id, !u.activo)),
          onDelete: (u) => _confirmDelete(ctx, u));
    }
    return _CardList(
        users: users,
        onEdit:   (u) => _openForm(ctx, user: u),
        onToggle: (u) => ctx.read<IamBloc>()
            .add(IamUserToggleRequested(u.id, !u.activo)),
        onDelete: (u) => _confirmDelete(ctx, u));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int total;
  final VoidCallback onAdd, onRefresh;

  const _Header({required this.total,
    required this.onAdd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gestión de Usuarios',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Text('$total usuario${total == 1 ? '' : 's'} registrado${total == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ])),
        IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
            onPressed: onRefresh, tooltip: 'Actualizar'),
        const SizedBox(width: 6),
        SizedBox(height: 42,
            child: ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 16 : 12)),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(isWide ? 'Nuevo usuario' : 'Nuevo',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARRA BÚSQUEDA + FILTRO ROL
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final TextEditingController ctrl;
  final String selectedRol;
  final List<String> roles;
  final void Function(String) onSearch, onFilter;

  const _FilterBar({required this.ctrl, required this.selectedRol,
    required this.roles, required this.onSearch, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      child: isWide
          ? Row(children: [
        Expanded(child: _search()),
        const SizedBox(width: 12),
        _rolDrop()])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _search(),
        const SizedBox(height: 10),
        _rolDrop(),
      ]),
    );
  }

  Widget _search() => TextField(
    controller: ctrl, onChanged: onSearch,
    decoration: InputDecoration(
        hintText: 'Buscar por nombre, usuario o correo...',
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded,
            color: Color(0xFF9CA3AF), size: 20),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Color(0xFF9CA3AF), size: 18),
            onPressed: () { ctrl.clear(); onSearch(''); })
            : null,
        filled: true, fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: _border(), enabledBorder: _border(),
        focusedBorder: _border(
            color: const Color(0xFF1A237E), width: 2)),
  );

  Widget _rolDrop() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB))),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedRol,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280)),
        items: roles.map((r) => DropdownMenuItem(
            value: r,
            child: Row(children: [
              if (r != 'Todos') ...[
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: _rc(r), shape: BoxShape.circle)),
                const SizedBox(width: 8),
              ],
              Text(r, style: const TextStyle(fontSize: 13)),
            ]))).toList(),
        onChanged: (v) => onFilter(v!),
      ),
    ),
  );

  OutlineInputBorder _border({Color? color, double width = 1}) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: color ?? const Color(0xFFE5E7EB), width: width));

  Color _rc(String r) => switch (r) {
    'ADMIN'      => const Color(0xFFC62828),
    'SUPERVISOR' => const Color(0xFFF9A825),
    'EMPLEADO'   => const Color(0xFF1A237E),
    'REPARTIDOR' => const Color(0xFFFF6F00),
    'CLIENTE'    => const Color(0xFF2E7D32),
    _            => const Color(0xFF9CA3AF),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLA (≥900px)
// ─────────────────────────────────────────────────────────────────────────────
class _TableView extends StatelessWidget {
  final List<UserModel> users;
  final void Function(UserModel) onEdit, onToggle, onDelete;

  const _TableView({required this.users, required this.onEdit,
    required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.8), // usuario
              1: FlexColumnWidth(2.4), // correo
              2: FlexColumnWidth(2.0), // sucursal
              3: FlexColumnWidth(1.4), // rol
              4: FixedColumnWidth(70), // estado
              5: FixedColumnWidth(100), // acciones
            },
            children: [
              // ── Encabezado ────────────────────────────────────────────────
              TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    'Usuario', 'Correo', 'Sucursal', 'Rol', 'Estado', 'Acciones'
                  ].map((h) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Text(h, style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280))))).toList()),

              // ── Filas ────────────────────────────────────────────────────
              ...users.map((u) => TableRow(
                  decoration: BoxDecoration(
                      border: const Border(
                          top: BorderSide(color: Color(0xFFE5E7EB))),
                      color: u.activo
                          ? Colors.white : const Color(0xFFFAFAFA)),
                  children: [
                    // Usuario (avatar + nombre + @username)
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(children: [
                          _Avatar(user: u, size: 36),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: u.activo
                                            ? const Color(0xFF1A1A2E)
                                            : const Color(0xFF9CA3AF))),
                                Text('@${u.username}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF))),
                              ])),
                        ])),

                    // Correo
                    _cell(u.correo),

                    // Sucursal
                    _cell(u.sucursalNombre ?? '—',
                        color: u.sucursalNombre == null
                            ? const Color(0xFFD1D5DB) : null),

                    // Rol
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: _RolBadge(rol: u.rol)),

                    // Toggle activo/inactivo
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Switch(
                            value: u.activo,
                            activeColor: const Color(0xFF2E7D32),
                            onChanged: (_) => onToggle(u))),

                    // Editar / Eliminar
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(children: [
                          _Btn(icon: Icons.edit_outlined,
                              color: const Color(0xFF1A237E),
                              tip: 'Editar',
                              onTap: () => onEdit(u)),
                          const SizedBox(width: 4),
                          _Btn(icon: Icons.delete_outline_rounded,
                              color: const Color(0xFFC62828),
                              tip: 'Eliminar',
                              onTap: () => onDelete(u)),
                        ])),
                  ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(text, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13,
              color: color ?? const Color(0xFF374151))));
}

// ─────────────────────────────────────────────────────────────────────────────
// LISTA DE CARDS (móvil / tablet)
// ─────────────────────────────────────────────────────────────────────────────
class _CardList extends StatelessWidget {
  final List<UserModel> users;
  final void Function(UserModel) onEdit, onToggle, onDelete;

  const _CardList({required this.users, required this.onEdit,
    required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    itemCount: users.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _UserCard(
      user: users[i],
      onEdit:   () => onEdit(users[i]),
      onToggle: () => onToggle(users[i]),
      onDelete: () => onDelete(users[i]),
    ),
  );
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit, onToggle, onDelete;

  const _UserCard({required this.user,
    required this.onEdit, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: [
          _Avatar(user: user, size: 46),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15,
                        color: Color(0xFF1A1A2E))),
                Text('@${user.username}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF))),
                Text(user.correo,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                if (user.sucursalNombre != null)
                  Row(children: [
                    const Icon(Icons.store_outlined,
                        size: 12, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(user.sucursalNombre!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                  ]),
              ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: Color(0xFF9CA3AF), size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined,
                        size: 18, color: Color(0xFF1A237E)),
                    SizedBox(width: 10),
                    Text('Editar'),
                  ])),
              const PopupMenuItem(value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: Color(0xFFC62828)),
                    SizedBox(width: 10),
                    Text('Eliminar'),
                  ])),
            ],
            onSelected: (v) {
              if (v == 'edit')   onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _RolBadge(rol: user.rol),
          const Spacer(),
          Text(user.activo ? 'Activo' : 'Inactivo',
              style: TextStyle(fontSize: 12,
                  color: user.activo
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF9CA3AF))),
          const SizedBox(width: 6),
          Switch(
              value: user.activo,
              activeColor: const Color(0xFF2E7D32),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) => onToggle()),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORMULARIO — BottomSheet con todos los campos del backend
// ─────────────────────────────────────────────────────────────────────────────
class _UserFormSheet extends StatefulWidget {
  final UserModel? user;
  const _UserFormSheet({this.user});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _key     = GlobalKey<FormState>();
  final _nomC    = TextEditingController();
  final _apC     = TextEditingController();
  final _usrC    = TextEditingController();
  final _emC     = TextEditingController();
  final _telC    = TextEditingController();
  final _nacC    = TextEditingController();
  final _prvC    = TextEditingController();
  final _ciuC    = TextEditingController();
  final _dirC    = TextEditingController();
  final _fecC    = TextEditingController();
  final _pasC    = TextEditingController();

  String  _rol       = 'EMPLEADO';
  String? _sucId;
  bool    _obs       = true;

  List<SucursalModel> _sucursales = [];
  bool                _loadSuc    = false;

  bool get _edit => widget.user != null;

  static const _roles = [
    'ADMIN', 'SUPERVISOR', 'EMPLEADO', 'REPARTIDOR', 'CLIENTE'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSucursales();
    if (_edit) {
      final u = widget.user!;
      _nomC.text = u.nombre;    _apC.text  = u.apellido;
      _usrC.text = u.username;  _emC.text  = u.correo;
      _telC.text = u.telefono;  _nacC.text = u.nacionalidad;
      _prvC.text = u.provincia; _ciuC.text = u.ciudad;
      _dirC.text = u.direccion; _fecC.text = u.fechaNacimiento;
      _rol = u.rol; _sucId = u.sucursalId;
    }
  }

  Future<void> _fetchSucursales() async {
    setState(() => _loadSuc = true);
    try {
      final list = await context.read<IamBloc>().repo.getSucursales();
      if (mounted) setState(() { _sucursales = list; _loadSuc = false; });
    } catch (_) {
      if (mounted) setState(() => _loadSuc = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_nomC,_apC,_usrC,_emC,_telC,
      _nacC,_prvC,_ciuC,_dirC,_fecC,_pasC]) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;

    final body = <String, dynamic>{
      'nombre':         _nomC.text.trim(),
      'apellido':       _apC.text.trim(),
      'username':       _usrC.text.trim(),
      'correo':         _emC.text.trim(),
      'telefono':       _telC.text.trim(),
      'nacionalidad':   _nacC.text.trim(),
      'provincia':      _prvC.text.trim(),
      'ciudad':         _ciuC.text.trim(),
      'direccion':      _dirC.text.trim(),
      'fechaNacimiento':_fecC.text.trim(),
      'rol':            _rol,
      if (_sucId != null && _sucId!.isNotEmpty) 'sucursalId': _sucId,
      if (!_edit) 'password': _pasC.text,
    };

    if (_edit) {
      context.read<IamBloc>()
          .add(IamUserUpdateRequested(widget.user!.id, body));
    } else {
      context.read<IamBloc>().add(IamUserCreateRequested(body));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        // Handle visual
        Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 12, 24,
                MediaQuery.of(context).viewInsets.bottom + 24),
            child: Form(key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Título ────────────────────────────────────────────────
                  Row(children: [
                    Expanded(child: Text(
                        _edit ? 'Editar usuario' : 'Nuevo usuario',
                        style: const TextStyle(fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E)))),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: 18),

                  // ── Nombre + Apellido ──────────────────────────────────────
                  _pair(
                    _f('Nombre',   _nomC, hint: 'Juan',  req: true),
                    _f('Apellido', _apC,  hint: 'Pérez', req: true),
                  ),

                  // ── Username ───────────────────────────────────────────────
                  _f('Usuario', _usrC,
                      hint: 'juan.perez', req: true,
                      readOnly: _edit),
                  const SizedBox(height: 14),

                  // ── Correo ─────────────────────────────────────────────────
                  _f('Correo electrónico', _emC,
                      hint: 'correo@ejemplo.com',
                      kb: TextInputType.emailAddress,
                      req: true,
                      xv: (v) =>
                      (!v!.contains('@') || !v.contains('.'))
                          ? 'Correo inválido' : null),
                  const SizedBox(height: 14),

                  // ── Teléfono + Nacionalidad ────────────────────────────────
                  _pair(
                    _f('Teléfono',     _telC,
                        hint: '0987654321',
                        kb: TextInputType.phone),
                    _f('Nacionalidad', _nacC, hint: 'Ecuatoriana'),
                  ),

                  // ── Provincia + Ciudad ─────────────────────────────────────
                  _pair(
                    _f('Provincia', _prvC, hint: 'Loja'),
                    _f('Ciudad',    _ciuC, hint: 'Loja'),
                  ),

                  // ── Dirección ──────────────────────────────────────────────
                  _f('Dirección', _dirC,
                      hint: 'Calle 10 de Agosto'),
                  const SizedBox(height: 14),

                  // ── Fecha de nacimiento ────────────────────────────────────
                  _f('Fecha de nacimiento', _fecC,
                      hint: 'AAAA-MM-DD',
                      kb: TextInputType.datetime,
                      xv: (v) {
                        if (v == null || v.isEmpty) return null;
                        return RegExp(r'^\d{4}-\d{2}-\d{2}$')
                            .hasMatch(v)
                            ? null
                            : 'Formato: AAAA-MM-DD';
                      }),
                  const SizedBox(height: 14),

                  // ── Rol ────────────────────────────────────────────────────
                  _lbl('Rol'),
                  const SizedBox(height: 8),
                  _drop<String>(
                    value: _rol, items: _roles,
                    label: (r) => r,
                    leading: (r) => Container(width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: _rc(r), shape: BoxShape.circle)),
                    onChanged: (v) => setState(() => _rol = v!),
                  ),
                  const SizedBox(height: 14),

                  // ── Sucursal ───────────────────────────────────────────────
                  _lbl('Sucursal asignada'),
                  const SizedBox(height: 8),
                  _loadSuc
                      ? const SizedBox(height: 48,
                      child: Center(child: SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              color: Color(0xFF1A237E)))))
                      : _drop<String?>(
                    value: _sucId,
                    items: [null, ..._sucursales.map((s) => s.id)],
                    label: (id) {
                      if (id == null) return 'Sin sucursal asignada';
                      return _sucursales
                          .where((s) => s.id == id)
                          .map((s) => s.label)
                          .firstOrNull ?? id;
                    },
                    leading: (id) => Icon(
                        id == null
                            ? Icons.remove_circle_outline
                            : Icons.store_outlined,
                        size: 16,
                        color: id == null
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF1A237E)),
                    onChanged: (v) => setState(() => _sucId = v),
                  ),
                  const SizedBox(height: 14),

                  // ── Contraseña (solo en crear) ─────────────────────────────
                  if (!_edit) ...[
                    _lbl('Contraseña'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pasC,
                      obscureText: _obs,
                      decoration: _deco('Mínimo 6 caracteres',
                          suf: IconButton(
                              icon: Icon(_obs
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                                  size: 20, color: const Color(0xFF9CA3AF)),
                              onPressed: () =>
                                  setState(() => _obs = !_obs))),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres' : null,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Botón guardar ──────────────────────────────────────────
                  SizedBox(height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text(
                            _edit ? 'Guardar cambios' : 'Crear usuario',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      )),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Pair (dos campos en fila) ──────────────────────────────────────────────
  Widget _pair(Widget a, Widget b) => Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: a), const SizedBox(width: 12), Expanded(child: b),
      ]));

  // ── Campo de texto genérico ────────────────────────────────────────────────
  Widget _f(String label, TextEditingController c, {
    String? hint, bool req = false, bool readOnly = false,
    TextInputType? kb, String? Function(String?)? xv,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl(label),
          const SizedBox(height: 7),
          TextFormField(
            controller: c, readOnly: readOnly, keyboardType: kb,
            style: TextStyle(
                color: readOnly ? const Color(0xFF9CA3AF) : null),
            decoration: _deco(hint, ro: readOnly),
            validator: (v) {
              if (req && (v == null || v.trim().isEmpty))
                return 'Campo requerido';
              return xv?.call(v);
            },
          ),
        ]),
      );

  // ── Dropdown genérico ──────────────────────────────────────────────────────
  Widget _drop<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    Widget Function(T)? leading,
    required void Function(T?) onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value, isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6B7280)),
            items: items.map((i) => DropdownMenuItem<T>(
                value: i,
                child: Row(children: [
                  if (leading != null) ...[
                    leading(i), const SizedBox(width: 10)],
                  Flexible(child: Text(label(i),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14))),
                ]))).toList(),
            onChanged: onChanged,
          ),
        ),
      );

  InputDecoration _deco(String? hint,
      {Widget? suf, bool ro = false}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        suffixIcon: suf,
        filled: true,
        fillColor: ro ? const Color(0xFFF9FAFB) : Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: _ob(), enabledBorder: _ob(),
        focusedBorder: _ob(c: const Color(0xFF1A237E), w: 2),
        errorBorder: _ob(c: const Color(0xFFC62828)),
        focusedErrorBorder: _ob(c: const Color(0xFFC62828), w: 2),
      );

  OutlineInputBorder _ob({Color? c, double w = 1}) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: c ?? const Color(0xFFE5E7EB), width: w));

  Widget _lbl(String t) => Text(t,
      style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: Color(0xFF374151)));

  Color _rc(String r) => switch (r) {
    'ADMIN'      => const Color(0xFFC62828),
    'SUPERVISOR' => const Color(0xFFF9A825),
    'EMPLEADO'   => const Color(0xFF1A237E),
    'REPARTIDOR' => const Color(0xFFFF6F00),
    'CLIENTE'    => const Color(0xFF2E7D32),
    _            => const Color(0xFF9CA3AF),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS COMPARTIDOS
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final UserModel user;
  final double size;
  const _Avatar({required this.user, required this.size});

  Color get _c => switch (user.rol) {
    'ADMIN'      => const Color(0xFFC62828),
    'SUPERVISOR' => const Color(0xFFF9A825),
    'REPARTIDOR' => const Color(0xFFFF6F00),
    'CLIENTE'    => const Color(0xFF2E7D32),
    _            => const Color(0xFF1A237E),
  };

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: _c.withOpacity(0.12),
    child: Text(
        user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
        style: TextStyle(color: _c, fontSize: size * 0.38,
            fontWeight: FontWeight.bold)),
  );
}

class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge({required this.rol});

  Color get _bg => switch (rol) {
    'ADMIN'      => const Color(0xFFFFEBEE),
    'SUPERVISOR' => const Color(0xFFFFF8E1),
    'EMPLEADO'   => const Color(0xFFE8EAF6),
    'REPARTIDOR' => const Color(0xFFFFF3E0),
    'CLIENTE'    => const Color(0xFFE8F5E9),
    _            => const Color(0xFFF5F5F5),
  };

  Color get _fg => switch (rol) {
    'ADMIN'      => const Color(0xFFC62828),
    'SUPERVISOR' => const Color(0xFFF57F17),
    'EMPLEADO'   => const Color(0xFF1A237E),
    'REPARTIDOR' => const Color(0xFFE65100),
    'CLIENTE'    => const Color(0xFF1B5E20),
    _            => const Color(0xFF616161),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: _bg, borderRadius: BorderRadius.circular(20)),
    child: Text(rol,
        style: TextStyle(color: _fg, fontSize: 11,
            fontWeight: FontWeight.w600)),
  );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tip;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.color,
    required this.tip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
            borderRadius: BorderRadius.circular(8), onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(7),
                child: Icon(icon, color: color, size: 16)))),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFC62828))),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 20),
        ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar')),
      ]),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  final bool hasSearch;
  const _EmptyView({required this.hasSearch});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6), shape: BoxShape.circle),
          child: const Icon(Icons.people_outline_rounded,
              size: 48, color: Color(0xFF1A237E))),
      const SizedBox(height: 16),
      Text(hasSearch ? 'Sin resultados' : 'No hay usuarios',
          style: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      Text(
          hasSearch
              ? 'Intenta con otro término de búsqueda'
              : 'Crea el primer usuario con el botón "Nuevo usuario"',
          style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          textAlign: TextAlign.center),
    ]),
  );
}