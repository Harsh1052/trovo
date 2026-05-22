import 'failures.dart';

/// Base exception. Prefer throwing typed subclasses in service/data layers.
/// Repositories catch [AppException] and convert to [Failure] via [toFailure].
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  /// Maps this exception to its corresponding [Failure] subtype so repositories
  /// can return `Err(e.toFailure())` in a single line without a long switch.
  Failure toFailure();

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);

  @override
  Failure toFailure() => NetworkFailure(message);
}

final class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed.']);

  @override
  Failure toFailure() => AuthFailure(message);
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Server error. Please try again.']);

  @override
  Failure toFailure() => ServerFailure(message);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found.']);

  @override
  Failure toFailure() => NotFoundFailure(message);
}

final class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission denied.']);

  @override
  Failure toFailure() => PermissionFailure(message);
}

final class LocationException extends AppException {
  const LocationException([super.message = 'Unable to get location.']);

  @override
  Failure toFailure() => LocationFailure(message);
}

final class PaymentException extends AppException {
  const PaymentException([super.message = 'Payment failed.']);

  @override
  Failure toFailure() => PaymentFailure(message);
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Cache operation failed.']);

  @override
  Failure toFailure() => CacheFailure(message);
}
