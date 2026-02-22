// lib/src/features/iam/presentation/pages/users_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart' as di;
import '../../domain/models/user_model.dart';
import '../bloc/iam_bloc.dart';

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

class _UsersView extends StatefulWidget {
  const _UsersView();
  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _searchCtrl = TextEditingController();
  String _search     = '';
  String _filterRol  = 'Todos';

  static const _roles = ['Todos', 'ADMIN', 'SUPERVISOR', 'EMPLEADO', 'REPARTIDOR', 'CLIENTE'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserModel> _filter(List<UserModel> users) {
    return users.where((u) {
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.correo.toLowerCase().contains(q) ||
          u.rol.toLowerCase().contains(q);
      final matchRol = _filterRol == 'Todos' || u.rol == _filterRol;
      return matchSearch && matchRol;
    }).toList();
  }

  void _showForm(BuildContext ctx, {UserModel? user}) {
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

  void _confirmDelete(BuildContext ctx, UserModel user) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Eliminar usuario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Eliminar a ${user.fullName}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ctx.read<IamBloc>()
                  .add(IamUserDeleteRequested(user.id));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return BlocConsumer<IamBloc, IamState>(
      listener: (ctx, state) {
        if (state is IamUsersLoaded && state.message != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(state.message!),
            ]),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ));
        }
        if (state is IamError) {
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
      builder: (ctx, state) {
        final users = state is IamUsersLoaded ? _filter(state.users) : <UserModel>[];
        final total = state is IamUsersLoaded ? state.users.length : 0;
        final loading = state is IamLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(children: [
            // ─── Header ───────────────────────────────────────────────────
            _Header(
              total: total,
              onAdd: () => _showForm(ctx),
              onRefresh: () => ctx.read<IamBloc>().add(IamUsersRequested()),
            ),

            // ─── Barra búsqueda + filtros ──────────────────────────────────
            _SearchBar(
              ctrl: _searchCtrl,
              selectedRol: _filterRol,
              roles: _roles,
              onSearch: (v) => setState(() => _search = v),
              onFilter: (v) => setState(() => _filterRol = v),
            ),

            // ─── Contenido ─────────────────────────────────────────────────
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(
                  color: Color(0xFF1A237E)))
                  : state is IamError
                  ? _ErrorView(
                  message: state.message,
                  onRetry: () =>
                      ctx.read<IamBloc>().add(IamUsersRequested()))
                  : users.isEmpty
                  ? _EmptyView(hasSearch: _search.isNotEmpty)
                  : isDesktop
                  ? _TableView(
                users: users,
                onEdit: (u) => _showForm(ctx, user: u),
                onToggle: (u) => ctx
                    .read<IamBloc>()
                    .add(IamUserToggleRequested(u.id)),
                onDelete: (u) => _confirmDelete(ctx, u),
              )
                  : _CardListView(
                users: users,
                onEdit: (u) => _showForm(ctx, user: u),
                onToggle: (u) => ctx
                    .read<IamBloc>()
                    .add(IamUserToggleRequested(u.id)),
                onDelete: (u) => _confirmDelete(ctx, u),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int total;
  final VoidCallback onAdd, onRefresh;
  const _Header({required this.total, required this.onAdd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Gestión de Usuarios',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text('$total usuarios registrados',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ])),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
          onPressed: onRefresh,
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: 8),
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
                  horizontal: isWide ? 16 : 12, vertical: 0),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(isWide ? 'Nuevo usuario' : 'Nuevo',
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ─── BARRA DE BÚSQUEDA ────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final String selectedRol;
  final List<String> roles;
  final void Function(String) onSearch, onFilter;

  const _SearchBar({
    required this.ctrl, required this.selectedRol,
    required this.roles, required this.onSearch, required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: isWide
          ? Row(children: [
        Expanded(child: _searchField()),
        const SizedBox(width: 12),
        _rolFilter(),
      ])
          : Column(children: [
        _searchField(),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: _rolFilter()),
      ]),
    );
  }

  Widget _searchField() => TextField(
    controller: ctrl,
    onChanged: onSearch,
    decoration: InputDecoration(
      hintText: 'Buscar por nombre, usuario o email...',
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: const Icon(Icons.search_rounded,
          color: Color(0xFF9CA3AF), size: 20),
      suffixIcon: ctrl.text.isNotEmpty
          ? IconButton(
          icon: const Icon(Icons.close_rounded,
              color: Color(0xFF9CA3AF), size: 18),
          onPressed: () {
            ctrl.clear();
            onSearch('');
          })
          : null,
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
    ),
  );

  Widget _rolFilter() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
        color: Colors.white,
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
              if (r != 'Todos')
                Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: _rolColor(r), shape: BoxShape.circle)),
              Text(r, style: const TextStyle(fontSize: 13)),
            ]))).toList(),
        onChanged: (v) => onFilter(v!),
      ),
    ),
  );

  Color _rolColor(String rol) {
    switch (rol) {
      case 'ADMIN':      return const Color(0xFFC62828);
      case 'SUPERVISOR': return const Color(0xFFF9A825);
      case 'EMPLEADO':   return const Color(0xFF1A237E);
      case 'REPARTIDOR': return const Color(0xFFFF6F00);
      case 'CLIENTE':    return const Color(0xFF2E7D32);
      default:           return const Color(0xFF9CA3AF);
    }
  }
}

