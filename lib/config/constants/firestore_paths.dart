/// Centralises every Firestore collection / document path used in the app.
/// Always use these constants rather than hardcoding strings.
abstract final class FirestorePaths {
  // ── Collections ───────────────────────────────────────────────────────────
  static const String users = 'users';
  static const String hunts = 'hunts';
  static const String huntProgress = 'huntProgress';

  // ── Sub-collections ───────────────────────────────────────────────────────
  static const String checkpoints = 'checkpoints';
  static const String completions = 'completions';

  // ── Document helpers ──────────────────────────────────────────────────────
  static String userDoc(String uid) => '$users/$uid';

  static String huntDoc(String huntId) => '$hunts/$huntId';

  static String checkpointsCollection(String huntId) =>
      '$hunts/$huntId/$checkpoints';

  static String checkpointDoc(String huntId, String checkpointId) =>
      '$hunts/$huntId/$checkpoints/$checkpointId';

  static String huntProgressDoc(String userId, String huntId) =>
      '$huntProgress/${userId}_$huntId';

  static String completionDoc(String huntId, String userId) =>
      '$hunts/$huntId/$completions/$userId';

  // ── Firestore field names ─────────────────────────────────────────────────
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldUserId = 'userId';
  static const String fieldHuntId = 'huntId';
  static const String fieldIsActive = 'isActive';
  static const String fieldCity = 'city';
  static const String fieldStatus = 'status';
  static const String fieldCurrentCheckpointIndex = 'currentCheckpointIndex';
  static const String fieldHintsUsed = 'hintsUsed';
  static const String fieldStartedAt = 'startedAt';
  static const String fieldCompletedAt = 'completedAt';
}
