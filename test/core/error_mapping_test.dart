import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/error/exceptions.dart';
import 'package:huntermania/core/error/failures.dart';

void main() {
  group('AppException.toFailure() mapping', () {
    // Each AppException subtype must map to its corresponding Failure subtype.
    // This prevents accidental breaks when the sealed-class hierarchy is
    // extended or refactored.

    test('NetworkException maps to NetworkFailure', () {
      const ex = NetworkException('No internet');
      final failure = ex.toFailure();
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'No internet');
    });

    test('NetworkException uses default message when none provided', () {
      const ex = NetworkException();
      expect(ex.toFailure().message, 'No internet connection.');
    });

    test('AuthException maps to AuthFailure', () {
      const ex = AuthException('Invalid credentials');
      final failure = ex.toFailure();
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Invalid credentials');
    });

    test('ServerException maps to ServerFailure', () {
      const ex = ServerException('500 Internal');
      final failure = ex.toFailure();
      expect(failure, isA<ServerFailure>());
      expect(failure.message, '500 Internal');
    });

    test('NotFoundException maps to NotFoundFailure', () {
      const ex = NotFoundException('Hunt not found');
      final failure = ex.toFailure();
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, 'Hunt not found');
    });

    test('PermissionException maps to PermissionFailure', () {
      const ex = PermissionException('Camera denied');
      final failure = ex.toFailure();
      expect(failure, isA<PermissionFailure>());
      expect(failure.message, 'Camera denied');
    });

    test('LocationException maps to LocationFailure', () {
      const ex = LocationException('GPS unavailable');
      final failure = ex.toFailure();
      expect(failure, isA<LocationFailure>());
      expect(failure.message, 'GPS unavailable');
    });

    test('PaymentException maps to PaymentFailure', () {
      const ex = PaymentException('Card declined');
      final failure = ex.toFailure();
      expect(failure, isA<PaymentFailure>());
      expect(failure.message, 'Card declined');
    });

    test('CacheException maps to CacheFailure', () {
      const ex = CacheException('Read failed');
      final failure = ex.toFailure();
      expect(failure, isA<CacheFailure>());
      expect(failure.message, 'Read failed');
    });

    // ── toString ──────────────────────────────────────────────────────────────

    group('toString', () {
      test('includes runtime type and message', () {
        const ex = NetworkException('offline');
        expect(ex.toString(), contains('NetworkException'));
        expect(ex.toString(), contains('offline'));
      });

      test('AuthException toString is correctly formatted', () {
        const ex = AuthException('bad token');
        expect(ex.toString(), 'AuthException: bad token');
      });
    });

    // ── Failure userFriendlyMessage ──────────────────────────────────────────

    group('Failure.userFriendlyMessage', () {
      test('NetworkFailure returns network-specific user message', () {
        const f = NetworkFailure();
        expect(f.userFriendlyMessage, contains('internet'));
      });

      test('AuthFailure forwards the raw message directly', () {
        const f = AuthFailure('Wrong password');
        expect(f.userFriendlyMessage, 'Wrong password');
      });

      test('ServerFailure returns generic server error copy', () {
        const f = ServerFailure();
        expect(f.userFriendlyMessage, contains('went wrong'));
      });

      test('NotFoundFailure returns not-found copy', () {
        const f = NotFoundFailure();
        expect(f.userFriendlyMessage, contains("find"));
      });

      test('PermissionFailure mentions Settings in its copy', () {
        const f = PermissionFailure();
        expect(f.userFriendlyMessage, contains('Settings'));
      });

      test('LocationFailure mentions location access', () {
        const f = LocationFailure();
        expect(f.userFriendlyMessage, contains('location'));
      });

      test('PaymentFailure mentions support', () {
        const f = PaymentFailure();
        expect(f.userFriendlyMessage, contains('support'));
      });

      test('CacheFailure asks user to restart the app', () {
        const f = CacheFailure();
        expect(f.userFriendlyMessage, contains('restart'));
      });

      test('UnknownFailure returns generic try-again copy', () {
        const f = UnknownFailure();
        expect(f.userFriendlyMessage, contains('unexpected'));
      });
    });
  });
}