// ─── VISTA TABLA (Desktop) ────────────────────────────────────────────────────
class _TableView extends StatelessWidget {
  final List<UserModel> users;
  final void Function(UserModel) onEdit, onToggle, onDelete;

  const _TableView({
    required this.users, required this.onEdit,
    required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2.5),
              2: FlexColumnWidth(1.5),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(120),
            },
            children: [
              // Encabezado
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: ['Usuario', 'Correo', 'Rol', 'Estado', 'Acciones']
                    .map((h) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Text(h,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280)))))
                    .toList(),
              ),
              // Filas
              ...users.map((u) => TableRow(
                decoration: BoxDecoration(
                  border: const Border(
                      top: BorderSide(color: Color(0xFFE5E7EB))),
                  color: u.activo ? Colors.white : const Color(0xFFFAFAFA),
                ),
                children: [
                  // Usuario
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14, color: Color(0xFF1A1A2E)),
                              overflow: TextOverflow.ellipsis),
                          Text('@${u.username}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9CA3AF))),
                        ],
                      )),
                    ]),
                  ),
                  // Email
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(u.correo,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF374151)),
                          overflow: TextOverflow.ellipsis)),
                  // Rol
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: _RolBadge(rol: u.rol)),
                  // Estado
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Switch(
                        value: u.activo,
                        activeColor: const Color(0xFF2E7D32),
                        onChanged: (_) => onToggle(u),
                      )),
                  // Acciones
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(children: [
                        _ActionBtn(
                            icon: Icons.edit_outlined,
                            color: const Color(0xFF1A237E),
                            tooltip: 'Editar',
                            onTap: () => onEdit(u)),
                        const SizedBox(width: 4),
                        _ActionBtn(
                            icon: Icons.delete_outline_rounded,
                            color: const Color(0xFFC62828),
                            tooltip: 'Eliminar',
                            onTap: () => onDelete(u)),
                      ])),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── VISTA CARDS (Móvil) ──────────────────────────────────────────────────────
class _CardListView extends StatelessWidget {
  final List<UserModel> users;
  final void Function(UserModel) onEdit, onToggle, onDelete;

