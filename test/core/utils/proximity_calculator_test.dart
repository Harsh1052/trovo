import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/utils/proximity_calculator.dart';

void main() {
  group('ProximityCalculator', () {
    const userLat = 12.9716;
    const userLng = 77.5946;

    test('returns unlocked zone when user is within unlock radius', () {
      final feedback = ProximityCalculator.calculate(
        userLat: userLat,
        userLng: userLng,
        targetLat: userLat, // 0m distance
        targetLng: userLng,
        unlockRadiusMetres: 20.0,
      );

      expect(feedback.zone, ProximityZone.unlocked);
      expect(feedback.distanceMetres, 0.0);
      expect(feedback.zone.label, 'Target Reached!');
    });

    test('returns hot zone when distance is <= 30m but above unlock radius', () {
      // 0.0001 deg lat is ~11 meters
      final feedback = ProximityCalculator.calculate(
        userLat: userLat,
        userLng: userLng,
        targetLat: userLat + 0.0002, // ~22 meters
        targetLng: userLng,
        unlockRadiusMetres: 10.0,
      );

      expect(feedback.zone, ProximityZone.hot);
      expect(feedback.zone.pulseIntervalMs, 350);
      expect(feedback.zone.label, 'Sizzling Hot!');
    });

    test('returns warm zone when distance is between 30m and 100m', () {
      // 0.0005 deg lat is ~55 meters
      final feedback = ProximityCalculator.calculate(
        userLat: userLat,
        userLng: userLng,
        targetLat: userLat + 0.0005,
        targetLng: userLng,
        unlockRadiusMetres: 20.0,
      );

      expect(feedback.zone, ProximityZone.warm);
      expect(feedback.zone.pulseIntervalMs, 800);
      expect(feedback.zone.label, 'Getting Warmer');
    });

    test('returns cold zone when distance is > 100m', () {
      // 0.002 deg lat is ~220 meters
      final feedback = ProximityCalculator.calculate(
        userLat: userLat,
        userLng: userLng,
        targetLat: userLat + 0.002,
        targetLng: userLng,
        unlockRadiusMetres: 20.0,
      );

      expect(feedback.zone, ProximityZone.cold);
      expect(feedback.zone.pulseIntervalMs, 1600);
      expect(feedback.zone.label, 'Freezing Cold');
    });

    test('calculates relative heading offset correctly', () {
      final feedback = ProximityCalculator.calculate(
        userLat: userLat,
        userLng: userLng,
        targetLat: userLat + 0.001, // Due North (0°)
        targetLng: userLng,
        unlockRadiusMetres: 20.0,
        deviceHeadingDegrees: 90.0, // Facing East (90°)
      );

      // Target is North (0°), Device is East (90°) -> Offset should be -90°
      expect(feedback.relativeHeadingOffset, closeTo(-90.0, 1.0));
    });
  });
}
