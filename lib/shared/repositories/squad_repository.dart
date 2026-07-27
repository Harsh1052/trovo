import '../../core/error/result.dart';
import '../models/squad_session_model.dart';

// ── Abstract contract ─────────────────────────────────────────────────────────

/// Defines the squad multiplayer operations.
///
/// Follows the same [Result]-based error handling pattern used by
/// [HuntRepository] and [ProgressRepository].
abstract class SquadRepository {
  /// Creates a new squad session with a unique 4-digit room code.
  ///
  /// The [hostUserId] and [hostDisplayName] identify the room creator,
  /// who is automatically added as the first member.
  Future<Result<SquadSessionModel>> createSquad({
    required String huntId,
    required String hostUserId,
    required String hostDisplayName,
  });

  /// Joins an existing squad session using a 4-digit [roomCode].
  ///
  /// Fails if the room is full, not found, or already active/completed.
  Future<Result<SquadSessionModel>> joinSquad({
    required String roomCode,
    required String userId,
    required String displayName,
  });

  /// Removes a member from the squad.
  ///
  /// If the host leaves, the squad is dissolved (status → completed).
  Future<Result<void>> leaveSquad({
    required String squadId,
    required String userId,
  });

  /// Real-time stream of the squad session document.
  ///
  /// Emits a new [SquadSessionModel] on every Firestore snapshot change
  /// (member joins, ready toggles, checkpoint advances, etc.).
  Stream<SquadSessionModel> watchSquad(String squadId);

  /// Toggles the ready state for [userId] in the squad lobby.
  Future<Result<void>> setReady({
    required String squadId,
    required String userId,
    required bool ready,
  });

  /// Host-only: transitions squad from [SquadStatus.lobby] → [SquadStatus.active].
  Future<Result<void>> startSquadHunt(String squadId);

  /// Host-only: advances the shared checkpoint index.
  Future<Result<void>> advanceCheckpoint({
    required String squadId,
    required int newIndex,
  });

  /// Throttled GPS sync — updates a single member's coordinates.
  Future<Result<void>> updateMemberLocation({
    required String squadId,
    required String userId,
    required double latitude,
    required double longitude,
  });

  /// Marks the squad session as completed.
  Future<Result<void>> completeSquad(String squadId);
}
