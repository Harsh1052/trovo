import 'dart:math' as math;

/// Utility helpers for GPS calculations.
abstract final class GpsUtils {
  static const double _earthRadiusMetres = 6371000.0;

  /// Haversine distance in metres between two lat/lng points.
  static double distanceInMetres(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMetres * c;
  }

  /// Returns true if the user is within [radiusMetres] of the target.
  static bool isWithinRadius({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
    required double radiusMetres,
  }) {
    final distance = distanceInMetres(userLat, userLng, targetLat, targetLng);
    return distance <= radiusMetres;
  }

  /// Formats a distance for display: "12 m" or "1.4 km".
  static String formatDistance(double metres) {
    if (metres < 1000) {
      return '${metres.round()} m';
    }
    final km = metres / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Bearing in degrees (0–360) from point 1 to point 2.
  static double bearingDegrees(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLng = _toRadians(lng2 - lng1);
    final rLat1 = _toRadians(lat1);
    final rLat2 = _toRadians(lat2);

    final y = math.sin(dLng) * math.cos(rLat2);
    final x = math.cos(rLat1) * math.sin(rLat2) -
        math.sin(rLat1) * math.cos(rLat2) * math.cos(dLng);

    final bearing = math.atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
  static double _toDegrees(double radians) => radians * 180 / math.pi;
}
