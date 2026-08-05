import '../../core/error/result.dart';
import '../models/checkpoint_model.dart';
import '../models/hunt_model.dart';

/// Defines UGC Hunt Creator operations following the project's [Result] pattern.
abstract class CreatorRepository {
  /// Publishes a custom UGC hunt and all its checkpoints atomically via Firestore WriteBatch.
  ///
  /// Enforces:
  /// 1. Min 2 checkpoints, max 10 checkpoints.
  /// 2. Checkpoints distance must be >= 30 meters apart.
  /// 3. Generates 6-character unique access code if `isPrivate == true`.
  Future<Result<HuntModel>> createHunt({
    required HuntModel hunt,
    required List<CheckpointModel> checkpoints,
  });

  /// Retrieves all hunts created by a specific user [userId].
  Future<Result<List<HuntModel>>> fetchUserCreatedHunts(String userId);

  /// Retrieves a private hunt by its 6-character [accessCode].
  Future<Result<HuntModel>> fetchHuntByAccessCode(String accessCode);

  /// Deletes a hunt and its checkpoints created by [userId].
  Future<Result<void>> deleteCreatedHunt({
    required String huntId,
    required String userId,
  });
}
