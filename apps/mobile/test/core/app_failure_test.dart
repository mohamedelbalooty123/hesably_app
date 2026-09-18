import 'package:flutter_test/flutter_test.dart';
import 'package:hesably/core/error/app_failure.dart';

void main() {
  group('mapError', () {
    test('passes through canonical failures', () {
      const failure = NetworkFailure('no connection');
      expect(mapError(failure), same(failure));
    });

    test('wraps unknown errors as UnexpectedFailure', () {
      final result = mapError(StateError('boom'));
      expect(result, isA<UnexpectedFailure>());
    });
  });
}
