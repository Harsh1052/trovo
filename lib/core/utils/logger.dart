import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Global app logger. Use the static helpers rather than creating instances.
///
/// ```dart
/// AppLogger.d('Checkpoint reached', tag: 'ActiveHunt');
/// AppLogger.e('Auth failed', error: e, stackTrace: st);
/// ```
abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    // Silence all logs in release builds.
    level: kReleaseMode ? Level.off : Level.trace,
  );

  static void t(String message, {String? tag}) =>
      _logger.t(_format(message, tag));

  static void d(String message, {String? tag}) =>
      _logger.d(_format(message, tag));

  static void i(String message, {String? tag}) =>
      _logger.i(_format(message, tag));

  static void w(String message, {String? tag, Object? error}) =>
      _logger.w(_format(message, tag), error: error);

  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _logger.e(_format(message, tag), error: error, stackTrace: stackTrace);

  static String _format(String message, String? tag) =>
      tag != null ? '[$tag] $message' : message;
}
