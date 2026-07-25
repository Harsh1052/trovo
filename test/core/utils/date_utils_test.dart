import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/utils/date_utils.dart';

void main() {
  group('HMDateUtils', () {
    // ── toTime ────────────────────────────────────────────────────────────────

    group('toTime', () {
      test('formats midnight as 00:00', () {
        final dt = DateTime(2025, 1, 1, 0, 0);
        expect(HMDateUtils.toTime(dt), '00:00');
      });

      test('formats noon as 12:00', () {
        final dt = DateTime(2025, 6, 15, 12, 0);
        expect(HMDateUtils.toTime(dt), '12:00');
      });

      test('formats 23:59 correctly', () {
        final dt = DateTime(2025, 12, 31, 23, 59);
        expect(HMDateUtils.toTime(dt), '23:59');
      });

      test('zero-pads single-digit hour and minute', () {
        final dt = DateTime(2025, 3, 10, 9, 5);
        expect(HMDateUtils.toTime(dt), '09:05');
      });
    });

    // ── toShortDate ───────────────────────────────────────────────────────────

    group('toShortDate', () {
      test('formats 5 April 2025 correctly', () {
        final dt = DateTime(2025, 4, 5);
        expect(HMDateUtils.toShortDate(dt), '5 Apr 2025');
      });

      test('formats 1 January 2000 correctly', () {
        final dt = DateTime(2000, 1, 1);
        expect(HMDateUtils.toShortDate(dt), '1 Jan 2000');
      });

      test('formats 31 December 2099 correctly', () {
        final dt = DateTime(2099, 12, 31);
        expect(HMDateUtils.toShortDate(dt), '31 Dec 2099');
      });
    });

    // ── toFullDate ────────────────────────────────────────────────────────────

    group('toFullDate', () {
      test('formats Saturday 5 April 2025 correctly', () {
        // April 5, 2025 is a Saturday
        final dt = DateTime(2025, 4, 5);
        expect(HMDateUtils.toFullDate(dt), 'Saturday, 5 April 2025');
      });

      test('formats Monday correctly', () {
        // May 19, 2025 is a Monday
        final dt = DateTime(2025, 5, 19);
        expect(HMDateUtils.toFullDate(dt), 'Monday, 19 May 2025');
      });
    });

    // ── formatElapsedSeconds ──────────────────────────────────────────────────

    group('formatElapsedSeconds', () {
      test('formats 0 seconds as "0s"', () {
        expect(HMDateUtils.formatElapsedSeconds(0), '0s');
      });

      test('formats 59 seconds correctly', () {
        expect(HMDateUtils.formatElapsedSeconds(59), '59s');
      });

      test('formats exactly 60 seconds as "1m 0s"', () {
        expect(HMDateUtils.formatElapsedSeconds(60), '1m 0s');
      });

      test('formats 90 seconds as "1m 30s"', () {
        expect(HMDateUtils.formatElapsedSeconds(90), '1m 30s');
      });

      test('formats exactly 1 hour as "1h 0m"', () {
        expect(HMDateUtils.formatElapsedSeconds(3600), '1h 0m');
      });

      test('formats 2h 34m correctly', () {
        expect(HMDateUtils.formatElapsedSeconds(9240), '2h 34m');
      });

      test('handles negative seconds by using absolute value', () {
        // -90 seconds should format the same as 90
        expect(HMDateUtils.formatElapsedSeconds(-90), '1m 30s');
      });
    });

    // ── timeAgo ───────────────────────────────────────────────────────────────

    group('timeAgo', () {
      final referenceNow = DateTime(2025, 6, 15, 12, 0, 0);

      test('returns "just now" for timestamps within 60 seconds ago', () {
        final dt = referenceNow.subtract(const Duration(seconds: 30));
        expect(HMDateUtils.timeAgo(dt, now: referenceNow), 'just now');
      });

      test('returns "just now" for exactly 0 seconds ago', () {
        expect(HMDateUtils.timeAgo(referenceNow, now: referenceNow), 'just now');
      });

      test('returns minutes ago for timestamps 2–59 minutes ago', () {
        final dt = referenceNow.subtract(const Duration(minutes: 5));
        expect(HMDateUtils.timeAgo(dt, now: referenceNow), '5m ago');
      });

      test('returns hours ago for timestamps 1–23 hours ago', () {
        final dt = referenceNow.subtract(const Duration(hours: 3));
        expect(HMDateUtils.timeAgo(dt, now: referenceNow), '3h ago');
      });

      test('returns days ago for timestamps 1–6 days ago', () {
        final dt = referenceNow.subtract(const Duration(days: 2));
        expect(HMDateUtils.timeAgo(dt, now: referenceNow), '2d ago');
      });

      test('returns short date for timestamps older than 7 days', () {
        final dt = DateTime(2025, 1, 1);
        final result = HMDateUtils.timeAgo(dt, now: referenceNow);
        expect(result, HMDateUtils.toShortDate(dt));
      });

      test('returns "X left" suffix for future timestamps within 60 min', () {
        final dt = referenceNow.add(const Duration(minutes: 10));
        expect(HMDateUtils.timeAgo(dt, now: referenceNow), '10m left');
      });

      test('returns "X left" for future timestamps within 24 h', () {
        final dt = referenceNow.add(const Duration(hours: 2));
        expect(HMDateUtils.timeAgo(dt, now: referenceNow), '2h left');
      });
    });
  });
}
