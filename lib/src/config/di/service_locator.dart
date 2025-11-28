import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final shared = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => shared);

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

  // Blocs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
}
