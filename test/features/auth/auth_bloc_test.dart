import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:huntermania/core/error/failures.dart';
import 'package:huntermania/core/error/result.dart';
import 'package:huntermania/features/auth/bloc/auth_bloc.dart';
import 'package:huntermania/features/auth/bloc/auth_event.dart';
import 'package:huntermania/features/auth/bloc/auth_state.dart';
import 'package:huntermania/shared/models/user_model.dart';
import 'package:huntermania/shared/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  final fakeUser = UserModel(
    uid: 'u1',
    displayName: 'Harsh',
    email: 'harsh@example.com',
    createdAt: DateTime(2025),
    lastActiveAt: DateTime(2025),
  );

  setUp(() {
    repo = MockAuthRepository();
  });

  AuthBloc build() => AuthBloc(authRepository: repo);

  // ── AuthCheckRequested ────────────────────────────────────────────────────

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] when user session exists',
      build: build,
      setUp: () => when(() => repo.fetchCurrentUser())
          .thenAnswer((_) async => Success(fakeUser)),
      act: (b) => b.add(const AuthCheckRequested()),
      expect: () => [const AuthLoading(), AuthAuthenticated(fakeUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] when no session',
      build: build,
      setUp: () => when(() => repo.fetchCurrentUser())
          .thenAnswer((_) async => const Success(null)),
      act: (b) => b.add(const AuthCheckRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] on fetch error (treats as logged out)',
      build: build,
      setUp: () => when(() => repo.fetchCurrentUser())
          .thenAnswer((_) async => const Err(ServerFailure('DB error'))),
      act: (b) => b.add(const AuthCheckRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );
  });

  // ── AuthSignInRequested ───────────────────────────────────────────────────

  group('AuthSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on success',
      build: build,
      setUp: () => when(
        () => repo.signInWithEmailAndPassword('harsh@example.com', 'pass123'),
      ).thenAnswer((_) async => Success(fakeUser)),
      act: (b) => b.add(const AuthSignInRequested(
          email: 'harsh@example.com', password: 'pass123')),
      expect: () => [const AuthLoading(), AuthAuthenticated(fakeUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] on wrong credentials',
      build: build,
      setUp: () => when(
        () => repo.signInWithEmailAndPassword(any(), any()),
      ).thenAnswer(
          (_) async => const Err(AuthFailure('Wrong email or password.'))),
      act: (b) => b.add(const AuthSignInRequested(
          email: 'x@x.com', password: 'wrongpass')),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });

  // ── AuthSignUpRequested ───────────────────────────────────────────────────

  group('AuthSignUpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] on successful registration',
      build: build,
      setUp: () => when(
        () => repo.createUserWithEmailAndPassword(any(), any()),
      ).thenAnswer((_) async => Success(fakeUser)),
      act: (b) => b.add(const AuthSignUpRequested(
          email: 'harsh@example.com', password: 'pass123')),
      expect: () => [const AuthLoading(), AuthAuthenticated(fakeUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] when email is already in use',
      build: build,
      setUp: () => when(
        () => repo.createUserWithEmailAndPassword(any(), any()),
      ).thenAnswer(
          (_) async => const Err(AuthFailure('Email already in use.'))),
      act: (b) => b.add(const AuthSignUpRequested(
          email: 'taken@example.com', password: 'pass123')),
      expect: () => [const AuthLoading(), isA<AuthError>()],
      verify: (b) {
        final state = b.state as AuthError;
        expect(state.message, contains('use'));
      },
    );
  });

  // ── AuthGoogleSignInRequested ─────────────────────────────────────────────

  group('AuthGoogleSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] when Google sign-in succeeds',
      build: build,
      setUp: () => when(() => repo.signInWithGoogle())
          .thenAnswer((_) async => Success(fakeUser)),
      act: (b) => b.add(const AuthGoogleSignInRequested()),
      expect: () => [const AuthLoading(), AuthAuthenticated(fakeUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AuthError] when user cancels Google sign-in',
      build: build,
      setUp: () => when(() => repo.signInWithGoogle()).thenAnswer(
          (_) async => const Err(AuthFailure('Google sign-in cancelled.'))),
      act: (b) => b.add(const AuthGoogleSignInRequested()),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );
  });

  // ── AuthGuestSignInRequested ──────────────────────────────────────────────

  group('AuthGuestSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] for anonymous sign-in',
      build: build,
      setUp: () => when(() => repo.signInAsGuest())
          .thenAnswer((_) async => Success(fakeUser)),
      act: (b) => b.add(const AuthGuestSignInRequested()),
      expect: () => [const AuthLoading(), AuthAuthenticated(fakeUser)],
    );
  });

  // ── AuthSignOutRequested ──────────────────────────────────────────────────

  group('AuthSignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated regardless of sign-out result',
      build: build,
      setUp: () => when(() => repo.signOut())
          .thenAnswer((_) async => const Success(null)),
      act: (b) => b.add(const AuthSignOutRequested()),
      expect: () => [const AuthUnauthenticated()],
    );
  });
}