  const _CardListView({
    required this.users, required this.onEdit,
    required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _UserCard(
        user: users[i],
        onEdit: () => onEdit(users[i]),
        onToggle: () => onToggle(users[i]),
        onDelete: () => onDelete(users[i]),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit, onToggle, onDelete;

  const _UserCard({
    required this.user, required this.onEdit,
    required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: [
          _Avatar(user: user, size: 44),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15,
                  color: Color(0xFF1A1A2E))),
              Text('@${user.username}', style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 4),
              Text(user.correo, style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280))),
            ],
          )),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: Color(0xFF9CA3AF), size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1A237E)),
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
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _RolBadge(rol: user.rol),
          const Spacer(),
          Text(user.activo ? 'Activo' : 'Inactivo',
              style: TextStyle(
                  fontSize: 12,
                  color: user.activo
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF9CA3AF))),
          const SizedBox(width: 8),
          Switch(
            value: user.activo,
            activeColor: const Color(0xFF2E7D32),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (_) => onToggle(),
          ),
        ]),
      ]),
    );
  }
}

// ─── FORMULARIO (BottomSheet) ─────────────────────────────────────────────────
class _UserFormSheet extends StatefulWidget {
  final UserModel? user;
  const _UserFormSheet({this.user});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _nomCtrl    = TextEditingController();
  final _apCtrl     = TextEditingController();
  final _userCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  String _rol       = 'EMPLEADO';
  bool   _obscure   = true;

  bool get _isEditing => widget.user != null;

  static const _roles = ['ADMIN', 'SUPERVISOR', 'EMPLEADO', 'REPARTIDOR', 'CLIENTE'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nomCtrl.text   = widget.user!.nombre;
      _apCtrl.text    = widget.user!.apellido;
      _userCtrl.text  = widget.user!.username;
      _emailCtrl.text = widget.user!.correo;
      _rol            = widget.user!.rol;
    }
  }

  @override
  void dispose() {
    for (final c in [_nomCtrl, _apCtrl, _userCtrl, _emailCtrl, _passCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nombre':   _nomCtrl.text.trim(),
      'apellido': _apCtrl.text.trim(),
      'username': _userCtrl.text.trim(),
      'correo':    _emailCtrl.text.trim(),
      'rol':      _rol,
      if (!_isEditing) 'password': _passCtrl.text,
    };

    if (_isEditing) {
      context.read<IamBloc>()
          .add(IamUserUpdateRequested(widget.user!.id, data));
    } else {
      context.read<IamBloc>().add(IamUserCreateRequested(data));
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
        // Handle
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),

        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 8, 24,
                MediaQuery.of(context).viewInsets.bottom + 24),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
                  Row(children: [
                    Expanded(child: Text(
                        _isEditing ? 'Editar usuario' : 'Nuevo usuario',
                        style: const TextStyle(fontSize: 20,
                            fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop()),
                  ]),
                  const SizedBox(height: 20),

                  // Nombre + Apellido
                  Row(children: [
                    Expanded(child: _field('Nombre', _nomCtrl,
                        hint: 'Juan', required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Apellido', _apCtrl,
                        hint: 'Pérez', required: true)),
                  ]),
                  const SizedBox(height: 14),

                  // Usuario
                  _field('Usuario', _userCtrl,
                      hint: 'usuario123', required: true,
                      readOnly: _isEditing),
                  const SizedBox(height: 14),

                  // Email
                  _field('Correo', _emailCtrl,
                      hint: 'correo@ejemplo.com',
                      keyboard: TextInputType.emailAddress,
                      required: true,
                      extraValidator: (v) => (!v!.contains('@') || !v.contains('.'))
                          ? 'Email inválido' : null),
                  const SizedBox(height: 14),

                  // Rol
                  _label('Rol'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _rol,
                        isExpanded: true,
                        items: _roles.map((r) => DropdownMenuItem(
                            value: r,
                            child: Row(children: [
                              Container(width: 8, height: 8,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                      color: _rolColor(r),
                                      shape: BoxShape.circle)),
                              Text(r),
                            ]))).toList(),
                        onChanged: (v) => setState(() => _rol = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Contraseña (solo en crear)
                  if (!_isEditing) ...[
                    _label('Contraseña'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Mínimo 6 caracteres',
                        hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 14),
                        suffixIcon: IconButton(
                            icon: Icon(
                                _obscure ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20, color: const Color(0xFF9CA3AF)),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure)),
                        filled: true, fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF1A237E), width: 2)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFC62828))),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 24),

                  // Botón
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(
                          _isEditing ? 'Guardar cambios' : 'Crear usuario',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {
    String? hint, bool required = false, bool readOnly = false,
    TextInputType? keyboard, String? Function(String?)? extraValidator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboard,
        style: TextStyle(color: readOnly
            ? const Color(0xFF9CA3AF) : null),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          filled: true, fillColor: readOnly
            ? const Color(0xFFF9FAFB) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
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
        ),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) return 'Campo requerido';
          if (extraValidator != null) return extraValidator(v);
          return null;
        },
      ),
    ]);
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: Color(0xFF374151)));

  Color _rolColor(String rol) {
    switch (rol) {
      case 'ADMIN':      return const Color(0xFFC62828);
      case 'SUPERVISOR': return const Color(0xFFF9A825);
      case 'EMPLEADO':   return const Color(0xFF1A237E);
      case 'REPARTIDOR': return const Color(0xFFFF6F00);
      case 'CLIENTE':    return const Color(0xFF2E7D32);
      default:           return const Color(0xFF9CA3AF);
    }
  }
}

