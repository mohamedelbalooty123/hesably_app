/// Canonical failure types surfaced to the Presentation layer.
///
/// Mappers convert underlying exceptions (network, Supabase, storage, AI edge
/// function) into these types so widgets render user-facing states without
/// leaking implementation details. Extend per feature as needed.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppFailure($message)';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause});
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.cause});
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message, {super.cause});
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.cause});
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure(super.message, {super.cause});
}

/// Maps an arbitrary thrown object to a canonical [AppFailure].
AppFailure mapError(Object error) {
  if (error is AppFailure) return error;
  final cause = error.toString();
  return UnexpectedFailure('Unexpected error: $cause', cause: error);
}
