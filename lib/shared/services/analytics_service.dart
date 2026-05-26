import 'package:firebase_analytics/firebase_analytics.dart';

import '../../config/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// Thin wrapper over [FirebaseAnalytics].
///
/// All feature code calls this service — never [FirebaseAnalytics] directly.
/// Swapping providers later only requires editing this single class.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;
  static const _tag = 'Analytics';

  // ── Generic entry-point ───────────────────────────────────────────────────

  /// Log any custom event. Prefer the typed helpers below for events that have
  /// a fixed schema — they enforce parameter names at compile time.
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? params,
  }) =>
      _log(
        name,
        params?.map((k, v) => MapEntry(k, v as Object)),
      );

  // ── Hunt lifecycle ────────────────────────────────────────────────────────

  Future<void> logHuntStarted(String huntId, String huntTitle) =>
      _log(AppConstants.eventHuntStarted, {
        'hunt_id': huntId,
        'hunt_title': huntTitle,
      });

  Future<void> logHuntCompleted({
    required String huntId,
    required int elapsedSeconds,
    required int hintsUsed,
  }) =>
      _log(AppConstants.eventHuntCompleted, {
        'hunt_id': huntId,
        'elapsed_seconds': elapsedSeconds,
        'hints_used': hintsUsed,
      });

  Future<void> logHuntAbandoned({
    required String huntId,
    required int checkpointIndex,
    required int elapsedSeconds,
  }) =>
      _log(AppConstants.eventHuntAbandoned, {
        'hunt_id': huntId,
        'checkpoint_index': checkpointIndex,
        'elapsed_seconds': elapsedSeconds,
      });

  // ── Checkpoint ────────────────────────────────────────────────────────────

  /// Log that a checkpoint was *reached* (player arrived at GPS location).
  Future<void> logCheckpointReached({
    required String huntId,
    required int checkpointIndex,
  }) =>
      _log(AppConstants.eventCheckpointReached, {
        'hunt_id': huntId,
        'checkpoint_index': checkpointIndex,
      });

  /// Log that a checkpoint was *unlocked* (correct answer / photo submitted).
  Future<void> logCheckpointUnlocked({
    required String huntId,
    required int checkpointIndex,
  }) =>
      _log(AppConstants.eventCheckpointUnlocked, {
        'hunt_id': huntId,
        'checkpoint_index': checkpointIndex,
      });

  // ── Hints ─────────────────────────────────────────────────────────────────

  Future<void> logHintUsed(String huntId, int checkpointIndex) =>
      _log(AppConstants.eventHintUsed, {
        'hunt_id': huntId,
        'checkpoint_index': checkpointIndex,
      });

  // ── Purchases ─────────────────────────────────────────────────────────────

  Future<void> logPurchaseStarted(String productId) =>
      _log(AppConstants.eventPurchaseStarted, {'product_id': productId});

  Future<void> logPurchaseCompleted(String productId) =>
      _log(AppConstants.eventPurchaseCompleted, {'product_id': productId});

  // ── Social ────────────────────────────────────────────────────────────────

  Future<void> logShareTapped(String huntId) =>
      _log(AppConstants.eventShareTapped, {'hunt_id': huntId});

  // ── Screen tracking ─────────────────────────────────────────────────────────────

  /// Log a screen view event. Call from each page's [initState] or route observer.
  /// [screenName] should match the route path (e.g. "/home", "/hunt/123/active").
  Future<void> logScreenView(String screenName) =>
      _log(AppConstants.eventScreenView, {'screen_name': screenName});

  // ── Answer feedback ───────────────────────────────────────────────────────────

  /// Log a wrong answer submission. Useful for identifying poorly-worded clues.
  Future<void> logAnswerWrong({
    required String huntId,
    required int checkpointIndex,
  }) =>
      _log(AppConstants.eventAnswerWrong, {
        'hunt_id': huntId,
        'checkpoint_index': checkpointIndex,
      });

  // ── Profile ───────────────────────────────────────────────────────────────────

  Future<void> logProfileViewed(String userId) =>
      _log(AppConstants.eventProfileViewed, {'user_id': userId});

  // ── Auth ────────────────────────────────────────────────────────────────────────

  /// Log a successful sign-in. [method] is "email", "google", or "guest".
  Future<void> logSignIn(String method) =>
      _log(AppConstants.eventSignIn, {'method': method});

  /// Log a successful account creation. [method] is "email" or "google".
  Future<void> logSignUp(String method) =>
      _log(AppConstants.eventSignUp, {'method': method});

  // ── User identity ─────────────────────────────────────────────────────────

  /// Associate subsequent events with the given Firebase/app user ID.
  /// Call after sign-in; pass null on sign-out to clear.
  Future<void> setUserId(String? userId) =>
      _analytics.setUserId(id: userId);

  /// Attach a persistent user property (e.g. `'city'`, `'plan'`).
  /// Properties are included in every subsequent event automatically.
  Future<void> setUserProperty(String name, String value) =>
      _analytics.setUserProperty(name: name, value: value);

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      // Analytics failures are non-fatal — log and continue.
      AppLogger.w('Analytics log failed: $name', tag: _tag, error: e);
    }
  }
}
