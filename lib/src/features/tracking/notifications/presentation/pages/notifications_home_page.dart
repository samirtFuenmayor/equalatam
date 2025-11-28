import 'package:equalatam/src/features/tracking/notifications/domain/entities/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../widgets/notification_card.dart';
import 'send_test_page.dart';
import 'templates_page.dart';
import 'logs_page.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../data/datasources/notifications_remote_ds.dart';

class NotificationsHomePage extends StatelessWidget {
  const NotificationsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = NotificationsRepositoryImpl(NotificationsRemoteDataSource());
    return BlocProvider(
      create: (_) => NotificationsBloc(repository: repo)..add(LoadTemplates())..add(LoadLogsEvent()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: LayoutBuilder(builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (isDesktop) const SizedBox(width: 260, child: SizedBox()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Motor de Notificaciones', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 10, children: [
                        ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Enviar prueba'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendTestPage()))),
                        ElevatedButton.icon(icon: const Icon(Icons.list), label: const Text('Plantillas'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplatesPage()))),
                        ElevatedButton.icon(icon: const Icon(Icons.history), label: const Text('Logs'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsPage()))),
                      ]),
                      const SizedBox(height: 14),
                      BlocBuilder<NotificationsBloc, NotificationsState>(builder: (context, state) {
                        return Expanded(
                          child: state.templates.isEmpty
                              ? const Center(child: Text('No hay plantillas (mock) — crea una'))
                              : ListView.separated(
                            itemCount: state.templates.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final t = state.templates[i];
                              // create a sample notification preview
                              final preview = NotificationEntity(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                channel: t.channel,
                                to: t.channel == 'email' ? 'cliente@demo.com' : '+593987654321',
                                subject: t.subject,
                                body: t.body.replaceAll('{{waybill}}', 'WB123456'),
                                scheduledAt: DateTime.now(),
                                status: 'pending',
                              );
                              return NotificationCard(notification: preview, onSend: () => context.read<NotificationsBloc>().add(SendNotificationEvent(preview)));
                            },
                          ),
                        );
                      })
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