// ─── WIDGETS COMPARTIDOS ──────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final UserModel user;
  final double size;
  const _Avatar({required this.user, required this.size});

  Color get _color {
    switch (user.rol) {
      case 'ADMIN':      return const Color(0xFFC62828);
      case 'SUPERVISOR': return const Color(0xFFF9A825);
      case 'REPARTIDOR': return const Color(0xFFFF6F00);
      case 'CLIENTE':    return const Color(0xFF2E7D32);
      default:           return const Color(0xFF1A237E);
    }
  }

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: _color.withOpacity(0.12),
    child: Text(
      user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
      style: TextStyle(color: _color, fontSize: size * 0.4,
          fontWeight: FontWeight.bold),
    ),
  );
}

class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge({required this.rol});

  Color get _bg {
    switch (rol) {
      case 'ADMIN':      return const Color(0xFFFFEBEE);
      case 'SUPERVISOR': return const Color(0xFFFFF8E1);
      case 'EMPLEADO':   return const Color(0xFFE8EAF6);
      case 'REPARTIDOR': return const Color(0xFFFFF3E0);
      case 'CLIENTE':    return const Color(0xFFE8F5E9);
      default:           return const Color(0xFFF5F5F5);
    }
  }

  Color get _fg {
    switch (rol) {
      case 'ADMIN':      return const Color(0xFFC62828);
      case 'SUPERVISOR': return const Color(0xFFF57F17);
      case 'EMPLEADO':   return const Color(0xFF1A237E);
      case 'REPARTIDOR': return const Color(0xFFE65100);
      case 'CLIENTE':    return const Color(0xFF1B5E20);
      default:           return const Color(0xFF616161);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _bg,
        borderRadius: BorderRadius.circular(20)),
    child: Text(rol, style: TextStyle(
        color: _fg, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color,
    required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(icon, color: color, size: 16))),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded,
              size: 48, color: Color(0xFFC62828))),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(
          fontSize: 14, color: Color(0xFF6B7280)),
          textAlign: TextAlign.center),
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
  );
}

class _EmptyView extends StatelessWidget {
  final bool hasSearch;
  const _EmptyView({required this.hasSearch});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6), shape: BoxShape.circle),
          child: const Icon(Icons.people_outline_rounded,
              size: 48, color: Color(0xFF1A237E))),
      const SizedBox(height: 16),
      Text(
          hasSearch ? 'No se encontraron resultados' : 'No hay usuarios aún',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: Color(0xFF374151))),
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