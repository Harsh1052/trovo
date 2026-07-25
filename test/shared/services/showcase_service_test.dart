import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/shared/services/showcase_service.dart';

void main() {
  group('ShowcaseService', () {
    late ShowcaseService service;

    setUp(() {
      service = ShowcaseService.testInstance();
    });

    test('shouldShowShowcase returns true when feature has not been seen', () async {
      final shouldShow = await service.shouldShowShowcase(ShowcaseService.featureRadarHud);
      expect(shouldShow, isTrue);
    });

    test('markShowcaseCompleted updates flag so shouldShowShowcase returns false', () async {
      await service.markShowcaseCompleted(ShowcaseService.featureRadarHud);

      final shouldShow = await service.shouldShowShowcase(ShowcaseService.featureRadarHud);
      expect(shouldShow, isFalse);
    });

    test('resetAllShowcases clears all completed flags', () async {
      await service.markShowcaseCompleted(ShowcaseService.featureOfflineSync);
      await service.resetAllShowcases();

      final shouldShow = await service.shouldShowShowcase(ShowcaseService.featureOfflineSync);
      expect(shouldShow, isTrue);
    });
  });
}
