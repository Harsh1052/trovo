import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/logger.dart';

/// Service managing Push Notifications (FCM) & Local Geofence Alerts.
class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging,
        _localNotifications = localNotifications;

  /// Test-only constructor with in-memory logging bypass.
  NotificationService.testInstance({
    List<Map<String, String>>? sentLog,
  })  : _messaging = null,
        _localNotifications = null,
        _sentLog = sentLog ?? [];

  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin? _localNotifications;
  List<Map<String, String>>? _sentLog;

  static const String channelIdAlerts = 'huntermania_alerts';
  static const String channelIdGeofence = 'huntermania_geofence';

  /// Initializes FCM and local notification channels.
  Future<void> init() async {
    if (_sentLog != null && _messaging == null) return;

    try {
      final messaging = _messaging ?? FirebaseMessaging.instance;
      final local = _localNotifications ?? FlutterLocalNotificationsPlugin();

      // Request notification permissions
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Configure Android local notification channels
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await local.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      // Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          showLocalNotification(
            title: notification.title ?? 'HunterMania Alert',
            body: notification.body ?? '',
          );
        }
      });

      AppLogger.i('NotificationService initialized successfully',
          tag: 'Notification');
    } catch (e) {
      AppLogger.w('Failed to initialize NotificationService: $e',
          tag: 'Notification');
    }
  }

  /// Displays a local notification in the status bar.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String channelId = channelIdAlerts,
  }) async {
    if (_sentLog != null) {
      _sentLog!.add({'title': title, 'body': body, 'channelId': channelId});
      return;
    }

    try {
      final local = _localNotifications ?? FlutterLocalNotificationsPlugin();
      final androidDetails = AndroidNotificationDetails(
        channelId,
        'HunterMania Notifications',
        channelDescription: 'Alerts and geofence proximity triggers',
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();

      await local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      AppLogger.w('Failed to show local notification: $e', tag: 'Notification');
    }
  }

  /// Triggers a local geofence alert when user is near a hidden checkpoint.
  Future<void> triggerProximityGeofenceAlert({
    required String checkpointTitle,
    required double distanceMetres,
  }) async {
    final title = 'Treasure Nearby! 📍';
    final body =
        'You are only ${distanceMetres.round()}m away from "$checkpointTitle"! Tap to open radar.';
    await showLocalNotification(
      title: title,
      body: body,
      channelId: channelIdGeofence,
    );
  }

  /// Inspects sent notification log for unit testing.
  List<Map<String, String>> get sentLog => _sentLog ?? [];
}
