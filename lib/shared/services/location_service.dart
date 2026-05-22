import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../config/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/gps_utils.dart';
import '../../core/utils/logger.dart';

class LocationService {
  static const _tag = 'LocationService';

  StreamSubscription<Position>? _positionSubscription;
  final _positionController = StreamController<Position>.broadcast();

  /// Broadcast stream of position updates. BLoCs subscribe here after calling
  /// [startTracking] or [startTrackingForHunt].
  Stream<Position> get positionStream => _positionController.stream;

  // ── Permissions ─────────────────────────────────────────────────────────────

  /// Request location permission. Returns true when granted.
  ///
  /// Handles all edge cases:
  /// - GPS disabled → prompts the user to open location settings.
  /// - Permission denied → triggers the OS rationale dialog.
  /// - Permanently denied → opens app settings so the user can grant manually.
  Future<bool> requestPermission() async {
    // 1. Check if the device location service is on at all.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.w('Location services are disabled', tag: _tag);
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    // 2. Ask for permission if not yet decided.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 3. Permanently denied → must navigate to app settings.
    if (permission == LocationPermission.deniedForever) {
      AppLogger.w('Location permission permanently denied', tag: _tag);
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ── Single-shot position ─────────────────────────────────────────────────────

  /// Returns the current GPS position wrapped in [Result].
  ///
  /// Logs a warning when accuracy exceeds [AppConstants.minimumGpsAccuracy]
  /// but still returns the position so the UI can decide how to handle it.
  Future<Result<Position>> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      return const Err(LocationFailure('Location permission denied.'));
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _warnIfPoorAccuracy(position);
      return Success(position);
    } catch (e) {
      AppLogger.e('getCurrentPosition failed', tag: _tag, error: e);
      return const Err(LocationFailure('Failed to get current position.'));
    }
  }

  // ── Continuous tracking ──────────────────────────────────────────────────────

  /// Start a continuous position stream optimised for active-hunt navigation.
  ///
  /// Uses medium accuracy and a 5-second update interval to balance navigation
  /// precision against battery drain in garden environments. Emits positions
  /// on [positionStream]; also returns the same broadcast stream for callers
  /// that prefer the fluent `.listen()` pattern.
  ///
  /// Poor-accuracy positions are emitted but a warning is logged so the UI
  /// can optionally surface a "weak GPS signal" notice.
  Stream<Position> startTrackingForHunt() {
    _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _huntLocationSettings(),
    ).listen(
      (position) {
        _warnIfPoorAccuracy(position);
        _positionController.add(position);
      },
      onError: (Object e) =>
          AppLogger.e('Hunt position stream error', tag: _tag, error: e),
    );

    AppLogger.d('Hunt location tracking started', tag: _tag);
    return _positionController.stream;
  }

  /// Legacy helper kept for backward compatibility. Delegates to
  /// [startTrackingForHunt] so all tracking goes through one code path.
  Future<void> startTracking() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      AppLogger.w('Cannot start tracking — permission denied', tag: _tag);
      return;
    }
    startTrackingForHunt();
  }

  /// Stop all active position subscriptions.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    AppLogger.d('Location tracking stopped', tag: _tag);
  }

  // ── Proximity check ──────────────────────────────────────────────────────────

  /// Returns true if the current device position is within [radiusMeters] of
  /// ([targetLat], [targetLng]). Uses [GpsUtils.distanceInMetres] (Haversine).
  ///
  /// Returns false on any error (permission denied, GPS unavailable) so the
  /// caller can treat an unknown location as "not yet there".
  Future<bool> isWithinRadius(
    double targetLat,
    double targetLng,
    int radiusMeters,
  ) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GpsUtils.isWithinRadius(
        userLat: position.latitude,
        userLng: position.longitude,
        targetLat: targetLat,
        targetLng: targetLng,
        radiusMetres: radiusMeters.toDouble(),
      );
    } catch (e) {
      AppLogger.e('isWithinRadius failed', tag: _tag, error: e);
      return false;
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  void dispose() {
    stopTracking();
    _positionController.close();
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Platform-appropriate [LocationSettings] for active hunt tracking.
  ///
  /// Android: requests updates every 5 s and only when the device moves
  /// [AppConstants.locationDistanceFilter] metres (saves battery).
  /// iOS / macOS: medium accuracy with no automatic pause.
  /// Other: generic medium accuracy fallback.
  LocationSettings _huntLocationSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.medium,
          intervalDuration: const Duration(seconds: 5),
          distanceFilter: AppConstants.locationDistanceFilter.toInt(),
          forceLocationManager: false,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: AppConstants.locationDistanceFilter.toInt(),
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: false,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
        );
    }
  }

  void _warnIfPoorAccuracy(Position position) {
    if (position.accuracy > AppConstants.minimumGpsAccuracy) {
      AppLogger.w(
        'Poor GPS accuracy: ${position.accuracy.toStringAsFixed(0)} m '
        '(threshold: ${AppConstants.minimumGpsAccuracy} m)',
        tag: _tag,
      );
    }
  }
}
