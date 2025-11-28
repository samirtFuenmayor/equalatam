import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../widgets/template_card.dart';
import '../../domain/entities/notification_template.dart';
import '../../data/models/notification_template_model.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _channel = TextEditingController(text: 'email');
  final _subject = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _channel.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _saveTemplate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final t = NotificationTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text,
      channel: _channel.text,
      subject: _subject.text,
      body: _body.text,
    );
    context.read<NotificationsBloc>().add(CreateTemplate(t));
    _name.clear(); _subject.clear(); _body.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plantillas de Notificación')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre plantilla'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                      TextFormField(controller: _channel, decoration: const InputDecoration(labelText: 'Canal (email|sms)'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                      TextFormField(controller: _subject, decoration: const InputDecoration(labelText: 'Asunto (email)'), ),
                      TextFormField(controller: _body, decoration: const InputDecoration(labelText: 'Cuerpo (usa {{waybill}})'), maxLines: 3),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        ElevatedButton(onPressed: _saveTemplate, child: const Text('Guardar plantilla')),
                      ])
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<NotificationsBloc, NotificationsState>(builder: (context, state) {
                if (state.loadingTemplates) return const Center(child: CircularProgressIndicator());
                if (state.templates.isEmpty) return const Center(child: Text('No hay plantillas'));
                return ListView.separated(
                  itemCount: state.templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = state.templates[i];
                    return TemplateCard(template: t, onEdit: () {/* abrir editor */}, onDelete: () => context.read<NotificationsBloc>().add(DeleteTemplateEvent(t.id)));
                  },
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}
