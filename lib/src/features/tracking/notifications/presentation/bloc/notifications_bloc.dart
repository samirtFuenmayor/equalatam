import 'package:flutter_bloc/flutter_bloc.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;

  NotificationsBloc({required this.repository}) : super(const NotificationsState()) {
    on<LoadTemplates>(_onLoadTemplates);
    on<CreateTemplate>(_onCreateTemplate);
    on<DeleteTemplateEvent>(_onDeleteTemplate);
    on<SendNotificationEvent>(_onSendNotification);
    on<ScheduleNotificationEvent>(_onScheduleNotification);
    on<LoadLogsEvent>(_onLoadLogs);
  }

  Future<void> _onLoadTemplates(LoadTemplates event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(loadingTemplates: true, error: null));
    try {
      final templates = await repository.getTemplates();
      emit(state.copyWith(loadingTemplates: false, templates: templates));
    } catch (e) {
      emit(state.copyWith(loadingTemplates: false, error: e.toString()));
    }
  }

  Future<void> _onCreateTemplate(CreateTemplate event, Emitter<NotificationsState> emit) async {
    try {
      await repository.createTemplate(event.template);
      add(LoadTemplates());
      emit(state.copyWith(message: 'Plantilla creada (mock)'));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteTemplate(DeleteTemplateEvent event, Emitter<NotificationsState> emit) async {
    try {
      await repository.deleteTemplate(event.templateId);
      add(LoadTemplates());
      emit(state.copyWith(message: 'Plantilla eliminada (mock)'));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSendNotification(SendNotificationEvent event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(sending: true, error: null));
    try {
      await repository.sendNotification(event.notification);
      add(LoadLogsEvent());
      emit(state.copyWith(sending: false, message: 'Notificación enviada (mock)'));
    } catch (e) {
      emit(state.copyWith(sending: false, error: e.toString()));
    }
  }

  Future<void> _onScheduleNotification(ScheduleNotificationEvent event, Emitter<NotificationsState> emit) async {
    try {
      await repository.scheduleNotification(event.notification);
      add(LoadLogsEvent());
      emit(state.copyWith(message: 'Notificación programada (mock)'));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadLogs(LoadLogsEvent event, Emitter<NotificationsState> emit) async {
    try {
      final logs = await repository.getLogs();
      emit(state.copyWith(logs: logs));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
