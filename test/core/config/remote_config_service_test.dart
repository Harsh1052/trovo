import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/config/remote_config_service.dart';

void main() {
  group('RemoteConfigService', () {
    test('returns default values when initialized without overrides', () {
      final service = RemoteConfigService.testInstance();

      expect(service.isRadarHudEnabled, isTrue);
      expect(service.isOfflineCacheEnabled, isTrue);
      expect(service.minRequiredAppVersion, '1.0.0');
      expect(service.paywallDiscountPercentage, 0);
      expect(service.isKillSwitchActive, isFalse);
    });

    test('respects OTA feature flag overrides', () {
      final service = RemoteConfigService.testInstance(
        mockValues: {
          'is_radar_hud_enabled': false,
          'is_offline_cache_enabled': true,
          'min_required_app_version': '1.2.0',
          'paywall_discount_percentage': 25,
          'emergency_kill_switch': true,
        },
      );

      expect(service.isRadarHudEnabled, isFalse);
      expect(service.isOfflineCacheEnabled, isTrue);
      expect(service.minRequiredAppVersion, '1.2.0');
      expect(service.paywallDiscountPercentage, 25);
      expect(service.isKillSwitchActive, isTrue);
    });
  });
}
