import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hesably/app/bootstrap.dart';
import 'package:hesably/app/di/injection.dart';
import 'package:hesably/features/auth/presentation/cubit/auth_cubit.dart' as import_auth_cubit;
import 'app_smoke_test.dart' as import_app_smoke_test;

import 'package:hesably/app/app.dart';

void main() {
  /// The bootstrap pipeline (`main → bootstrap`) pre-resolves
  /// `SharedPreferences` during DI, so tests must provide mock values to
  /// avoid touching the platform channel. `bootstrap()` also guards
  /// `Supabase.initialize` behind `isBackendConfigured`, so with no
  /// `SUPABASE_URL`/`SUPABASE_ANON_KEY` the app boots fully offline.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'bootstrap boots to the home shell without a configured backend',
    (tester) async {
      await bootstrap(
        appBuilder: () {
          // Override the real AuthCubit with a mock to simulate an authenticated user
          // so the router redirects to the home shell instead of /login
          getIt.allowReassignment = true;
          final mockAuthCubit = import_auth_cubit.AuthCubit(
            import_app_smoke_test.DummyRestoreSessionUseCase(),
            import_app_smoke_test.DummySendOtpUseCase(),
            import_app_smoke_test.DummyVerifyOtpUseCase(),
            import_app_smoke_test.DummySignOutUseCase(),
          );
          getIt.registerSingleton<import_auth_cubit.AuthCubit>(mockAuthCubit);
          return const HesablyApp();
        },
      );

      await tester.pumpAndSettle();

      // The guarded-boot path reached `runApp` and rendered the home shell.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('الرئيسية'), findsWidgets);
    },
  );
}
