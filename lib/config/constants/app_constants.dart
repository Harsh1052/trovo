abstract final class AppConstants {
  // ── App info ──────────────────────────────────────────────────────────────
  static const String appName = 'HunterMania';
  static const String appVersion = '1.0.0';

  // ── GPS / Location ────────────────────────────────────────────────────────
  /// Radius in metres within which a checkpoint is considered "reached".
  static const double checkpointUnlockRadius = 20.0;

  /// Minimum accuracy (metres) accepted from the device GPS before using it.
  static const double minimumGpsAccuracy = 50.0;

  /// Location update interval in milliseconds.
  static const int locationUpdateIntervalMs = 3000;

  /// Distance filter in metres — only emit new position after moving this far.
  static const double locationDistanceFilter = 5.0;

  // ── Hints ─────────────────────────────────────────────────────────────────
  /// Maximum hints a player may use per checkpoint.
  static const int maxHintsPerCheckpoint = 3;

  /// Hint cost in seconds added to final time.
  static const int hintTimePenaltySeconds = 60;

  // ── Hunt ─────────────────────────────────────────────────────────────────
  /// Maximum time (minutes) before an active hunt auto-expires.
  static const int huntExpiryMinutes = 240; // 4 hours

  /// Minimum number of checkpoints for a valid hunt.
  static const int minCheckpoints = 3;

  /// Maximum number of checkpoints per hunt.
  static const int maxCheckpoints = 20;

  // ── Answer validation ─────────────────────────────────────────────────────
  /// Minimum levenshtein similarity ratio (0-1) to accept a fuzzy answer.
  static const double answerSimilarityThreshold = 0.85;

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int huntPageSize = 15;
  static const int profileHuntPageSize = 20;

  // ── Cache ─────────────────────────────────────────────────────────────────
  static const Duration huntCacheDuration = Duration(minutes: 10);

  // ── RevenueCat ────────────────────────────────────────────────────────────
  static const String rcEntitlementPremium = 'premium';
  static const String rcEntitlementSingleHunt = 'single_hunt';

  /// Replace with your RevenueCat project API keys.
  static const String rcApiKeyIos = 'appl_REPLACE_WITH_IOS_RC_KEY';
  static const String rcApiKeyAndroid = 'goog_REPLACE_WITH_ANDROID_RC_KEY';

  // ── Analytics events ──────────────────────────────────────────────────────
  static const String eventHuntStarted = 'hunt_started';
  static const String eventHuntCompleted = 'hunt_completed';
  static const String eventHuntAbandoned = 'hunt_abandoned';
  static const String eventCheckpointReached = 'checkpoint_reached';
  static const String eventCheckpointUnlocked = 'checkpoint_unlocked';
  static const String eventHintUsed = 'hint_used';
  static const String eventPurchaseStarted = 'purchase_initiated';
  static const String eventPurchaseCompleted = 'purchase_completed';
  static const String eventShareTapped = 'share_tapped';
}
