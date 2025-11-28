import 'package:flutter/material.dart';
import '../widgets/user_card.dart';
import '../../data/services/iam_mock_service.dart';
import '../../domain/models/user_model.dart';
import 'user_form_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _service = IamMockService();
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _service.getUsers();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Usuarios')),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Usuarios del Sistema', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserFormPage())), icon: const Icon(Icons.add), label: const Text('Crear usuario')),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<UserModel>>(
                      future: _usersFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final users = snapshot.data!;
                        return ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => UserCard(
                            user: users[i],
                            onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserFormPage(editUser: users[i]))),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
