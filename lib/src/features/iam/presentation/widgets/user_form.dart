import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';
import '../../data/services/iam_mock_service.dart';
import '../../data/models/role_model.dart';

class UserForm extends StatefulWidget {
  final UserModel? editUser;
  const UserForm({super.key, this.editUser});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = IamMockService();

  late TextEditingController _name;
  late TextEditingController _email;
  String? _roleId;
  bool _active = true;
  List<RoleModel> _roles = [];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.editUser?.name ?? '');
    _email = TextEditingController(text: widget.editUser?.email ?? '');
    _roleId = widget.editUser?.roleId ?? 'r_viewer';
    _active = widget.editUser?.active ?? true;
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final roles = await _service.getRoles();
    setState(() { _roles = roles; });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = UserModel(
      id: widget.editUser?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      email: _email.text.trim(),
      roleId: _roleId ?? 'r_viewer',
      active: _active,
    );
    if (widget.editUser == null) {
      await _service.createUser(user);
    } else {
      await _service.updateUser(user);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario guardado (mock)')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.editUser == null ? 'Crear Usuario' : 'Editar Usuario', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _roleId,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: _roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                onChanged: (v) => setState(() => _roleId = v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(title: const Text('Activo'), value: _active, onChanged: (v) => setState(() => _active = v)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _save, child: const Text('Guardar')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
