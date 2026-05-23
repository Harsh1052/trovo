import 'package:equatable/equatable.dart';

import '../../../shared/models/user_model.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Before the initial auth check completes. Router holds on the splash screen.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth operation in flight (sign-in, sign-out, or session check).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A valid session exists. Carries the full [UserModel] for UI consumption.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserModel user;

  @override
  List<Object?> get props => [user];
}

/// No session present or the session was explicitly ended.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed. [message] is safe to display in a SnackBar.
final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
