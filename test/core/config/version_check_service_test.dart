import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/config/remote_config_service.dart';
import 'package:huntermania/core/config/version_check_service.dart';

void main() {
  group('VersionCheckService', () {
    test('returns upToDate when current version equals min required', () async {
      final remoteConfig = RemoteConfigService.testInstance(
        mockValues: {'min_required_app_version': '1.0.0'},
      );
      final service = VersionCheckService.testInstance(
        remoteConfig: remoteConfig,
        mockInstalledVersion: '1.0.0',
      );

      final status = await service.checkVersionStatus();
      expect(status, VersionStatus.upToDate);
    });

    test('returns forceUpdateRequired when current version is older than min required', () async {
      final remoteConfig = RemoteConfigService.testInstance(
        mockValues: {'min_required_app_version': '1.2.0'},
      );
      final service = VersionCheckService.testInstance(
        remoteConfig: remoteConfig,
        mockInstalledVersion: '1.0.5',
      );

      final status = await service.checkVersionStatus();
      expect(status, VersionStatus.forceUpdateRequired);
    });

    test('returns upToDate when current version is newer than min required', () async {
      final remoteConfig = RemoteConfigService.testInstance(
        mockValues: {'min_required_app_version': '1.0.0'},
      );
      final service = VersionCheckService.testInstance(
        remoteConfig: remoteConfig,
        mockInstalledVersion: '2.0.0',
      );

      final status = await service.checkVersionStatus();
      expect(status, VersionStatus.upToDate);
    });
  });
}
