import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_environment.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@module
abstract class CoreModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}

@InjectableInit()
Future<void> configureDependencies(AppEnvironment environment) async {
  getIt.registerSingleton<AppEnvironment>(environment);
  await getIt.init();
}
