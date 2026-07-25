import 'gps_utils.dart';

enum ProximityZone {
  /// User is > 100m away from checkpoint.
  cold,

  /// User is 30m–100m away.
  warm,

  /// User is within 30m up to unlockRadius.
  hot,

  /// User is within unlock radius (can unlock checkpoint).
  unlocked;

  String get label => switch (this) {
        ProximityZone.cold => 'Freezing Cold',
        ProximityZone.warm => 'Getting Warmer',
        ProximityZone.hot => 'Sizzling Hot!',
        ProximityZone.unlocked => 'Target Reached!',
      };

  /// Pulse animation / haptic rate interval in milliseconds.
  int get pulseIntervalMs => switch (this) {
        ProximityZone.cold => 1600,
        ProximityZone.warm => 800,
        ProximityZone.hot => 350,
        ProximityZone.unlocked => 150,
      };
}

class ProximityFeedback {
  const ProximityFeedback({
    required this.zone,
    required this.distanceMetres,
    required this.targetBearingDegrees,
    required this.relativeHeadingOffset,
  });

  final ProximityZone zone;
  final double distanceMetres;

  /// Absolute geographical bearing to target (0°–360°).
  final double targetBearingDegrees;

  /// Heading offset relative to device compass orientation (-180° to +180°).
  final double relativeHeadingOffset;

  String get formattedDistance => GpsUtils.formatDistance(distanceMetres);
}

abstract final class ProximityCalculator {
  /// Evaluates user GPS coordinates against target checkpoint.
  static ProximityFeedback calculate({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
    required double unlockRadiusMetres,
    double deviceHeadingDegrees = 0.0,
  }) {
    final distance =
        GpsUtils.distanceInMetres(userLat, userLng, targetLat, targetLng);

    final zone = switch (distance) {
      _ when distance <= unlockRadiusMetres => ProximityZone.unlocked,
      _ when distance <= 30.0 => ProximityZone.hot,
      _ when distance <= 100.0 => ProximityZone.warm,
      _ => ProximityZone.cold,
    };

    final targetBearing =
        GpsUtils.bearingDegrees(userLat, userLng, targetLat, targetLng);

    // Calculate relative heading offset (-180° to 180°).
    double offset = (targetBearing - deviceHeadingDegrees) % 360;
    if (offset > 180) offset -= 360;
    if (offset < -180) offset += 360;

    return ProximityFeedback(
      zone: zone,
      distanceMetres: distance,
      targetBearingDegrees: targetBearing,
      relativeHeadingOffset: offset,
    );
  }
}
