import 'failures.dart';

/// A discriminated union representing the outcome of a fallible operation.
///
/// Repositories return `Future<Result<T>>`; BLoCs pattern-match using [fold]
/// instead of try/catch. This guarantees that every failure path is handled
/// exhaustively at compile time — unhandled exceptions can no longer silently
/// crash the app.
///
/// ```dart
/// final result = await huntRepository.fetchHunt(id);
/// result.fold(
///   onSuccess: (hunt) => emit(HuntLoaded(hunt)),
///   onErr:     (f)    => emit(HuntError(f.userFriendlyMessage)),
/// );
/// ```
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

// ── Extension helpers ─────────────────────────────────────────────────────────

extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  /// Runs [onSuccess] or [onErr] and returns the result.
  /// Use this when the BLoC handler needs to produce a value from the result.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onErr,
  }) =>
      switch (this) {
        Success<T>(:final data) => onSuccess(data),
        Err<T>(:final failure) => onErr(failure),
      };

  /// Data from a [Success], or null for an [Err].
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Err<T>() => null,
      };

  /// Failure from an [Err], or null for a [Success].
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Err<T>(:final failure) => failure,
      };

  /// Transforms the success value without touching the failure side.
  ///
  /// ```dart
  /// final nameResult = userResult.mapSuccess((u) => u.displayName);
  /// ```
  Result<R> mapSuccess<R>(R Function(T data) transform) => switch (this) {
        Success<T>(:final data) => Success(transform(data)),
        Err<T>(:final failure) => Err(failure),
      };

  /// Calls [onSuccess] or [onErr] for side-effects only (returns void).
  ///
  /// Prefer [fold] when you need a return value.
  void when({
    required void Function(T data) onSuccess,
    required void Function(Failure failure) onErr,
  }) =>
      switch (this) {
        Success<T>(:final data) => onSuccess(data),
        Err<T>(:final failure) => onErr(failure),
      };
}
