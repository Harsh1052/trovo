import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/utils/gps_utils.dart';

void main() {
  group('GpsUtils', () {
    // ── distanceInMetres ──────────────────────────────────────────────────────

    group('distanceInMetres', () {
      test('returns 0 for identical coordinates', () {
        final dist = GpsUtils.distanceInMetres(12.9716, 77.5946, 12.9716, 77.5946);
        expect(dist, closeTo(0.0, 0.001));
      });

      test('calculates distance between two known points (Bengaluru to Chennai ~290 km)', () {
        // Bengaluru: 12.9716, 77.5946 | Chennai: 13.0827, 80.2707
        final dist = GpsUtils.distanceInMetres(12.9716, 77.5946, 13.0827, 80.2707);
        // Real-world distance is approximately 290 000 m; allow ±5 km tolerance
        expect(dist, inInclusiveRange(285000.0, 295000.0));
      });

      test('is symmetric — A→B equals B→A', () {
        final ab = GpsUtils.distanceInMetres(19.076, 72.877, 28.613, 77.209);
        final ba = GpsUtils.distanceInMetres(28.613, 77.209, 19.076, 72.877);
        expect(ab, closeTo(ba, 0.001));
      });

      test('is positive for non-identical coordinates', () {
        final dist = GpsUtils.distanceInMetres(0.0, 0.0, 1.0, 1.0);
        expect(dist, greaterThan(0));
      });
    });

    // ── isWithinRadius ────────────────────────────────────────────────────────

    group('isWithinRadius', () {
      const targetLat = 12.9716;
      const targetLng = 77.5946;

      test('returns true when user is exactly on the target', () {
        expect(
          GpsUtils.isWithinRadius(
            userLat: targetLat,
            userLng: targetLng,
            targetLat: targetLat,
            targetLng: targetLng,
            radiusMetres: 20,
          ),
          isTrue,
        );
      });

      test('returns true when user is within radius', () {
        // Offset by ~10 m north (roughly 0.00009 degrees)
        expect(
          GpsUtils.isWithinRadius(
            userLat: targetLat + 0.00009,
            userLng: targetLng,
            targetLat: targetLat,
            targetLng: targetLng,
            radiusMetres: 20,
          ),
          isTrue,
        );
      });

      test('returns false when user is well outside radius', () {
        expect(
          GpsUtils.isWithinRadius(
            userLat: targetLat + 1.0, // ~111 km north
            userLng: targetLng,
            targetLat: targetLat,
            targetLng: targetLng,
            radiusMetres: 20,
          ),
          isFalse,
        );
      });

      test('returns false when distance equals radius plus 1 m', () {
        // User is ~21 m north; radius is 20 m
        expect(
          GpsUtils.isWithinRadius(
            userLat: targetLat + 0.000189, // ≈ 21 m
            userLng: targetLng,
            targetLat: targetLat,
            targetLng: targetLng,
            radiusMetres: 20,
          ),
          isFalse,
        );
      });
    });

    // ── formatDistance ────────────────────────────────────────────────────────

    group('formatDistance', () {
      test('formats values below 1000 m as metres', () {
        expect(GpsUtils.formatDistance(0), '0 m');
        expect(GpsUtils.formatDistance(500), '500 m');
        expect(GpsUtils.formatDistance(999), '999 m');
      });

      test('formats exactly 1000 m as km', () {
        expect(GpsUtils.formatDistance(1000), '1.0 km');
      });

      test('formats values above 1000 m with one decimal km', () {
        expect(GpsUtils.formatDistance(1500), '1.5 km');
        expect(GpsUtils.formatDistance(10000), '10.0 km');
        expect(GpsUtils.formatDistance(2340), '2.3 km');
      });

      test('rounds metres correctly', () {
        expect(GpsUtils.formatDistance(999.6), '1000 m');
        expect(GpsUtils.formatDistance(999.4), '999 m');
      });
    });

    // ── bearingDegrees ────────────────────────────────────────────────────────

    group('bearingDegrees', () {
      test('bearing from equator pointing due north is ~0°', () {
        final bearing = GpsUtils.bearingDegrees(0, 0, 1, 0);
        expect(bearing, closeTo(0.0, 0.5));
      });

      test('bearing pointing due east is ~90°', () {
        final bearing = GpsUtils.bearingDegrees(0, 0, 0, 1);
        expect(bearing, closeTo(90.0, 0.5));
      });

      test('bearing pointing due south is ~180°', () {
        final bearing = GpsUtils.bearingDegrees(1, 0, 0, 0);
        expect(bearing, closeTo(180.0, 0.5));
      });

      test('bearing pointing due west is ~270°', () {
        final bearing = GpsUtils.bearingDegrees(0, 1, 0, 0);
        expect(bearing, closeTo(270.0, 0.5));
      });

      test('returns value in [0, 360) range', () {
        const coords = [
          [12.9716, 77.5946, 28.6139, 77.2090],
          [28.6139, 77.2090, 12.9716, 77.5946],
          [19.0760, 72.8777, 13.0827, 80.2707],
        ];
        for (final c in coords) {
          final bearing = GpsUtils.bearingDegrees(c[0], c[1], c[2], c[3]);
          expect(bearing, inInclusiveRange(0.0, 360.0),
              reason: 'bearing should be in [0, 360) for coords $c');
        }
      });
    });
  });
}
