import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Global Error Boundary & Crash reporting service wrapping Firebase Crashlytics.
class CrashlyticsObserver {
  CrashlyticsObserver({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics;

  /// Test-only constructor with in-memory error buffer.
  CrashlyticsObserver.testInstance({
    List<Map<String, dynamic>>? errorLog,
  })  : _crashlytics = null,
        _errorLog = errorLog ?? [];

  final FirebaseCrashlytics? _crashlytics;
  List<Map<String, dynamic>>? _errorLog;

  /// Attaches global Flutter framework error and platform dispatcher hooks.
  void initGlobalErrorHooks() {
    if (_errorLog != null) return;

    try {
      final crashlytics = _crashlytics ?? FirebaseCrashlytics.instance;

      // Pass all Flutter framework errors to Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.e('Flutter Framework Error: ${details.exceptionAsString()}',
            tag: 'Crashlytics');
        crashlytics.recordFlutterFatalError(details);
      };

      // Pass all unhandled asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        AppLogger.e('Platform Dispatcher Async Error: $error',
            tag: 'Crashlytics');
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      AppLogger.i('Crashlytics error boundary hooks registered',
          tag: 'Crashlytics');
    } catch (e) {
      AppLogger.w('Failed to initialize Crashlytics hooks: $e',
          tag: 'Crashlytics');
    }
  }

  /// Records a non-fatal exception manually with optional stacktrace and reason.
  Future<void> recordNonFatalError(
    Object exception, {
    StackTrace? stackTrace,
    String? reason,
  }) async {
    if (_errorLog != null) {
      _errorLog!.add({
        'exception': exception.toString(),
        'reason': reason,
        'fatal': false,
      });
      return;
    }

    try {
      final crashlytics = _crashlytics ?? FirebaseCrashlytics.instance;
      await crashlytics.recordError(
        exception,
        stackTrace ?? StackTrace.current,
        reason: reason,
        fatal: false,
      );
    } catch (e) {
      AppLogger.w('Failed to record non-fatal error: $e', tag: 'Crashlytics');
    }
  }

  /// Sets custom diagnostic key-value pairs (e.g. `user_id`, `active_hunt_id`).
  Future<void> setCustomKey(String key, Object value) async {
    if (_errorLog != null) {
      _errorLog!.add({'custom_key': key, 'value': value});
      return;
    }

    try {
      final crashlytics = _crashlytics ?? FirebaseCrashlytics.instance;
      await crashlytics.setCustomKey(key, value);
    } catch (e) {
      AppLogger.w('Failed to set custom Crashlytics key: $e',
          tag: 'Crashlytics');
    }
  }

  /// Inspects in-memory error buffer for unit testing.
  List<Map<String, dynamic>> get errorLog => _errorLog ?? [];
}
