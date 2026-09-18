/// Single source of truth for environment-provided configuration.
///
/// Values are read from `--dart-define` first (CI/CD), then fall back to
/// the `.env` file loaded via flutter_dotenv (local development).
class AppEnvironment {
  AppEnvironment({required this.supabaseUrl, required this.supabaseAnonKey});

  static const String _urlDefine = String.fromEnvironment('SUPABASE_URL');
  static const String _keyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isBackendConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Builds an environment from the `.env` file values (loaded already via
  /// flutter_dotenv), preferring compile-time `--dart-define` overrides.
  factory AppEnvironment.fromDotEnv(Map<String, String> env) {
    return AppEnvironment(
      supabaseUrl: _urlDefine.isNotEmpty
          ? _urlDefine
          : (env['SUPABASE_URL'] ?? ''),
      supabaseAnonKey: _keyDefine.isNotEmpty
          ? _keyDefine
          : (env['SUPABASE_ANON_KEY'] ?? ''),
    );
  }
}
