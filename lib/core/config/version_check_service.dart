import 'package:package_info_plus/package_info_plus.dart';
import 'remote_config_service.dart';
import '../utils/logger.dart';

enum VersionStatus {
  upToDate,
  optionalUpdateAvailable,
  forceUpdateRequired,
}

/// Service managing in-app version enforcement & force update prompts.
class VersionCheckService {
  VersionCheckService({
    RemoteConfigService? remoteConfig,
    PackageInfo? packageInfo,
  })  : _remoteConfig = remoteConfig,
        _packageInfo = packageInfo;

  /// Test-only constructor with mock version overrides.
  VersionCheckService.testInstance({
    required RemoteConfigService remoteConfig,
    required String mockInstalledVersion,
  })  : _remoteConfig = remoteConfig,
        _packageInfo = null,
        _mockInstalledVersion = mockInstalledVersion;

  final RemoteConfigService? _remoteConfig;
  final PackageInfo? _packageInfo;
  String? _mockInstalledVersion;

  /// Returns the current installed app version string (e.g. "1.0.0").
  Future<String> getInstalledVersion() async {
    if (_mockInstalledVersion != null) return _mockInstalledVersion!;
    try {
      final info = _packageInfo ?? await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      AppLogger.w('Failed to read package info: $e', tag: 'VersionCheck');
      return '1.0.0';
    }
  }

  /// Checks installed version against Remote Config `minRequiredAppVersion`.
  Future<VersionStatus> checkVersionStatus() async {
    final current = await getInstalledVersion();
    final minRequired =
        _remoteConfig?.minRequiredAppVersion ?? '1.0.0';

    AppLogger.i('Version check: current=$current, minRequired=$minRequired',
        tag: 'VersionCheck');

    if (_isVersionOlder(current, minRequired)) {
      return VersionStatus.forceUpdateRequired;
    }

    return VersionStatus.upToDate;
  }

  /// Compares two semver strings (e.g. "1.0.0" vs "1.2.0").
  /// Returns true if [v1] is strictly older than [v2].
  static bool _isVersionOlder(String v1, String v2) {
    try {
      final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (var i = 0; i < 3; i++) {
        final num1 = i < p1.length ? p1[i] : 0;
        final num2 = i < p2.length ? p2[i] : 0;

        if (num1 < num2) return true;
        if (num1 > num2) return false;
      }
    } catch (e) {
      AppLogger.w('Failed to parse semver: $e', tag: 'VersionCheck');
    }
    return false;
  }
}
