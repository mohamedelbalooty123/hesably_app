import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hesably/app/bootstrap.dart';

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
      await bootstrap();
      await tester.pumpAndSettle();

      // The guarded-boot path reached `runApp` and rendered the home shell.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('الرئيسية'), findsWidgets);
    },
  );
}
