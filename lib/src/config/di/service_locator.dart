// lib/src/config/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ─── Externos ──────────────────────────────────────────────────────────────
  final shared = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => shared);

  // ─── Repositories ─────────────────────────────────────────────────────────
  // AuthRepositoryImpl maneja sus propios SharedPreferences internamente
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

  // ─── BLoCs ────────────────────────────────────────────────────────────────
  // registerFactory = nueva instancia cada vez que se pide (correcto para BLoC)
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
}