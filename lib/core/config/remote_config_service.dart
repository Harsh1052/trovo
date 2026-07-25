import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/logger.dart';

/// Manages Over-The-Air (OTA) feature flags, dynamic config, and emergency
/// rollbacks via Firebase Remote Config.
class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig;

  /// Test-only constructor with static values bypass.
  RemoteConfigService.testInstance({
    Map<String, dynamic>? mockValues,
  })  : _remoteConfig = null,
        _mockValues = mockValues ?? {};

  final FirebaseRemoteConfig? _remoteConfig;
  Map<String, dynamic>? _mockValues;

  static const String _keyRadarHudEnabled = 'is_radar_hud_enabled';
  static const String _keyOfflineCacheEnabled = 'is_offline_cache_enabled';
  static const String _keyMinRequiredVersion = 'min_required_app_version';
  static const String _keyPaywallDiscount = 'paywall_discount_percentage';
  static const String _keyKillSwitch = 'emergency_kill_switch';

  /// Default fallback values when offline or before remote fetch.
  static const Map<String, dynamic> _defaults = {
    _keyRadarHudEnabled: true,
    _keyOfflineCacheEnabled: true,
    _keyMinRequiredVersion: '1.0.0',
    _keyPaywallDiscount: 0,
    _keyKillSwitch: false,
  };

  /// Initializes Remote Config and fetches latest values OTA.
  Future<void> init() async {
    if (_mockValues != null) return;
    try {
      final config = _remoteConfig ?? FirebaseRemoteConfig.instance;
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await config.setDefaults(_defaults);
      await config.fetchAndActivate();
      AppLogger.i('Remote Config fetched and activated successfully',
          tag: 'RemoteConfig');
    } catch (e) {
      AppLogger.w('Failed to fetch Remote Config, using defaults: $e',
          tag: 'RemoteConfig');
    }
  }

  /// Whether the Live Hot & Cold Radar HUD feature is enabled OTA.
  bool get isRadarHudEnabled {
    if (_mockValues != null) {
      return _mockValues![_keyRadarHudEnabled] as bool? ?? true;
    }
    return _remoteConfig?.getBool(_keyRadarHudEnabled) ?? true;
  }

  /// Whether the Offline Hunt Cache feature is enabled OTA.
  bool get isOfflineCacheEnabled {
    if (_mockValues != null) {
      return _mockValues![_keyOfflineCacheEnabled] as bool? ?? true;
    }
    return _remoteConfig?.getBool(_keyOfflineCacheEnabled) ?? true;
  }

  /// Minimum required app version string (e.g. "1.0.0").
  String get minRequiredAppVersion {
    if (_mockValues != null) {
      return _mockValues![_keyMinRequiredVersion] as String? ?? '1.0.0';
    }
    return _remoteConfig?.getString(_keyMinRequiredVersion) ?? '1.0.0';
  }

  /// Active paywall discount percentage (0–100).
  int get paywallDiscountPercentage {
    if (_mockValues != null) {
      return _mockValues![_keyPaywallDiscount] as int? ?? 0;
    }
    return _remoteConfig?.getInt(_keyPaywallDiscount) ?? 0;
  }

  /// Emergency kill switch flag to disable all non-essential remote operations.
  bool get isKillSwitchActive {
    if (_mockValues != null) {
      return _mockValues![_keyKillSwitch] as bool? ?? false;
    }
    return _remoteConfig?.getBool(_keyKillSwitch) ?? false;
  }
}
