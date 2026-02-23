// lib/src/config/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/iam/domain/repositories/iam_repository.dart';
import '../../features/iam/data/repositories/iam_repository_impl.dart';
import '../../features/iam/presentation/bloc/iam_bloc.dart';
import '../../features/network/presentation/data/repositories/sucursal_repository_impl.dart';
import '../../features/network/presentation/data/repositories/despacho_repository_impl.dart';
import '../../features/network/presentation/domain/repositories/sucursal_repository.dart';
import '../../features/network/presentation/domain/repositories/despacho_repository.dart';
import '../../features/network/presentation/bloc/sucursal_bloc.dart';
import '../../features/network/presentation/bloc/despacho_bloc.dart';
import '../../features/iam/presentation/bloc/cliente_bloc.dart';
import '../../features/iam/domain/repositories/cliente_repository.dart';
import '../../features/iam/data/repositories/cliente_repository_impl.dart';




final sl = GetIt.instance;

Future<void> init() async {
  // ─── Externos ──────────────────────────────────────────────────────────────
  final shared = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => shared);
  sl.registerLazySingleton<SucursalRepository>(() => SucursalRepositoryImpl());
  sl.registerLazySingleton<DespachoRepository>(() => DespachoRepositoryImpl());
  sl.registerLazySingleton<ClienteRepository>(() => ClienteRepositoryImpl());

  // ─── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<IamRepository>(() => IamRepositoryImpl());

  // ─── BLoCs ────────────────────────────────────────────────────────────────
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => IamBloc(repo: sl()));
  sl.registerFactory(() => SucursalBloc(repo: sl()));
  sl.registerFactory(() => DespachoBloc(repo: sl()));
  sl.registerFactory(() => ClienteBloc(repo: sl()));

}