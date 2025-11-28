import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../widgets/log_item.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(LoadLogsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logs de Notificaciones')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: BlocBuilder<NotificationsBloc, NotificationsState>(builder: (context, state) {
          if (state.logs.isEmpty) return const Center(child: Text('No hay logs (aún)'));
          return ListView.separated(
            itemCount: state.logs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) => LogItem(log: state.logs[i]),
          );
        }),
      ),
    );
  }
}
