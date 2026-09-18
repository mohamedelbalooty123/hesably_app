import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_environment.dart';
import 'di/injection.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart' as import_auth_cubit;
/// Boots the application: binds the root widget, loads environment
/// configuration, initializes the dependency container and optional backend.
///
/// Supabase initialization is skipped when no backend is configured (e.g.
/// widget tests or a local run without `.env`), allowing the app shell,
/// theming, localization, and routing to be exercised in isolation.
Future<void> bootstrap({Widget Function()? appBuilder}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();
  final environment = AppEnvironment.fromDotEnv(
    dotenv.isInitialized ? dotenv.env : const {},
  );

  await configureDependencies(environment);

  if (environment.isBackendConfigured) {
    await Supabase.initialize(
      url: environment.supabaseUrl,
      publishableKey: environment.supabaseAnonKey,
    );
  }

  runApp(appBuilder?.call() ?? const HesablyApp());
}


/// Loads `.env` without failing when the file is absent (e.g. tests, CI
/// where values come from `--dart-define`).
Future<void> loadEnv() async {
  try {
    await dotenv.load();
  } catch (_) {
    // No .env file — rely on dart-define values.
  }
}
