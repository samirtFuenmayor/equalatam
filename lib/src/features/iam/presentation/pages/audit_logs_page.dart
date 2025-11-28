import 'package:flutter/material.dart';
import '../../data/services/iam_mock_service.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final _service = IamMockService();
  late Future<List<String>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _service.getAuditLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder<List<String>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final logs = snapshot.data!;
            return ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) => ListTile(title: Text(logs[i])),
            );
          },
        ),
      ),
    );
  }
}
