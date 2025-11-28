import 'package:flutter/material.dart';
import '../widgets/user_form.dart';
import '../../domain/models/user_model.dart';

class UserFormPage extends StatelessWidget {
  final UserModel? editUser;
  const UserFormPage({super.key, this.editUser});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: Text(editUser == null ? 'Crear usuario' : 'Editar usuario')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: UserForm(editUser: editUser)),
        ),
      ),
    );
  }
}
