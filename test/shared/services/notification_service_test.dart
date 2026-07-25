import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/shared/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.testInstance();
    });

    test('logs local notifications correctly in test mode', () async {
      await service.showLocalNotification(
        title: 'New Hunt Unlocked',
        body: 'Cubbon Park Emerald is now live!',
      );

      expect(service.sentLog.length, 1);
      expect(service.sentLog.first['title'], 'New Hunt Unlocked');
      expect(service.sentLog.first['body'], 'Cubbon Park Emerald is now live!');
    });

    test('triggers proximity geofence alerts with correct formatted distance', () async {
      await service.triggerProximityGeofenceAlert(
        checkpointTitle: 'Panchvati Banyan Tree',
        distanceMetres: 24.6,
      );

      expect(service.sentLog.length, 1);
      expect(service.sentLog.first['title'], 'Treasure Nearby! 📍');
      expect(
        service.sentLog.first['body'],
        contains('You are only 25m away from "Panchvati Banyan Tree"!'),
      );
      expect(service.sentLog.first['channelId'], NotificationService.channelIdGeofence);
    });
  });
}
