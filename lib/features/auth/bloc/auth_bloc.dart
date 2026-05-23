import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthGuestSignInRequested>(_onGuestSignIn);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final AuthRepository _authRepository;
  static const _tag = 'AuthBloc';

  // ── AuthCheckRequested ────────────────────────────────────────────────────

  /// Called once at app start. Reads the persisted session from the repository
  /// and emits [AuthAuthenticated] or [AuthUnauthenticated] accordingly.
  /// The router's [refreshListenable] picks up the state change and drives
  /// navigation away from the splash screen.
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.fetchCurrentUser();
    result.fold(
      onSuccess: (user) => user != null
          ? emit(AuthAuthenticated(user))
          : emit(const AuthUnauthenticated()),
      onErr: (failure) {
        AppLogger.w(
          'Session check failed — treating as unauthenticated',
          tag: _tag,
          error: failure.message,
        );
        emit(const AuthUnauthenticated());
      },
    );
  }

  // ── Email / password ──────────────────────────────────────────────────────

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.signInWithEmailAndPassword(
        event.email, event.password);
    result.fold(
      onSuccess: (user) => emit(AuthAuthenticated(user)),
      onErr: (failure) {
        AppLogger.e('Sign in failed', tag: _tag, error: failure.message);
        emit(AuthError(failure.userFriendlyMessage));
      },
    );
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.createUserWithEmailAndPassword(
        event.email, event.password);
    result.fold(
      onSuccess: (user) => emit(AuthAuthenticated(user)),
      onErr: (failure) {
        AppLogger.e('Sign up failed', tag: _tag, error: failure.message);
        emit(AuthError(failure.userFriendlyMessage));
      },
    );
  }

  // ── Social / guest ────────────────────────────────────────────────────────

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.signInWithGoogle();
    result.fold(
      onSuccess: (user) => emit(AuthAuthenticated(user)),
      onErr: (failure) {
        AppLogger.e('Google sign-in failed', tag: _tag, error: failure.message);
        emit(AuthError(failure.userFriendlyMessage));
      },
    );
  }

  /// Signs in anonymously. If the user later taps "Sign in with Google" the
  /// repository links the two accounts so progress is never lost.
  Future<void> _onGuestSignIn(
    AuthGuestSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.signInAsGuest();
    result.fold(
      onSuccess: (user) => emit(AuthAuthenticated(user)),
      onErr: (failure) {
        AppLogger.e('Guest sign-in failed', tag: _tag, error: failure.message);
        emit(AuthError(failure.userFriendlyMessage));
      },
    );
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Best-effort: navigate away regardless of the result.
    await _authRepository.signOut();
    emit(const AuthUnauthenticated());
  }
}
