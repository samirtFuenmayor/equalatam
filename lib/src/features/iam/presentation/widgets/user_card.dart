import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;

  const UserCard({super.key, required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(child: Text(user.name.substring(0,1))),
        title: Text(user.name),
        subtitle: Text('${user.email}\nRole: ${user.roleId}'),
        isThreeLine: true,
        trailing: OutlinedButton(onPressed: onEdit, child: const Text('Editar')),
      ),
    );
  }
}
