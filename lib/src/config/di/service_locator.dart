// lib/src/config/di/service_locator.dart
import 'package:equalatam/src/features/financiero/data/repositories/finaciero_repository_impl.dart';
import 'package:equalatam/src/features/financiero/domain/repositories/fianciero_repository.dart';
import 'package:equalatam/src/features/financiero/presentation/bloc/financiero_loc.dart';
import 'package:equalatam/src/features/operations/pedidos/bloc/pedido_bloc.dart';
import 'package:equalatam/src/features/operations/presentation/bloc/guia_bloc.dart';
import 'package:equalatam/src/features/operations/presentation/bloc/tracking_bloc.dart';
import 'package:equalatam/src/features/operations/presentation/data/repositories/guia_repository_impl.dart';
import 'package:equalatam/src/features/operations/presentation/data/repositories/tracking_repository_impl.dart';
import 'package:equalatam/src/features/operations/presentation/domain/repositories/guia_repository.dart';
import 'package:equalatam/src/features/operations/presentation/domain/repositories/tracking_repository.dart';
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
import '../../features/operations/pedidos/data/repositories/pedido_repository_impl.dart';
import '../../features/operations/pedidos/domain/repositories/pedido_repository.dart';



final sl = GetIt.instance;

Future<void> init() async {
  // ─── Externos ──────────────────────────────────────────────────────────────
  final shared = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => shared);
  sl.registerLazySingleton<SucursalRepository>(() => SucursalRepositoryImpl());
  sl.registerLazySingleton<DespachoRepository>(() => DespachoRepositoryImpl());
  sl.registerLazySingleton<ClienteRepository>(() => ClienteRepositoryImpl());
  sl.registerLazySingleton<PedidoRepository>(() => PedidoRepositoryImpl());
  sl.registerLazySingleton<TrackingRepository>(() => TrackingRepositoryImpl());
  sl.registerLazySingleton<GuiaRepository>(() => GuiaRepositoryImpl());
  sl.registerLazySingleton<FinancieroRepository>(() => FinancieroRepositoryImpl());
  // ─── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<IamRepository>(() => IamRepositoryImpl());

  // ─── BLoCs ────────────────────────────────────────────────────────────────
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => IamBloc(repo: sl()));
  sl.registerFactory(() => SucursalBloc(repo: sl()));
  sl.registerFactory(() => DespachoBloc(repo: sl()));
  sl.registerFactory(() => ClienteBloc(repo: sl()));
  sl.registerFactory(() => PedidoBloc(repo: sl()));
  sl.registerFactory(() => TrackingBloc(repo: sl()));
  sl.registerFactory(() => GuiaBloc(repo: sl()));
  sl.registerFactory(() => FinancieroBloc(repo: sl()));

}