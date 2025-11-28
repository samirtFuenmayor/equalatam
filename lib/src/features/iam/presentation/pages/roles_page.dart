import 'package:flutter/material.dart';
import '../widgets/role_card.dart';
import '../../data/services/iam_mock_service.dart';
import '../../data/models/role_model.dart';

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});
  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  final _service = IamMockService();
  late Future<List<RoleModel>> _rolesFuture;

  @override
  void initState() {
    super.initState();
    _rolesFuture = _service.getRoles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roles')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder<List<RoleModel>>(
          future: _rolesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final roles = snapshot.data!;
            return ListView.separated(
              itemCount: roles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => RoleCard(role: roles[i], onEdit: (){}),
            );
          },
        ),
      ),
    );
  }
}
