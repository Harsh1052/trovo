import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/core/error/crashlytics_observer.dart';

void main() {
  group('CrashlyticsObserver', () {
    late CrashlyticsObserver observer;

    setUp(() {
      observer = CrashlyticsObserver.testInstance();
    });

    test('logs non-fatal errors in test mode', () async {
      await observer.recordNonFatalError(
        StateError('Test State Error'),
        reason: 'Simulated API Timeout',
      );

      expect(observer.errorLog.length, 1);
      expect(observer.errorLog.first['exception'], contains('Test State Error'));
      expect(observer.errorLog.first['reason'], 'Simulated API Timeout');
      expect(observer.errorLog.first['fatal'], isFalse);
    });

    test('sets custom diagnostic keys correctly', () async {
      await observer.setCustomKey('active_hunt_id', 'cubbon_park_emerald');

      expect(observer.errorLog.length, 1);
      expect(observer.errorLog.first['custom_key'], 'active_hunt_id');
      expect(observer.errorLog.first['value'], 'cubbon_park_emerald');
    });
  });
}
