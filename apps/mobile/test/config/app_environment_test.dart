import 'package:flutter_test/flutter_test.dart';
import 'package:hesably/app/config/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('fromDotEnv maps values from the env map', () {
      final env = AppEnvironment.fromDotEnv({
        'SUPABASE_URL': 'https://abc.supabase.co',
        'SUPABASE_ANON_KEY': 'anon-key',
      });

      expect(env.supabaseUrl, 'https://abc.supabase.co');
      expect(env.supabaseAnonKey, 'anon-key');
      expect(env.isBackendConfigured, isTrue);
    });

    test('isBackendConfigured is false when keys are missing', () {
      final env = AppEnvironment.fromDotEnv({});

      expect(env.isBackendConfigured, isFalse);
      expect(env.supabaseUrl, isEmpty);
      expect(env.supabaseAnonKey, isEmpty);
    });
  });
}
