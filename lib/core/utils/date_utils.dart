import 'package:intl/intl.dart';

abstract final class HMDateUtils {
  static final _timeFormatter = DateFormat('HH:mm');
  static final _shortDateFormatter = DateFormat('d MMM yyyy');
  static final _fullDateFormatter = DateFormat('EEEE, d MMMM yyyy');

  /// "14:35"
  static String toTime(DateTime dt) => _timeFormatter.format(dt);

  /// "5 Apr 2025"
  static String toShortDate(DateTime dt) => _shortDateFormatter.format(dt);

  /// "Saturday, 5 April 2025"
  static String toFullDate(DateTime dt) => _fullDateFormatter.format(dt);

  /// "2h 34m" or "45m 12s" style elapsed time from seconds.
  static String formatElapsedSeconds(int totalSeconds) {
    final secs = totalSeconds.abs();
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;

    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  /// Human-readable "X ago" / "just now" / "in Xm" for future dates.
  ///
  /// Pass [now] to override the reference time (useful for deterministic tests).
  static String timeAgo(DateTime dt, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(dt);
    final abs = diff.abs();

    if (abs.inSeconds < 60) return 'just now';

    final past = !diff.isNegative;
    final suffix = past ? ' ago' : ' left';

    if (abs.inMinutes < 60) return '${abs.inMinutes}m$suffix';
    if (abs.inHours < 24) return '${abs.inHours}h$suffix';
    if (abs.inDays < 7) return '${abs.inDays}d$suffix';
    return toShortDate(dt);
  }
}
