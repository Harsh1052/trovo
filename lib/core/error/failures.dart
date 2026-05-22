import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Raw message, typically the original exception message. May be technical.
  final String message;

  /// Safe, human-readable string for display in UI widgets and snackbars.
  /// Override in each subtype to provide context-specific copy.
  String get userFriendlyMessage => message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);

  @override
  String get userFriendlyMessage =>
      'No internet connection. Please check your network and try again.';
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);

  // Firebase auth messages are already user-facing (e.g. "wrong password"),
  // so we forward `message` directly here.
  @override
  String get userFriendlyMessage => message;
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again.']);

  @override
  String get userFriendlyMessage =>
      'Something went wrong on our end. Please try again later.';
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);

  @override
  String get userFriendlyMessage => "We couldn't find what you're looking for.";
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied.']);

  @override
  String get userFriendlyMessage =>
      'Permission denied. Please enable the required permissions in Settings.';
}

final class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Unable to determine location.']);

  @override
  String get userFriendlyMessage =>
      'Unable to get your location. Please enable location access in Settings.';
}

final class PaymentFailure extends Failure {
  const PaymentFailure([super.message = 'Payment could not be processed.']);

  @override
  String get userFriendlyMessage =>
      'Payment could not be completed. Please try again or contact support.';
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error.']);

  @override
  String get userFriendlyMessage =>
      'Something went wrong. Please restart the app.';
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);

  @override
  String get userFriendlyMessage => 'An unexpected error occurred. Please try again.';
}
