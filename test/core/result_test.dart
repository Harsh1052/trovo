import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/error/failures.dart';
import 'package:huntermania/core/error/result.dart';

void main() {
  group('Result<T>', () {
    const successResult = Success<int>(42);
    final errResult = Err<int>(const NetworkFailure());

    // ── isSuccess / isFailure ──────────────────────────────────────────────────

    group('isSuccess / isFailure', () {
      test('Success.isSuccess is true', () => expect(successResult.isSuccess, isTrue));
      test('Success.isFailure is false', () => expect(successResult.isFailure, isFalse));
      test('Err.isSuccess is false', () => expect(errResult.isSuccess, isFalse));
      test('Err.isFailure is true', () => expect(errResult.isFailure, isTrue));
    });

    // ── fold ──────────────────────────────────────────────────────────────────

    group('fold', () {
      test('calls onSuccess with data for Success', () {
        final result = successResult.fold(
          onSuccess: (d) => 'got $d',
          onErr: (_) => 'error',
        );
        expect(result, 'got 42');
      });

      test('calls onErr with failure for Err', () {
        final result = errResult.fold(
          onSuccess: (_) => 'success',
          onErr: (f) => f.runtimeType.toString(),
        );
        expect(result, 'NetworkFailure');
      });
    });

    // ── dataOrNull ────────────────────────────────────────────────────────────

    group('dataOrNull', () {
      test('returns data for Success', () => expect(successResult.dataOrNull, 42));
      test('returns null for Err', () => expect(errResult.dataOrNull, isNull));
    });

    // ── failureOrNull ─────────────────────────────────────────────────────────

    group('failureOrNull', () {
      test('returns null for Success', () => expect(successResult.failureOrNull, isNull));
      test('returns failure for Err', () {
        expect(errResult.failureOrNull, isA<NetworkFailure>());
      });
    });

    // ── mapSuccess ────────────────────────────────────────────────────────────

    group('mapSuccess', () {
      test('transforms data on Success', () {
        final mapped = successResult.mapSuccess((d) => d * 2);
        expect(mapped.dataOrNull, 84);
        expect(mapped.isSuccess, isTrue);
      });

      test('passes failure through on Err without calling transform', () {
        var called = false;
        final mapped = errResult.mapSuccess((d) {
          called = true;
          return d * 2;
        });
        expect(called, isFalse);
        expect(mapped.isFailure, isTrue);
        expect(mapped.failureOrNull, isA<NetworkFailure>());
      });

      test('can change the generic type', () {
        final mapped = successResult.mapSuccess((d) => d.toString());
        expect(mapped.dataOrNull, '42');
      });
    });

    // ── when ──────────────────────────────────────────────────────────────────

    group('when', () {
      test('calls onSuccess side-effect for Success', () {
        int? captured;
        successResult.when(
          onSuccess: (d) => captured = d,
          onErr: (_) => fail('should not be called'),
        );
        expect(captured, 42);
      });

      test('calls onErr side-effect for Err', () {
        Failure? captured;
        errResult.when(
          onSuccess: (_) => fail('should not be called'),
          onErr: (f) => captured = f,
        );
        expect(captured, isA<NetworkFailure>());
      });
    });
  });
}
