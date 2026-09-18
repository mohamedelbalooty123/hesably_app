// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:hesably/app/di/injection.dart' as _i297;
import 'package:hesably/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i601;
import 'package:hesably/features/auth/data/repositories/auth_repository_impl.dart'
    as _i264;
import 'package:hesably/features/auth/domain/repositories/auth_repository.dart'
    as _i936;
import 'package:hesably/features/auth/domain/usecases/restore_session_usecase.dart'
    as _i976;
import 'package:hesably/features/auth/domain/usecases/send_otp_usecase.dart'
    as _i538;
import 'package:hesably/features/auth/domain/usecases/sign_out_usecase.dart'
    as _i44;
import 'package:hesably/features/auth/domain/usecases/verify_otp_usecase.dart'
    as _i151;
import 'package:hesably/features/auth/presentation/cubit/auth_cubit.dart'
    as _i891;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final coreModule = _$CoreModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => coreModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i454.SupabaseClient>(() => coreModule.supabaseClient);
    gh.lazySingleton<_i601.AuthRemoteDataSource>(
      () => _i601.AuthRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i936.AuthRepository>(
      () => _i264.AuthRepositoryImpl(gh<_i601.AuthRemoteDataSource>()),
    );
    gh.factory<_i976.RestoreSessionUseCase>(
      () => _i976.RestoreSessionUseCase(gh<_i936.AuthRepository>()),
    );
    gh.factory<_i538.SendOtpUseCase>(
      () => _i538.SendOtpUseCase(gh<_i936.AuthRepository>()),
    );
    gh.factory<_i44.SignOutUseCase>(
      () => _i44.SignOutUseCase(gh<_i936.AuthRepository>()),
    );
    gh.factory<_i151.VerifyOtpUseCase>(
      () => _i151.VerifyOtpUseCase(gh<_i936.AuthRepository>()),
    );
    gh.lazySingleton<_i891.AuthCubit>(
      () => _i891.AuthCubit(
        gh<_i976.RestoreSessionUseCase>(),
        gh<_i538.SendOtpUseCase>(),
        gh<_i151.VerifyOtpUseCase>(),
        gh<_i44.SignOutUseCase>(),
      ),
    );
    return this;
  }
}

class _$CoreModule extends _i297.CoreModule {}
